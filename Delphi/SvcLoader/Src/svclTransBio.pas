{$IFDEF svclTransBio}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclTransBio;

interface

uses
    SysUtils, Windows, Classes, XPFileEnumerator, XPThreads, svclTCPTransfer;

type
    TTransBioThread = class(TXPNamedThread)
    private
        FCycleErrorCount : Integer;
        procedure DoClientCycle;
        procedure ReplicDataFiles2PrimaryMachine(BioFile : TTransferFile);
        procedure CopyBioFile(const Source, Dest, Fase, ErrMsg : string; ToMove : boolean);
        procedure ForceEloConfiguration();
    public
        procedure Execute(); override;
    end;

    TTransBioServerThread = class(TXPNamedThread)
    private
        procedure StoreTransmitted(SrcFile : TFileSystemEntry);
        procedure DoServerCycle;
        procedure CreatePrimaryBackup(const DirName : string);
        procedure StartTCPServer;
		 procedure StopTCPServer;
	 protected
	 	procedure DoTerminate(); override;
    public
        procedure Execute(); override;
    end;

implementation

uses
    svclConfig, FileHnd, AppLog, svclUtils, WinNetHnd, WinReg32, AppSettings, JclSysInfo, svclBiometricFiles;

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

procedure TTransBioThread.DoClientCycle;
 ///Inicia novo ciclo de operação
 ///

    procedure LSRSearchDivergents(list : TStringList);
    //--------------------------------------------------------
    ///<summary>
    ///Varre lista de arquivos ordenada por nome por arquivos com hash divergente. Encontrando
    ///</summary>
    ///<remarks>
    ///
    ///</remarks>
    var
        x :      Integer;
        f1, f2 : TTransferFile;
    begin
		 {TODO -oroger -cfuture : Melhorar implementa~çao de modo a buscar por arquivo do bioservice e na ausencia usar outro para denomiar de primario}
        x := list.Count - 1; //pivot no final da lista para comparar aos pares
        while (x > 0) do begin
            if (list.Strings[x] = list.Strings[x - 1]) then begin //comparar os hash
                f1 := TTransferFile(list.Objects[x - 1]);
                f2 := TTransferFile(list.Objects[x]);
                if (f1.Hash <> f2.Hash) then begin //Renomear e remover os não constantes na pasta Bioservice
					 if (not SameText(TFileHnd.ParentDir(f2.Filename), GlobalConfig.PathClientBioService)) then begin
						 f2.SetAsDivergent;
                        list.Delete(x); //OwnsObjects = true para a lista libera instância
                    end else begin
                        if (not SameText(TFileHnd.ParentDir(f1.Filename), GlobalConfig.PathClientBioService)) then begin
                            f1.SetAsDivergent;
                            list.Delete(x - 1); //OwnsObjects = true para a lista libera instância
                        end;
                    end;
                    x := list.Count - 1; //recomeçar
                    System.Continue;
                end;
            end;
            Dec(x); //Pula para o par seguinte, se houver
        end;
    end;

var
    FileEnt : IEnumerable<TFileSystemEntry>;
    f :   TFileSystemEntry;
    cmp : string;
    FileList : TStringList;
    x :   Integer;
    BioFile : TTransferFile;
begin
    {TODO -oroger -cdebug : Ponto critico de verificação de memory leak}
    //Coleta a lista de arquivos para a operação neste ciclo
    FileList := TStringList.Create;
    try
        FileList.Sorted      := True;
        FileList.Duplicates  := dupAccept;
        FileList.OwnsObjects := True; //mantera as instancia consigo

        //repositorio Bioservice(Bio)
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.PathClientBioService, BIOMETRIC_FILE_MASK, False);
        //repositorio Bioservice
        for f in FileEnt do begin
            FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
        end;

        //repositorio TransBio(Bio)
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.Elo2TransBio, BIOMETRIC_FILE_MASK, False);
        for f in FileEnt do begin
            FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
        end;

        //repositorio TransBio(Trans)
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.PathTransmitted, BIOMETRIC_FILE_MASK, False);
        for f in FileEnt do begin
            FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
        end;

        //repositorio TransBio(ReTrans)
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.PathRetrans, BIOMETRIC_FILE_MASK, False);
        for f in FileEnt do begin
            FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
        end;

        //repositorio TransBio(Erro)
        FileEnt := TDirectory.FileSystemEntries(GlobalConfig.TransbioConfig.PathError, BIOMETRIC_FILE_MASK, False);
        for f in FileEnt do begin
            FileList.AddObject(UpperCase(f.Name), TTransferFile.CreateOutput(f.FullName));
        end;

        //Inicia busca por divergentes
        LSRSearchDivergents(FileList);

        //Processa a lista de arquivos para envio
        if (FileList.Count <= 0) then begin
            Exit;
        end;
        cmp := WinNetHnd.GetComputerName();
        DMTCPTransfer.StartClient;
        try
            DMTCPTransfer.StartSession(cmp);
            try
                //Para o caso de estação(Única a coletar dados biométricos), o sistema executará o caso de uso "ReplicDataFiles2PrimaryMachine"
                for x := 0 to FileList.Count - 1 do begin
                    bioFile := TTransferFile(FileList.Objects[x]);
                    Self.ReplicDataFiles2PrimaryMachine(bioFile);
                end;
            finally
                DMTCPTransfer.EndSession(cmp);
            end;
        finally
            DMTCPTransfer.StopClient;
        end;
    finally
        FileList.Free; //OwnsObjects = true para a lista libera instâncias
    end;

end;

procedure TTransBioThread.ReplicDataFiles2PrimaryMachine(BioFile : TTransferFile);
 ///<summary>
 /// Realiza a operação unitária com o arquivo dado:
 /// 1 - Envia o arquivo para o servidor
 /// 2 - Copia para a pasta de backup ordenado
 /// 3 - Copia para o bakup local(não ordenado)
 /// 4 - Apaga do local de aquisição
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
const
    ERR_MSG: string = 'Falha copiando arquivo'#13'%s'#13'para'#13'%s'#13'%s'#13'%s';
var
    DestFilename, LocalBackupName : string;
begin
    //Envia o arquivo para o servidor, passando ok -> realiza seu backup local
    DMTCPTransfer.SendFile(BioFile);

    DestFilename := TFileHnd.ConcatPath([GlobalConfig.PathClientOrderlyBackup, BioFile.DateStamp,
        ExtractFileName(BioFile.Filename)]);
    Self.CopyBioFile(BioFile.Filename, DestFilename, 'Backup do cliente', ERR_MSG, False);

    //Move arquivo para backup local, todos os arquivos sem agrupamento
    LocalBackupName := TFileHnd.ConcatPath([GlobalConfig.PathClientFullyBackup, ExtractFileName(BioFile.Filename)]);
    Self.CopyBioFile(BioFile.Filename, LocalBackupName, 'Backup Local', ERR_MSG, True);
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
    ErrorMessage : string;

    procedure LSRReportError(EComm : Exception);
    //notificar agente monitorador
    begin
        //Registrar o erro e testar o contador de erros
        Inc(Self.FCycleErrorCount);
        ErrorMessage := Format('Quantidade de erros consecutivos(%d) ultrapassou o limite.'#13#10 +
            'Último erro registrado = "%s"', [Self.FCycleErrorCount, EComm.Message]);
        if (Integer(Self.FCycleErrorCount) > 10) then begin
            TLogFile.Log(ErrorMessage, lmtError);
            Self.FCycleErrorCount := 0; //reseta contador global
        end;
    end;

begin
    inherited;

    try
        //Checar na inicialização do serviço as configurações locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
        Self.ForceEloConfiguration();
    except
        on EElo : Exception do begin //Registrar o erro e continuar com o processo
            BioFilesService.SendMailNotification('Erro forçando a configuração dos aplicativos ELO e/ou Transbio'#13#10 +
                EElo.Message);
        end;
    end;

    //Repetir os ciclos de acordo com a temporização configurada
    //O Thread primário pode enviar notificação da cancelamento que deve ser verificada ao inicio de cada ciclo
    Self.FCycleErrorCount := 0;
    while (not Self.Terminated) do begin
        try
            if (not GlobalConfig.RunAsServer) then begin
                Self.DoClientCycle;
            end;
            Self.FCycleErrorCount := 0; //Reseta contador de erros do ciclo
        except
            on EComm : Exception do begin
                LSRReportError(EComm);
            end;
        end;
        //Suspende este thread até a liberação pelo thread do serviço
        Self.Suspended := True;
    end;
end;

procedure TTransBioThread.ForceEloConfiguration;
///Checar na inicialização do serviço as configurações locais para o ELO e Transbio de modo a garantir o funcionamento correto/esperado
/// Requisitos: Veraão anterior ao Windows Vista
var
    EloReg : TRegistryNT;
begin
    //**** Configurações do TransBio *****
    //Todas as configurações do TransBio forcadas desta forma, caso o ini do serviço esteja ompleto
    if (Assigned(GlobalConfig.TransbioConfig)) then begin
        GlobalConfig.TransbioConfig.Import(GlobalConfig, 'TransBio', '', True);
        GlobalConfig.TransbioConfig.Elo2TransBio := GlobalConfig.TransbioConfig.PathBio;
    end;
    //Caminhos de configuração do elo e pasta de transmissão do Transbio devem ser iguais, notificar para divergente
    if (not SameText(GlobalConfig.TransbioConfig.Elo2TransBio, GlobalConfig.TransbioConfig.PathBio)) then begin
        BioFilesService.SendMailNotification(
            'Caminhos de destino do arquivos biométricos do elo divergente do caminho de leitura do serviço Transbio nesta estação'#13#10 +
            'ELO=' + GlobalConfig.TransbioConfig.Elo2TransBio + #13#10 +
            'TransBio=' + GlobalConfig.TransbioConfig.PathBio);
    end;

    //Configurações do ELO a serem forçadas
    if (not IsDebuggerPresent) then begin
        if (JclSysInfo.GetWindowsVersion() > wvWinXP) then begin
            raise Exception.Create('Versão do windows não suportada(Requer elevação)');
        end;
        //Configurações do ELO(Local onde serão armazenados o arquivos lidos do Bioservice)
        EloReg := TRegistryNT.Create;
        try
            try
                EloReg.WriteFullString(ELO_TRANSFER_TRANSBIO_PATH, GlobalConfig.TransbioConfig.PathBio, True);
            finally
                EloReg.Free;
            end;
        except
            on E : Exception do begin
                TLogFile.Log('Configuração do ELO não foram forçadas corretamente'#13#10 + E.Message, lmtWarning);
            end;
        end;
    end;
end;

{TTransBioServerThread}
procedure TTransBioServerThread.DoServerCycle;
///Inicia novo ciclo de operação do servidor
///Para o caso do computador primário o serviço executa o caso de uso "CreatePrimaryBackup"
begin
	 Self.CreatePrimaryBackup(GlobalConfig.TransbioConfig.PathTransmitted);  //move arquivos da pasta de transmitidos do transbio para ordenado
end;

procedure TTransBioServerThread.DoTerminate;
begin
    //Parada do servidor TCP
    Self.StopTCPServer;
    inherited;
end;

procedure TTransBioServerThread.Execute;
begin
	 inherited;
	 Self.StartTCPServer; //Para o servidor inicia escuta na porta
    while (not Self.Terminated) do begin
        try
			 Self.DoServerCycle();
		 except
			on E : Exception do begin
			 TLogFile.Log( 'Ciclo de organização de arquivos do servidor de envio falhou: ' + E.Message, lmtError );
			end;
		 end;
    end;
end;

procedure TTransBioServerThread.StartTCPServer;
//Verificar a atividade do servidor tcp, ativando o mesmo se necessário
begin
	 if (not DMTCPTransfer.tcpsrvr.Active) then begin
        DMTCPTransfer.StartServer();
    end;
end;

procedure TTransBioServerThread.CreatePrimaryBackup(const DirName : string);
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

procedure TTransBioServerThread.StopTCPServer;
begin
    if (DMTCPTransfer.tcpsrvr.Active) then begin
        DMTCPTransfer.StopServer();
    end;
end;

procedure TTransBioServerThread.StoreTransmitted(SrcFile : TFileSystemEntry);
 ///
 /// Move arquivo da pasta de transmitidos de acordo com a data de criação para a pasta raiz de armazenamento
 ///
var
    DestPath, FullDateStr, sy, sm, sd : string;
    dummy, FileCreateTime : TDateTime;
begin
    TFileHnd.FileTimeProperties(SrcFile.FullName, FileCreateTime, dummy, dummy);
    FullDateStr := FormatDateTime('YYYYMMDD', FileCreateTime);
    //Conversão da data de criação(supostamente o momento de transmissão pelo transbio)
	 sy := Copy(FullDateStr, 1, 4);
    sm := Copy(FullDateStr, 5, 2);
    sd := Copy(FullDateStr, 7, 2);
	 DestPath := TFileHnd.ConcatPath([GlobalConfig.PathServerFullyBackup, sy, sm, sd]);
    ForceDirectories(DestPath);
    if (not MoveFile(PChar(SrcFile.FullName), PChar(DestPath + '\' + SrcFile.Name))) then begin
        TLogFile.Log('Erro movendo arquivo para o repositório definitivo no computador primário'#13 +
            SysErrorMessage(GetLastError()));
    end;
end;


end.
