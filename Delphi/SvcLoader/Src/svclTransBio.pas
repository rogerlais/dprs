{$IFDEF svclTransBio}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclTransBio;

interface

uses
    SysUtils, Windows, Classes, XPFileEnumerator, XPThreads;

type
    TTransBioThread = class(TXPNamedThread)
    private
        FStream :    TFileStream;
        FUserToken : THandle;
        procedure DoCycle;
        procedure ReplicDataFiles2PrimaryMachine(const Filename : string);
        procedure CreatePrimaryBackup(const DirName : string);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure StoreTransmitted(SrcFile : TFileSystemEntry);
        procedure NetAccess(link : boolean);
    public
        procedure Execute(); override;
        function InitNetUserAccess(const AUsername, APassword : string) : Integer;
        destructor Destroy; override;
    end;

implementation

uses
    svclConfig, FileHnd, AppLog, svclUtils;

{ TTransBioThread }
procedure TTransBioThread.CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
//ErrMsg DEVE conter exatamente 4 tokens para string
var
    DestName : string;
begin
    //Verificar se existe o destino, garantindo nome único
    Self.NetAccess(True);
    try
        if FileExists(Dest) then begin
            DestName := TFileHnd.NextFamilyFilename(Dest);
        end else begin
            DestName := Dest;
        end;
        if not (ForceDirectories(ExtractFilePath(Dest))) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(ERROR_CANNOT_MAKE)]);
        end;
    finally
        Self.NetAccess(False);
    end;
    if ToMove then begin
        if not MoveFile(PWideChar(Source), PWideChar(DestName)) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end else begin
        Self.NetAccess(True);
        try
            if not CopyFile(PWideChar(Source), PWideChar(DestName), True) then begin
                raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
            end;
        finally
            Self.NetAccess(False);
        end;
    end;
end;

procedure TTransBioThread.CreatePrimaryBackup(const DirName : string);
 ///Monta arvore de diretorios baseado na data do arquivo no padrão <root>\year\month\day
 /// Onde <root> é configurado
var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f : TFileSystemEntry;
begin
    FileEnt := TDirectory.FileSystemEntries(DirName, BIOMETRIC_FILE_MASK, False);
    for f in FileEnt do begin
        Self.StoreTransmitted(f);
    end;
end;

destructor TTransBioThread.Destroy;
begin
	 //Liberar o Token usado pela conta alternativa
	 CloseHandle( Self.FUserToken );
	 Self.FUserToken := 0;
    inherited;
end;

procedure TTransBioThread.DoCycle;
///Inicia novo ciclo de operação
var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f : TFileSystemEntry;
begin
    if GlobalConfig.isPrimaryComputer then begin
        //Para o caso do computador primário o serviço executa o caso de uso "CreatePrimaryBackup"
        Self.CreatePrimaryBackup(GlobalConfig.PrimaryTransmittedPath);
    end else begin
        //FileEnt := TDirectory.FileSystemEntries(GlobalConfig.StationSourcePath, BIOMETRIC_FILE_MASK, False);
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.StationSourcePath, BIOMETRIC_FILE_MASK, False);
        //Para o caso de estação(Única a coletar dados biométricos), o sistema executará o caso de uso "ReplicDataFiles2PrimaryMachine"
        for f in FileEnt do begin
            Self.ReplicDataFiles2PrimaryMachine(f.FullName);
        end;
    end;
end;

procedure TTransBioThread.ReplicDataFiles2PrimaryMachine(const Filename : string);
 //Realiza a operação unitária com o arquivo dado:
 //1 - Copia para a pasta local de transmissão
 //2 - Copia para a pasta de transmissão primária
 //3 - Copia para o bakup local
 //4 - Apaga do local de aquisição
const
    ERR_MSG: string = 'Falha copiando arquivo'#13'%s'#13'para'#13'%s'#13'%s'#13'%s';
var
    PrimaryTransName, LocalTransName, LocalBackupName : string;
begin
    //Copia para a pasta local de transmissão
    LocalTransName := TFileHnd.ConcatPath([GlobalConfig.StationLocalTransPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalTransName, 'Transbio Local', ERR_MSG, False);

    //Copia arquivo para local remoto de transmissão
    PrimaryTransName := TFileHnd.ConcatPath([GlobalConfig.StationRemoteTransPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, PrimaryTransName, 'Repositório primário', ERR_MSG, False);

    //Move arquivo para backup local
    LocalBackupName := TFileHnd.ConcatPath([GlobalConfig.StationBackupPath, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalBackupName, 'Backup Local', ERR_MSG, True);
end;

procedure TTransBioThread.Execute;
var
    ErrCnt : Integer;
begin
    inherited;
    //Repetir os ciclos de acordo com a temporização configurada
    //O Thread primário pode enviar notificação da cancelamento que deve ser verificada ao inicio de cada ciclo
    try
        ErrCnt := 0;
        while Self.IsAlive do begin
            try
                Self.DoCycle;
                ErrCnt := 0;
            except
                on E : Exception do begin
                    //Registrar o erro e testar o contador de erros
                    Inc(ErrCnt);
                    if ErrCnt > 10 then begin
                        {TODO -oroger -cdsg : Interrromper servico e notificar agente monitorador}
                        TLogFile.Log(Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.', [ErrCnt]), lmtError);
                    end;
                end;
            end;
            //Suspende este thread até a liberação pelo thread do serviço
               {$IFDEF DEBUG}
            //SwitchToThread();
            Self.Suspended := True;
              {$ELSE}
            Self.Suspended := True;
             {$ENDIF}
        end;
    finally
        Self.FStream.Destroy;
    end;
end;

function TTransBioThread.InitNetUserAccess(const AUsername, APassword : string) : Integer;
var
    User, Pass : PChar;
begin
	 TLogFile.LogDebug(Format('Usando conta: %s para acesso à rede com a senha: "%s"', [AUsername, GlobalConfig.CypherNetAccessPassword]), DBGLEVEL_DETAILED);

    User   := PChar(AUserName);
    Pass   := PChar(APassword);
    Result := ERROR_SUCCESS;
    SetLastError(Result);
    if not LogonUser(User, nil, Pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, Self.FUserToken) then begin
        Result := GetLastError();
    end;
end;

procedure TTransBioThread.NetAccess(link : boolean);
 ///  <summary>
 ///    Habilita o acesso a um compartilhamento remoto para a replicação dos arquivos
 ///  </summary>
 ///  <remarks>
 ///  A inicialização deve ter sido chamada anteriormente
 ///  </remarks>
var
    ret : boolean;
begin
    if (link) then begin
        ret := ImpersonateLoggedOnUser(Self.FUserToken);
    end else begin
        ret := RevertToSelf();
    end;
    if (not ret) then begin
        TLogFile.Log('Acesso a rede falhou!!!'#13 + SysErrorMessage(GetLastError()));
    end;
end;

procedure TTransBioThread.StoreTransmitted(SrcFile : TFileSystemEntry);
 ///
 /// Move arquivo da pasta de transmitidos de acordo com a data de criação para a pasta raiz de armazenamento
 ///
var
    DestPath, FullDateStr, sy, sm, sd : string;
    dummy, t : TDateTime;
begin
    TFileHnd.FileTimeProperties(SrcFile.FullName, dummy, dummy, t);
    FullDateStr := FormatDateTime('YYYYMMDD', t);
    sy := Copy(FullDateStr, 1, 4);
    sm := Copy(FullDateStr, 5, 2);
    sd := Copy(FullDateStr, 7, 2);
    DestPath := TFileHnd.ConcatPath([GlobalConfig.PrimaryBackupPath, sy, sm, sd]);
    ForceDirectories(DestPath);
    if (not MoveFile(PChar(SrcFile.FullName), PChar(DestPath + '\' + SrcFile.Name))) then begin
        TLogFile.Log('Erro movendo arquivo para o repositório definitivo no computador primário'#13 +
            SysErrorMessage(GetLastError()));
    end;
end;

end.
