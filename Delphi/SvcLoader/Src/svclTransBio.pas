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
        procedure DoClientCycle;
        procedure DoServerCycle;
        procedure ReplicDataFiles2PrimaryMachine(const Filename : string);
        procedure CreatePrimaryBackup(const DirName : string);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure StoreTransmitted(SrcFile : TFileSystemEntry);
        procedure ForceEloConfiguration();
    public
        PathELOTransbioConfigFile : string;
        procedure Execute(); override;
    end;

implementation

uses
    svclConfig, FileHnd, AppLog, svclUtils, svclTCPTransfer, WinNetHnd, WinReg32, AppSettings, JclSysInfo;

{ TTransBioThread }
procedure TTransBioThread.CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
//ErrMsg DEVE conter exatamente 4 tokens para string
var
    DestName : string;
begin
    //Verificar se existe o destino, garantindo nome único
    if FileExists(Dest) then begin
        DestName := TFileHnd.NextFamilyFilename(Dest);
    end else begin
        DestName := Dest;
    end;
    if not (ForceDirectories(ExtractFilePath(Dest))) then begin
        raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(ERROR_CANNOT_MAKE)]);
    end;
    if ToMove then begin
        if not MoveFile(PWideChar(Source), PWideChar(DestName)) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
        end;
    end else begin
        if not CopyFile(PWideChar(Source), PWideChar(DestName), True) then begin
            raise ESVCLException.CreateFmt(ErrMsg, [Source, DestName, Fase, SysErrorMessage(GetLastError())]);
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

procedure TTransBioThread.DoClientCycle;
///Inicia novo ciclo de operação
var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f :   TFileSystemEntry;
    cmp : string;
begin
    cmp := WinNetHnd.GetComputerName();
    DMTCPTransfer.StartClient;
    try
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathServiceCapture, BIOMETRIC_FILE_MASK, False);
        DMTCPTransfer.StartSession(cmp);
        try
            //Para o caso de estação(Única a coletar dados biométricos), o sistema executará o caso de uso "ReplicDataFiles2PrimaryMachine"
            for f in FileEnt do begin
                Self.ReplicDataFiles2PrimaryMachine(f.FullName);
            end;
        finally
            DMTCPTransfer.EndSession(cmp);
        end;
    finally
        DMTCPTransfer.StopClient;
    end;
end;

procedure TTransBioThread.DoServerCycle;
///Inicia novo ciclo de operação do servidor
begin
    //Para o caso do computador primário o serviço executa o caso de uso "CreatePrimaryBackup"
    Self.CreatePrimaryBackup(GlobalConfig.PathServerBackup);
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
    tf : TTransferFile;
begin
    {TODO -oroger -cdsg : empacotar e enviar para servidor}

    tf := TTransferFile.CreateOutput(Filename);
    try
        DMTCPTransfer.SendFile(tf);
    finally
        tf.Free;
    end;


    //Copia para a pasta local de transmissão
    LocalTransName := TFileHnd.ConcatPath([GlobalConfig.PathServiceCapture, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalTransName, 'Transbio Local', ERR_MSG, False);

    //Copia arquivo para local remoto de transmissão
    PrimaryTransName := TFileHnd.ConcatPath([GlobalConfig.PathELOTransbioBioSource, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, PrimaryTransName, 'Repositório primário', ERR_MSG, False);

    //Move arquivo para backup local
    LocalBackupName := TFileHnd.ConcatPath([GlobalConfig.PathLocalBackup, ExtractFileName(Filename)]);
    Self.CopyBioFile(Filename, LocalBackupName, 'Backup Local', ERR_MSG, True);
end;

procedure TTransBioThread.Execute;
 ///<summary>
 ///Rotina primaria do caso de uso do servico.
 ///Nele temos 2 cenarios:
 /// 1 - Maquina secundária:
 ///     a) Enumera todos os arquivos da pasta de origem
 ///    b) Repassa todo os arquivos para a maquina primária
 ///    c) Realiza seu backup local
 /// 2 - Máquina primária:
 ///     a) Move todos os da pasta de recepção remota para a pasta de transmissão
 ///     b) Move todos os arquivos da pasta transmitidos para a de backup global
 ///     c) Reorganiza todos os arquivos do backup global
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
var
    ErrCnt : Integer;
begin
    inherited;

    try
        //Checar na inicialização do serviço as configurações locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
        Self.ForceEloConfiguration();
    except
        on E : Exception do begin
            {TODO -oroger -cdsg : Registrar o erro e continuar com o processo}

        end;
    end;

    //Repetir os ciclos de acordo com a temporização configurada
    //O Thread primário pode enviar notificação da cancelamento que deve ser verificada ao inicio de cada ciclo
    ErrCnt := 0;
    while Self.IsAlive do begin
        try
            if (GlobalConfig.isPrimaryComputer) then begin
                Self.DoServerCycle;
            end else begin
                Self.DoClientCycle;
            end;
            ErrCnt := 0; //Reseta contador de erros do ciclo
        except
            on E : Exception do begin
                //Registrar o erro e testar o contador de erros
                Inc(ErrCnt);
                if ErrCnt > 10 then begin
                    {TODO -oroger -cdsg : Interrromper servico e notificar agente monitorador}
                    TLogFile.Log(Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 +
                        'Último erro registrado = "%s"', [ErrCnt, E.Message]), lmtError);
                end;
            end;
        end;
        //Suspende este thread até a liberação pelo thread do serviço
        //SwitchToThread();
        Self.Suspended := True;
    end;
end;

procedure TTransBioThread.ForceEloConfiguration;
///Checar na inicialização do serviço as configurações locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
/// Requisitos: Veraão anterior ao Windows Vista
var
    EloReg : TRegistryNT;
begin
    if (not IsDebuggerPresent) then begin    {TODO -oroger -cdsg : negar o teste ao lado}
        if (JclSysInfo.GetWindowsVersion() > wvWinXP) then begin
            raise Exception.Create('Versão do windows não suportada(Requer elevação)');
        end;

        //Configurações do ELO
        EloReg := TRegistryNT.Create;
        try
            try
                EloReg.WriteFullString('HKEY_LOCAL_MACHINE\SOFTWARE\ELO\Config\DirTransfBio',
                    GlobalConfig.PathELOTransbioBioSource, True);
            finally
                EloReg.Free;
            end;
        except
            on E : Exception do begin
                {TODO -oroger -cdsg : Registrar a falha e continuar com a operação}
            end;
        end;

    end;
    //**** Configurações do TransBio *****
    //Caminhos TransBio
    if (Assigned(GlobalConfig.TransbioConfig)) then begin
        GlobalConfig.TransbioConfig.Import(GlobalConfig, 'TransBio', '', True);
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
    DestPath := TFileHnd.ConcatPath([GlobalConfig.PathClientBackup, sy, sm, sd]);
    ForceDirectories(DestPath);
    if (not MoveFile(PChar(SrcFile.FullName), PChar(DestPath + '\' + SrcFile.Name))) then begin
        TLogFile.Log('Erro movendo arquivo para o repositório definitivo no computador primário'#13 +
            SysErrorMessage(GetLastError()));
    end;
end;

end.
