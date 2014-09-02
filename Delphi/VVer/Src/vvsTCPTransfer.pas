{$IFDEF svclTCPTransfer}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVerSvc.inc}

unit vvsTCPTransfer;

interface

{TODO -oroger -cdsg : Possibilitar pela UI pausar o envio dos dados por x minutos}
{TODO -oroger -cdsg : Ao receber mensagem de shutdown e havendo arquivos a transmitir/receber, possibilita ao usuário deixar o desligamento a cargo do serviço}
{TODO -oroger -cdsg : Registrar o encerramento do windows }

uses
    SysUtils, Classes, Windows, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
    IdTCPServer, AppLog, XPFileEnumerator, IdGlobal, Menus, ExtCtrls, SyncObjs, StreamHnd, ImgList,
    Controls, vvsConsts, vvsThreadList, HTTPApp, Dialogs, vvsFileMgmt;

type
	 TThreadStringList = class(TStringList)
    private
        FLocker : TCriticalSection;
    protected
        procedure Enter;
        procedure Leave;
    public
        constructor Create;
        destructor Destroy; override;
    end;

    TTransferFile = class(TObject)
    private
        FAccesTime :    TDateTime;
        FModifiedTime : TDateTime;
        FCreatedTime :  TDateTime;
        FFilename :     string;
        FHash :         string;
        FIsInputFile :  boolean;
        FStream :       TMemoryStream;
        procedure SetFilename(const Value : string);
        procedure InvalidWriteOperation(const AttrName : string);
        function GetSize : int64;
        function GetHash : string;
        function GetDateStamp : string;
    public
        property Filename : string read FFilename write SetFilename;
        property IsInputFile : boolean read FIsInputFile;
        property AccesTime : TDateTime read FAccesTime;
        property ModifiedTime : TDateTime read FModifiedTime;
        property CreatedTime : TDateTime read FCreatedTime;
        property Size : int64 read GetSize;
        property Hash : string read GetHash;
        property DateStamp : string read GetDateStamp;
        procedure ReadFromStream(AStream : TStream);
        constructor CreateOutput(const Filename : string);
        constructor Create(strm : TStream);
        destructor Destroy; override;
    end;

    TServerSyncSession = class(TObject)
    private
        FSessionName :   string;
        FContext :       TIdContext;
        FClientVersion : string;
        FClientName :    string;
        function ExecReadContent() : string;
		 function ExecFileDownload() : string;
		 function ExecFileFingerPrint() : string;
    public
        property ClientName : string read FClientName;
        property ClientVersion : string read FClientVersion;
        property SessionName : string read FSessionName;
        property Context : TIdContext read FContext;
        {TODO -oroger -cdsg : capturar no construtor todos os eventos do context desejáveis }
        constructor Create(AContext : TidContext; const AClientName, AClientVersion, ASessionName : string); virtual;
        function DoExecVerbs() : string;
    end;

    TSyncSessionServerList = class(TSyncTThreadList<TServerSyncSession>);


type
    TDMTCPTransfer = class(TDataModule)
        tcpsrvr :     TIdTCPServer;
        tcpclnt :     TIdTCPClient;
        TrayIcon :    TTrayIcon;
        pmTrayMenu :  TPopupMenu;
        Configurar1 : TMenuItem;
        Sair1 :       TMenuItem;
        ilIcons :     TImageList;
        procedure tcpclntConnected(Sender : TObject);
        procedure tcpclntDisconnected(Sender : TObject);
        procedure DataModuleDestroy(Sender : TObject);
        procedure tcpsrvrExecute(AContext : TIdContext);
        procedure tcpsrvrStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
		 procedure DataModuleCreate(Sender : TObject);
		 procedure TrayIconMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
		 procedure tcpsrvrConnect(AContext : TIdContext);
		 procedure tcpsrvrDisconnect(AContext : TIdContext);
	 private
		 { Private declarations }
		 FClientSessionList : TThreadStringList;
		 FServerSessionList : TSyncSessionServerList;
		 FSessionFileCount :  Integer;
		 FMaxTrackedClients : Integer;
		 procedure SaveBioFile(const ClientName, Filename, screateDate, saccessDate, smodifiedDate : string; inputStrm : TStream);
		 procedure InitSettings();
		 procedure UpdateServerTrayStatus();
	 public
		 { Public declarations }
		 procedure StartServer();
		 procedure StartClient();
		 function StartSession(const SessionName : string) : string;
		 procedure EndSession(const SessionName : string);
		 procedure StopServer();
		 procedure StopClient();
		 procedure SendFile(AFile : TTransferFile);
		 constructor Create(AOwner : TComponent); override;
		 destructor Destroy; override;
    end;

var
    DMTCPTransfer : TDMTCPTransfer = nil; //Criado manualmente nas aplicações de teste

implementation

uses
    vvsConfig, FileHnd, StrHnd, vvSvcDM;

{$R *.dfm}

var
    ForcedFormatSettings : TFormatSettings;

constructor TDMTCPTransfer.Create(AOwner : TComponent);
begin
    inherited;
	 Self.FClientSessionList := TThreadStringList.Create;
	 Self.FServerSessionList := TSyncSessionServerList.Create;
	 if (not Assigned(VVSvcConfig.ProfileInfo)) then begin
        Self.TrayIcon.IconIndex := II_CLIENT_ERROR; //indica falha de identificação de perfil
    end else begin
        Self.TrayIcon.IconIndex := II_CLIENT_IDLE; //Nada a se "adivinhar" ainda
    end;
end;

procedure TDMTCPTransfer.DataModuleCreate(Sender : TObject);
begin
	 Self.tcpclnt.ReadTimeout;
end;

procedure TDMTCPTransfer.DataModuleDestroy(Sender : TObject);
begin
    //Fecha clientes e servidor
    //Self.StopClient;
    Self.StopServer;
end;

destructor TDMTCPTransfer.Destroy;
begin
	 Self.FClientSessionList.Free;
	 Self.FServerSessionList.Free;
	 inherited;
end;

procedure TDMTCPTransfer.EndSession(const SessionName : string);
var
    idx : Integer;
begin
    //Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
    Self.FClientSessionList.Enter;
    try
        idx := Self.FClientSessionList.IndexOf(SessionName);
        if (idx >= 0) then begin
            Self.FClientSessionList.Delete(idx);
        end;
    finally
        Self.FClientSessionList.Leave;
    end;
    //Envia a finalização de sessão para o servidor
    Self.tcpclnt.IOHandler.WriteLn(STR_END_SESSION_SIGNATURE + SessionName); //Envia msg de fim de sessão
end;

procedure TDMTCPTransfer.InitSettings;
begin
    SysUtils.GetLocaleFormatSettings(Windows.LOCALE_SYSTEM_DEFAULT, ForcedFormatSettings);
    ForcedFormatSettings.DecimalSeparator := '.';
end;

procedure TDMTCPTransfer.SaveBioFile(const ClientName, Filename, screateDate, saccessDate, smodifiedDate : string;
    inputStrm : TStream);

    procedure LSRWriteFile(const Filename : string; src : TStream);
    var
        fs :   TFileStream;
        mode : Word;
    begin
        src.Position := 0;
        ForceDirectories(ExtractFilePath(filename));
        mode := fmShareExclusive;
        if (not FileExists(filename)) then begin
            mode := mode + fmCreate;
        end else begin
            mode := mode + fmOpenWrite;
        end;
        fs := TFileStream.Create(filename, mode);
        try
            fs.CopyFrom(src, src.Size);
        finally
            fs.Free;
        end;
    end;

var
    createDate, modDate, accDate : TDateTime;
    lastName, TransbioFileName, BackupFileName : string;
begin
    createDate := StrToFloat(screateDate, ForcedFormatSettings);
    modDate    := StrToFloat(smodifiedDate, ForcedFormatSettings);
    accDate    := StrToFloat(saccessDate, ForcedFormatSettings);
    lastName   := ExtractFileName(Filename);
    TransbioFileName := TFileHnd.ConcatPath([VVSvcConfig.PathLocalInstSeg, lastName]);
    BackupFileName := TFileHnd.ConcatPath([VVSvcConfig.PathTempDownload, ClientName, FormatDateTime(
        'YYYY\MM\DD', modDate), lastName]);
    LSRWriteFile(TransbioFileName, inputStrm);
    FileHnd.SetFileTimeProperties(TransbioFileName, createDate, accDate, modDate);
    LSRWriteFile(BackupFileName, inputStrm);
    FileHnd.SetFileTimeProperties(BackupFileName, createDate, accDate, modDate);
end;

procedure TDMTCPTransfer.SendFile(AFile : TTransferFile);
 ///<summary>
 ///Envia a instancia passada para o servidor
 ///</summary>
 /// <preconditions>
 /// Socket com o servidor aberto
 /// <preconditions>
 ///<remarks>
 ///
 ///</remarks>
var
    s : string;
begin
    if (not Self.tcpclnt.Connected) then begin
        raise ESVCLException.Create('Canal com o servidor não estabelecido antecipadamente');
    end;
    //Passados obrigatoriamente nesta ordem!!!
	 s := AFile.FFilename + TOKEN_DELIMITER +
		 FloatToStr(AFile.FCreatedTime, ForcedFormatSettings) + TOKEN_DELIMITER +
        FloatToStr(AFile.FAccesTime, ForcedFormatSettings) + TOKEN_DELIMITER +
        FloatToStr(AFile.FModifiedTime, ForcedFormatSettings) + TOKEN_DELIMITER +
        FloatToStr(AFile.Size, ForcedFormatSettings) + TOKEN_DELIMITER +
        AFile.Hash;
    Self.tcpclnt.IOHandler.WriteLn(s);
    Self.tcpclnt.IOHandler.WriteFile(AFile.Filename);
    s := Self.tcpclnt.IOHandler.ReadLn();
    if (s <> STR_OK_PACK) then begin
        raise ESVCLException.CreateFmt('Retorno de erro de envio: "%s" para arquivo="%s".', [s, AFile.Filename]);
    end else begin
        Inc(Self.FSessionFileCount); //Incrementa contador de trafego(modo cliente)
    end;
end;

procedure TDMTCPTransfer.StartClient;
 ///<summary>
 ///Ajusta o container para funcionar apenas como cliente(envio de arquivos apenas)
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    Self.InitSettings();
    if (System.DebugHook <> 0) then begin //Depurando na IDE
        Self.tcpclnt.ConnectTimeout := 5000; //Tempo reduzido do abaixo para dinamica de depuração
    end else begin //Execução normal
        Self.tcpclnt.ConnectTimeout := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
    end;
    Self.tcpclnt.Host      := VVSvcConfig.ParentServer;
    Self.tcpclnt.Port      := VVSvcConfig.NetClientPort;
    Self.tcpclnt.OnDisconnected := tcpclntDisconnected;
    Self.tcpclnt.OnConnected := tcpclntConnected;
    Self.tcpclnt.ConnectTimeout := 0;
    Self.tcpclnt.IPVersion := Id_IPv4;
    Self.tcpclnt.ReadTimeout := -1;
    //Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
    TLogFile.LogDebug(Format('Falando na porta:(%d) - Servidor:(%s)', [VVSvcConfig.NetClientPort, VVSvcConfig.ParentServer]),
        DBGLEVEL_DETAILED);
end;


procedure TDMTCPTransfer.StartServer;
 ///<summary>
 ///Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas)
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    TLogFile.LogDebug('Ajustando parametros para o modo servidor', DBGLEVEL_ULTIMATE);
    try
        Self.InitSettings;
        Self.tcpsrvr.OnStatus    := tcpsrvrStatus;
        Self.tcpsrvr.DefaultPort := VVSvcConfig.NetServicePort;
        Self.tcpsrvr.OnExecute   := tcpsrvrExecute;
        Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
        Self.tcpsrvr.Active      := True;
        Self.tcpsrvr.StartListening;
        //Self.TrayIcon.IconIndex := II_SERVER_IDLE; não pode ser alterado pelo inicio do servidor
        TLogFile.LogDebug(Format('Escutando na porta: %d', [VVSvcConfig.NetServicePort]), DBGLEVEL_DETAILED);
    except
        on E : Exception do begin
            TLogFile.Log(Format('Erro fatal abrindo porta %d.'#13#10'%s', [VVSvcConfig.NetServicePort, E.Message]), lmtError);
            raise E;
        end;
    end;
end;

function TDMTCPTransfer.StartSession(const SessionName : string) : string;
var
    msg : string;
begin
    try
        Self.FClientSessionList.Enter;
        try
            if (Self.FClientSessionList.IndexOf(SessionName) <> -1) then begin
                //raise ESVCLException.Create('Sessão iniciada previamente neste módulo');
                Exit;  //Operação anterior ainda em andamento
            end;
        finally
            Self.FClientSessionList.Leave;
        end;
        //Envia a abertura de sessão para o servidor
        Self.tcpclnt.Connect;
        //passa valores obrigatorios para inicio de sessão
        Self.tcpclnt.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //cabecalho da sessão
        Self.tcpclnt.IOHandler.WriteLn(VVerService.fvInfo.FileVersion); //versão do cliente
        Self.tcpclnt.IOHandler.WriteLn(VVSvcConfig.ClientName); //Nome do computador cliente
        Self.tcpclnt.IOHandler.WriteLn(STR_BEGIN_SESSION_SIGNATURE + SessionName); //repete cabecalho da sessão
        Result := Self.tcpclnt.IOHandler.ReadLn();
        if (not SameText(Result, STR_OK_PACK)) then begin
            try
                msg := Self.tcpclnt.IOHandler.ReadLn();
            except
                on E : Exception do begin
                    msg := '"' + msg + '"'#13#10 + E.Message;
                end;
            end;
            raise ESVCLException.Create('Sessão não pode ser iniciada: ' + msg);
        end;
        try
            Self.FClientSessionList.Add(SessionName);
        finally
            Self.FClientSessionList.Leave;
        end;
    except
        on E : Exception do begin //colocar como registro de depuração, por se tratar de erro comum
            TLogFile.LogDebug(Format
                ('Falha de comunicação com o servidor pai desta instância(%s) na porta(%d).'#13#10,
                [Self.tcpclnt.Host, Self.tcpclnt.Port]) +
                E.Message, DBGLEVEL_ALERT_ONLY);
            raise;
        end;
    end;
end;

procedure TDMTCPTransfer.StopClient;
 ///<summary>
 ///Atividade opcional, pois o processamento por sessão é rápido
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    if (Self.tcpclnt.Connected()) then begin
        Self.tcpclnt.Disconnect;
    end;
end;

procedure TDMTCPTransfer.StopServer;
begin
    if (Self.tcpsrvr.Active) then begin
        Self.tcpsrvr.StopListening;
        Self.tcpsrvr.Active := False;
        TLogFile.LogDebug('Servidor interrompido!', DBGLEVEL_DETAILED);
    end;
end;

procedure TDMTCPTransfer.tcpclntConnected(Sender : TObject);
begin
    TLogFile.LogDebug('Conectado ao servidor', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpclntDisconnected(Sender : TObject);
begin
    TLogFile.LogDebug('Desconectado do servidor', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpsrvrConnect(AContext : TIdContext);
begin
    Self.UpdateServerTrayStatus();
end;

procedure TDMTCPTransfer.tcpsrvrDisconnect(AContext : TIdContext);
begin
    Self.UpdateServerTrayStatus();
end;

procedure TDMTCPTransfer.tcpsrvrExecute(AContext : TIdContext);
 ///<summary>
 ///Metodo de operação do tcpserver para cada conexão realizada
 ///</summary>
 ///<remarks>
 /// Todos os parametros são pegos por linha
 /// Estudar como proteger o metodo e o timeout da passagem dos dados
 ///</remarks>
var
    sFooter, sClientVersion, smodifiedDate, sClientSessionName, sClientName, sFileSize, sHash : string;
    sHeader, retHash : string;
    inStrm : TMemoryStream;
    nFileSize : int64;
    SyncSession : TServerSyncSession;
    ret : string;

begin
    //Criticidade em ReadBytes para o stream, ajustado para 30 segundos
    AContext.Connection.Socket.ReadTimeout := 30000;
    TLogFile.LogDebug(Format('Sessão inciada, cliente: %s', [AContext.Connection.Socket.Binding.PeerIP]), DBGLEVEL_DETAILED);
    AContext.Connection.IOHandler.AfterAccept; //processamento pos conexao com sucesso

    try
        SyncSession := nil;
        //***Dados passados para abertura de sessão:
        //1 - cabecalho da sessão contendo nome da sessão
        //2 - versão do cliente
        //3- Nome do computador
        //4 - fim cabecalho cadeia igual ao inicio

        sHeader := AContext.Connection.IOHandler.ReadLn(); //Aguarda a assinatura do cliente para iniciar operação
        if (not TStrHnd.startsWith(sHeader, STR_BEGIN_SESSION_SIGNATURE)) then begin
            //Cancela a sessão por falha de protocolo
            TLogFile.LogDebug(
                Format('Falha de protocolo, cadeia recebida="%s"', [sHeader]), DBGLEVEL_ALERT_ONLY);
            AContext.Connection.IOHandler.WriteLn(STR_FAIL_PROTOCOL); //informa e sai
            Exit;
        end else begin
            sClientSessionName := Copy(sHeader, Length(STR_BEGIN_SESSION_SIGNATURE) + 1, Length(sHeader));
        end;

        //Linha incial de dados deve conter os atributos do arquivo(fullname, createdDate, accessDate, modifiedDate, Size )
        //No inicio da operação, captura as cadeias. Caso a linha possua o token de final de sessão desconecta(o servidor espera uma nova sessão)
        sClientVersion := AContext.Connection.IOHandler.ReadLn();
        sClientName := AContext.Connection.IOHandler.ReadLn();
        sFooter := AContext.Connection.IOHandler.ReadLn();
        if (not SameText(sFooter, sHeader)) then begin
            TLogFile.Log(Format('Falha de protocolo, cadeia recebida="%s"', [sHeader]), lmtWarning);
            AContext.Connection.IOHandler.WriteLn(STR_FAIL_PROTOCOL); //informa falha e cai fora
            Exit; //termina sessão frustada
        end;

        {TODO -oroger -cdsg : buscar por duplicidade de sessão}
		 SyncSession := TServerSyncSession.Create(AContext, sClientName, sClientVersion, sClientSessionName);
        Self.FServerSessionList.Add(sClientSessionName, SyncSession);
        {TODO -oroger -cdsg : registrar log de depuração do evento acima}
        AContext.Connection.IOHandler.WriteLn(STR_OK_PACK); //informa OK e em seguida apto a executar os verbos da sessão
        ret := SyncSession.DoExecVerbs(); //repete o protocolo até o recebimento de fim de sessão

    finally
        //Finaliza a sessão
        try
            if (Assigned(SyncSession)) then begin
                Self.FServerSessionList.Extract(SyncSession);
            end;
            AContext.Connection.Disconnect;
        finally
            if (TStrHnd.endsWith(sHeader, STR_END_SESSION_SIGNATURE)) then begin
                TLogFile.LogDebug('Sessão encerrada normalmente', DBGLEVEL_DETAILED);
            end else begin
                TLogFile.Log(Format('Cliente("%s") desconectado abruptamente', [sClientName]), lmtWarning);
            end;
        end;
    end;
end;

procedure TDMTCPTransfer.tcpsrvrStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
begin
    TLogFile.LogDebug(Format('Status do servidor: "%s"', [AStatusText]), DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.TrayIconMouseMove(Sender : TObject; Shift : TShiftState; X, Y : Integer);
///Atualiza status da dica, informando o tráfego atual da sessão
var
    rtVersion : string;
    hint :      string;
begin
    if (not Assigned(VVerService)) then begin
        rtVersion := '*** VERSÃO DESCONHECIDA ***';
    end else begin
        try
            rtVersion := 'Versão: ' + VVerService.fvInfo.FileVersion;
        except
            on E : Exception do begin
                rtVersion := '*** VERSÃO DESCONHECIDA ***';
            end;
        end;
    end;
    hint := 'SESOP - Verificador de Versões' + #13#10 + rtVersion + #13#10;
    if (Self.tcpsrvr.Bindings.Count > 0) then begin
        Hint := Hint + 'Clientes conectados = ' + IntToStr(Self.tcpsrvr.Bindings.Count) + #13#10;
    end;
    if (Self.tcpclnt.Connected) then begin
        Hint := Hint + 'Download em andamento' + #13#10;
    end;
    if (not Assigned(VVSvcConfig.ProfileInfo)) then begin
        Hint := Hint + 'Não foi possível identificar perfil deste computador!!!' + #13#10;

    end;
    Self.TrayIcon.Hint := Hint;
end;

procedure TDMTCPTransfer.UpdateServerTrayStatus;
var
    List : TList;
    clientCount : Integer;
begin
    try
        List := Self.tcpsrvr.Contexts.LockList;
        clientCount := List.Count;
    finally
        Self.tcpsrvr.Contexts.UnlockList;
    end;
    if (clientCount > 0) then begin
        //Self.TrayIcon.IconIndex := II_SERVER_BUZY;
        if (Self.FMaxTrackedClients < clientCount) then begin
            Self.FMaxTrackedClients := clientCount;
            TLogFile.LogDebug(Format('Registro de clientes simultâneos aumentado = %d', [Self.FMaxTrackedClients]),
                DBGLEVEL_DETAILED);
        end;
    end else begin
        //Self.TrayIcon.IconIndex := II_SERVER_IDLE;
    end;
end;

{ TTransferFile }

constructor TTransferFile.Create;
begin
    inherited Create;
    Self.FIsInputFile := True; //Atributo RO indica que o arquivo será lido como entrada da transmissão
end;

constructor TTransferFile.CreateOutput(const Filename : string);
    ///<summary>
    ///Construtor de arquivo de transferencia, realiza a leitura dos atributos do arquivo para repassar para a saida
    ///</summary>
    ///<remarks>
    ///
    ///</remarks>
begin
    inherited;
    Self.FIsInputFile := False;
    Self.FFilename    := Filename;
    FileHnd.TFileHnd.FileTimeProperties(Self.FFilename, Self.FCreatedTime, Self.FAccesTime, Self.FModifiedTime);
end;

destructor TTransferFile.Destroy;
begin
    if (Assigned(Self.FStream)) then begin
        FreeAndNil(Self.FStream);
    end;
    inherited;
end;

function TTransferFile.GetDateStamp : string;
    /// <summary>
    /// Retorna a cadeia no formato YYYY\MM\DD para a data de modificação do arquivo
    /// </summary>
var
    modDate, dummy : TDateTime;
    //FullDateStr, sy, sm, sd : string;
begin
    TFileHnd.FileTimeProperties(Self.FFilename, dummy, dummy, modDate);

    Result := FormatDateTime('YYYY\MM\DD', modDate);
    {

    FullDateStr :=FormatDateTime( 'YYYMMDD' , modDate );

     sy := Copy(FullDateStr, 1, 4);
     sm := Copy(FullDateStr, 5, 2);
     sd := Copy(FullDateStr, 7, 2);
    }
end;

function TTransferFile.GetHash : string;
begin
    if (Self.FHash = EmptyStr) then begin
        Self.FHash := THashHnd.MD5(Self.FFilename);
    end;
    Result := Self.FHash;
end;

function TTransferFile.GetSize : int64;
begin
    Result := TFileHnd.FileSize(Self.FFilename);
end;

procedure TTransferFile.InvalidWriteOperation(const AttrName : string);
begin
    raise Exception.CreateFmt('Atributo "%s" para arquivo tipo entrada não pode ter este atributo altereado.', [AttrName]);
end;

procedure TTransferFile.ReadFromStream(AStream : TStream);
begin
    if (not Assigned(Self.FStream)) then begin
        Self.FStream := TMemoryStream.Create;
    end;
    Self.FStream.CopyFrom(AStream, AStream.Size);
end;

procedure TTransferFile.SetFilename(const Value : string);
{TODO -oroger -cfuture : diferenciar a carga nomral do construtor para carregar pelo streamer os dados das datas do arquivo }
begin
    if (not Self.FIsInputFile) then begin
        Self.FFilename := Value;
    end else begin
        Self.InvalidWriteOperation('Nome do arquivo:' + Value + ' não pode ser alterado neste momento');
    end;
end;

{ TThreadStringList }

constructor TThreadStringList.Create;
begin
    inherited;
    Self.FLocker := TCriticalSection.Create;
end;

destructor TThreadStringList.Destroy;
begin
    FreeAndNil(Self.FLocker);
    inherited;
end;

procedure TThreadStringList.Enter;
begin
    Self.FLocker.Enter;
end;

procedure TThreadStringList.Leave;
begin
    Self.FLocker.Leave;
end;

{ TSyncSession }

constructor TServerSyncSession.Create(AContext : TidContext; const AClientName, AClientVersion, ASessionName : string);
begin
	 inherited Create;
    Self.FSessionName := ASessionName;
    Self.FContext     := AContext;
    Self.FClientVersion := AClientVersion;
    Self.FClientName  := AClientName;
end;

function TServerSyncSession.DoExecVerbs : string;
var
    sVerb, sLine : string;
    execVerb :     TVVSVerbs;

begin
    Result := STR_OK_PACK;
    repeat
        sLine := Self.Context.Connection.IOHandler.ReadLn();
        sVerb := TStrHnd.CopyAfterLast(STR_CMD_VERB, sLine); {TODO -oroger -cdebug : gerar erro}
        if (sVerb = EmptyStr) then begin
            Result := STR_FAIL_PROTOCOL;
            Self.Context.Connection.IOHandler.WriteLn(Result);
            Self.Context.Connection.IOHandler.WriteLn('Aguardando operação não recebida');
            Exit;
        end else begin
            if (sVerb = STR_VERB_EXIT) then begin
                Exit;
            end;
            try
                execVerb := String2Verb(sVerb);
                try
                    case execVerb of
                        vvvReadContent : begin //monta json com versões dos arquivos
                            Result := Self.ExecReadContent();
                        end;
                        vvvFileDownload : begin
                            Result := Self.ExecFileDownload();
						 end;
						 vvvFullFingerprint : begin
                        	Result:= Self.ExecFileFingerPrint();
						 end;
                    end;
                    Self.Context.Connection.IOHandler.WriteLn(Result);//envia retorno da operação
                except
                    on E : Exception do begin
                        Result := STR_FAIL_RETURN;
                        Self.Context.Connection.IOHandler.WriteLn(Result);//envia retorno da operação
                        Self.Context.Connection.IOHandler.WriteLn(HttpEncode(E.Message));//envia retorno da operação
                        Exit;
                    end;
                end;
            except
                on E : Exception do begin
                    Result := STR_FAIL_PROTOCOL;
                    Self.Context.Connection.IOHandler.WriteLn(Result);
                    Self.Context.Connection.IOHandler.WriteLn('Operação inválida = "' + sVerb + '"');
                    Exit;
                end;
            end;
        end;
    until (False);
end;

function TServerSyncSession.ExecFileDownload : string;
begin
end;

function TServerSyncSession.ExecFileFingerPrint: string;
var
	 filename, pubname : string;
	 vf : TVVSFile;
begin
	 //espera como argumento unico o nome da publicação
	 try
		 pubname := Self.Context.Connection.IOHandler.ReadLn();
		 if (not SameText(pubname, PUBLICATION_INSTSEG)) then begin  //atualmente apenas esta publicação??
			 Result := STR_FAIL_VERB;
		 end else begin
			filename := Self.Context.Connection.IOHandler.ReadLn();
			if ( GlobalPublication.ManagedFolder.TryGetValue( filename, vf ) ) then begin
				Result:= vf.FingerPrints;
			end else begin
            	raise ESVCLException.CreateFmt('Arquivo "%s" não existe na publicação informada.', [ filename ] );
			end;
			Assert( ( Result <> EmptyStr ), 'fingerprint nula?' );
			Result:=HttpEncode( Result );
		 end;
	 except
		 on E : Exception do begin
			Result := E.Message + TOKEN_DELIMITER + STR_FAIL_PROTOCOL + TOKEN_DELIMITER;
			Exit;
		 end
	 end;
	 Result := Result + TOKEN_DELIMITER + STR_OK_PACK + TOKEN_DELIMITER; //resposta normal deste método
end;

function TServerSyncSession.ExecReadContent : string;
var
	 pubname : string;
begin
	 //espera como argumento unico o nome da publicação
	 try
		 pubname := Self.Context.Connection.IOHandler.ReadLn();
		 if (not SameText(pubname, PUBLICATION_INSTSEG)) then begin  //atualmente apenas esta publicação??
			 Result := STR_FAIL_VERB;
		 end else begin
			Result:=HttpEncode( GlobalPublication.ManagedFolder.ToString() );
		 end;
	 except
		 on E : Exception do Result := STR_FAIL_PROTOCOL;
	 end;
	 Result := Result + TOKEN_DELIMITER + STR_OK_PACK;
end;

end.
