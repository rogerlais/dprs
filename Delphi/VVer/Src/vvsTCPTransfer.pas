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
        FSessionFileTransfer : TFileStream;
        function ExecReadContent() : string;
        function ExecFileDownload() : string;
        function ExecFileClose() : string;
        function ExecFileFingerPrint() : string;
        function ExecRegisterStatus() : string;
        function ExecReadSegment() : string;
    public
        property ClientName : string read FClientName;
        property ClientVersion : string read FClientVersion;
        property SessionName : string read FSessionName;
        property Context : TIdContext read FContext;
        {TODO -oroger -cdsg : capturar no construtor todos os eventos do context desejáveis }
        constructor Create(AContext : TidContext; const AClientName, AClientVersion, ASessionName : string); virtual;
        destructor Destroy; override;
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
        FClientSessionList : TThreadStringList; //Container para a lista de sessões clientes ativas(usada para notificação)
        FServerSessionList : TSyncSessionServerList;
        FMaxTrackedClients : Integer;
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
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
    DMTCPTransfer : TDMTCPTransfer = nil; //Criado manualmente nas aplicações de teste

implementation

uses
    FileHnd, StrHnd, vvSvcDM, Math, vvConfig;

{$R *.dfm}

var
    ForcedFormatSettings : TFormatSettings;

constructor TDMTCPTransfer.Create(AOwner : TComponent);
begin
    inherited;
    Self.FClientSessionList := TThreadStringList.Create;
    Self.FServerSessionList := TSyncSessionServerList.Create;
    if (not Assigned(GlobalInfo.ProfileInfo)) then begin
        Self.TrayIcon.IconIndex := II_CLIENT_ERROR; //indica falha de identificação de perfil
    end else begin
        Self.TrayIcon.IconIndex := II_CLIENT_IDLE; //Nada a se "adivinhar" ainda
    end;
end;

procedure TDMTCPTransfer.DataModuleCreate(Sender : TObject);
begin
    Self.tcpsrvr.ReuseSocket := rsFalse;
    Self.tcpclnt.ReuseSocket := rsFalse;
    Self.tcpclnt.ReadTimeout; {TODO -oroger -cdsg : Pra que isso acima????}
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
    ForcedFormatSettings.DecimalSeparator  := '.';
    ForcedFormatSettings.ThousandSeparator := ' ';
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
	 Self.tcpclnt.Host      := GlobalInfo.PublicationParentServer;
    Self.tcpclnt.Port      := GlobalInfo.NetClientPort;
    Self.tcpclnt.OnDisconnected := tcpclntDisconnected;
    Self.tcpclnt.OnConnected := tcpclntConnected;
    Self.tcpclnt.ConnectTimeout := 0; {TODO -oroger -cdsg : deixar configuravel este e ReadTimerout}
    Self.tcpclnt.IPVersion := Id_IPv4;
    Self.tcpclnt.ReadTimeout := 0;  //usa o valor dado por  IdTimeoutDefault
    //Self.TrayIcon.IconIndex := II_CLIENT_IDLE;
	 TLogFile.LogDebug(Format('Falando na porta:(%d) - Servidor:(%s)', [Self.tcpclnt.Port, Self.tcpclnt.Host]), DBGLEVEL_DETAILED);
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
        Self.tcpsrvr.DefaultPort := GlobalInfo.NetClientPort;
        Self.tcpsrvr.OnExecute   := tcpsrvrExecute;
        Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
        Self.tcpsrvr.Active      := True;
		 Self.tcpsrvr.StartListening;
		 TLogFile.LogDebug(Format('Escutando na porta: %d', [ Self.tcpsrvr.DefaultPort ]), DBGLEVEL_DETAILED);
    except
        on E : Exception do begin
			 TLogFile.Log(Format('Erro fatal abrindo porta %d.'#13#10'%s', [Self.tcpsrvr.DefaultPort , E.Message]), lmtError);
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
		 Self.tcpclnt.IOHandler.WriteLn(GlobalInfo.ClientName); //Nome do computador cliente
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
            raise EVVException.Create('Sessão não pode ser iniciada: ' + msg);
        end;
        Self.FClientSessionList.Enter;
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
        try
            Self.FServerSessionList.Add(sClientSessionName, SyncSession);
            try
                {TODO -oroger -cdsg : registrar log de depuração do evento acima}
                AContext.Connection.IOHandler.WriteLn(STR_OK_PACK); //informa OK e em seguida apto a executar os verbos da sessão
                ret := SyncSession.DoExecVerbs(); //repete o protocolo até o recebimento de fim de sessão
            finally
                Self.FServerSessionList.Extract(SyncSession);
            end;
        finally
            SyncSession.Free; //finaliza a sessão de sincronismo
        end;
    finally
        try
            AContext.Connection.Disconnect; //Finaliza a sessão
        finally
            if (ret = STR_OK_PACK) then begin
                TLogFile.LogDebug('Sessão encerrada normalmente', DBGLEVEL_DETAILED);
            end else begin
                TLogFile.Log(Format('Cliente("%s") desconectado abruptamente com o seguinte retorno("%s")',
                    [sClientName, ret]), lmtWarning);
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
    if (not Assigned(GlobalInfo.ProfileInfo)) then begin
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

destructor TServerSyncSession.Destroy;
begin
    if (Assigned(Self.FSessionFileTransfer)) then begin
        FreeAndNil(Self.FSessionFileTransfer);
    end;
    inherited;
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
                        vvvFileClose : begin
                            Result := Self.ExecFileClose();
                        end;
                        vvvFullFingerprint : begin
                            Result := Self.ExecFileFingerPrint();
                        end;
                        vvvReadSegment : begin
                            Self.ExecReadSegment();
                            Result := STR_OK_PACK;
                        end;
                        vvvRegisterStatus : begin
                            Result := Self.ExecRegisterStatus();
                        end;
                        vvvEndSession : begin
                            Result := STR_OK_PACK;
                            Exit; //termina o ciclo sem postar nada para o cliente
                        end;
                        else begin
                            Result := STR_FAIL_VERB;
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

function TServerSyncSession.ExecFileClose : string;
    //Le o Id do download e o fecha
    //envia data de criação, modificação, acesso
var
    outId : string;
    vf :    TVVSFile;
    hnd :   cardinal;
    modDate, createDate, accDate : TDateTime;
begin
    Result := EmptyStr;
    try
        outId := Self.Context.Connection.IOHandler.ReadLn();
        hnd   := StrToInt(outId);
        if (hnd = Self.FSessionFileTransfer.Handle) then begin
            //leitura das datas do arquivo
            TFileHnd.FileTimeProperties(Self.FSessionFileTransfer.Handle, createDate, accDate, modDate);
            Result := FloatToStr(createDate) + TOKEN_DELIMITER + FloatToStr(modDate) + TOKEN_DELIMITER + FloatToStr(accDate) +
                TOKEN_DELIMITER + IntToStr(Self.FSessionFileTransfer.Size);
            FreeAndNil(Self.FSessionFileTransfer);
        end else begin
            {TODO -oroger -cdsg : gerar erro}
            raise Exception.CreateFmt('Falha no fechamento do arquivo corrente da sessão. Id interno = %d, ID solicitado = %d',
                [Self.FSessionFileTransfer.Handle, hnd]);
        end;
    except
        on E : Exception do begin
            Result := HTTPEncode(E.Message) + TOKEN_DELIMITER + STR_FAIL_PROTOCOL;
            Exit;
        end
    end;
    Result := HTTPEncode(Result) + TOKEN_DELIMITER + STR_OK_PACK; //resposta normal deste método
end;

function TServerSyncSession.ExecFileDownload : string;
    //Le publicação e nome do arquivo
    //envia id do download, hash do arquivo, e seu tamanho
var
    pubName, clientFilename, filename, outId : string;
    vf : TVVSFile;
begin
    Result := EmptyStr;
    try
        pubname := Self.Context.Connection.IOHandler.ReadLn();
        if (not SameText(pubname, PUBLICATION_INSTSEG)) then begin  //atualmente apenas esta publicação??
            Result := STR_FAIL_VERB;
        end else begin
            clientFilename := Self.Context.Connection.IOHandler.ReadLn();
            if (GlobalPublication.ManagedFolder.TryGetValue(clientFilename, vf)) then begin
                Assert(not Assigned(Self.FSessionFileTransfer), 'Sessão já abriu arquivo anteriomente');
                Self.FSessionFileTransfer := TFileStream.Create(vf.FullFilename, fmOpenRead); //captura stream para transferencia
                Result := IntToStr(Self.FSessionFileTransfer.Handle) + TOKEN_DELIMITER + //Id do download
                    vf.MD5String + TOKEN_DELIMITER + //hash total do arquivo
                    IntToStr(vf.Size); //tamanho total do arquivo
            end else begin
                raise EVVException.CreateFmt('Arquivo "%s" não existe na publicação informada.', [filename]);
            end;
        end;
    except
        on E : Exception do begin
            Result := HTTPEncode(E.Message) + TOKEN_DELIMITER + STR_FAIL_PROTOCOL;
            Exit;
        end
    end;
    Result := HttpEncode(Result) + TOKEN_DELIMITER + STR_OK_PACK; //resposta normal deste método
end;

function TServerSyncSession.ExecFileFingerPrint : string;
var
    filename, pubname : string;
    vf : TVVSFile;
begin
    //espera como argumento unico o nome da publicação
    try
        pubname := Self.Context.Connection.IOHandler.ReadLn();
        if (not SameText(pubname, PUBLICATION_INSTSEG)) then begin  //atualmente apenas esta publicação??
            Result := HttpEncode('Publicação inválida solicitada') + TOKEN_DELIMITER + STR_FAIL_VERB;
            Exit;
        end else begin
            filename := Self.Context.Connection.IOHandler.ReadLn();
            if (GlobalPublication.ManagedFolder.TryGetValue(filename, vf)) then begin
                Result := vf.FingerPrints;
            end else begin
                raise EVVException.CreateFmt('Arquivo "%s" não existe na publicação informada.', [filename]);
            end;
            Assert((Result <> EmptyStr), 'fingerprint nula?');
        end;
    except
        on E : Exception do begin
            Result := HTTPEncode(E.Message) + TOKEN_DELIMITER + STR_FAIL_PROTOCOL;
            Exit;
        end
    end;
    Result := HttpEncode(Result) + TOKEN_DELIMITER + STR_OK_PACK; //resposta normal deste método
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
            Result := GlobalPublication.ManagedFolder.ToString();
        end;
    except
        on E : Exception do begin
            Result := HttpEncode(E.Message) + TOKEN_DELIMITER + STR_FAIL_PROTOCOL;
            Exit;
        end;
    end;
    Result := HttpEncode(Result) + TOKEN_DELIMITER + STR_OK_PACK;
end;

function TServerSyncSession.ExecReadSegment : string;
    //espera como argumento unico o handle do arquivo aberto e o ordinal do mesmo. IMPORTANTE TODOS DEVEM POSSUIR O MESMO TAMANDO DE BLOCO
    //a resposta enviada será
    //(bytes no streamer a serem lidos) + SOK parcial + (streamer) + (hash caculado do segmento ) + (bytes faltantes) + SOK
var
    downID : THandle;
    jumpBytes, segNumber : int64;
    segHash, intRead : string;
    ms :     TMemoryStream;
    bs :     Integer;
begin
    //espera como argumento unico o handle do arquivo aberto e o ordinal do mesmo. IMPORTANTE TODOS DEVEM POSSUIR O MESMO TAMANDO DE BLOCO
    bs := GlobalInfo.BlockSize;
    try
        Assert(Assigned(Self.FSessionFileTransfer), 'Arquivo para transferencia não alocado anteriormente nesta sessão');
        intRead := Self.Context.Connection.IOHandler.ReadLn();
        try
            downId := StrToInt(intRead);
        except
            on E : Exception do begin
                raise Exception.CreateFmt('Valor recebido("%s") para identificador do arquivo inválido', [intRead]);
            end;
        end;

        intRead := Self.Context.Connection.IOHandler.ReadLn();
        try
            segNumber := StrToInt64(intRead);
        except
            on E : Exception do begin
                raise Exception.CreateFmt('Valor recebido("%s") para segmento do arquivo inválido', [intRead]);
            end;
        end;

        {TODO -oroger -cdsg : colocar a checagem do handle do arquivo}

        jumpBytes := bs * segNumber;
        Self.FSessionFileTransfer.Position := jumpBytes;
        ms := TMemoryStream.Create;
        try
            jumpBytes := Math.Min(bs, self.FSessionFileTransfer.Size - Self.FSessionFileTransfer.Position);
            ms.CopyFrom(Self.FSessionFileTransfer, jumpBytes);
            ms.Position := 0;
            segHash     := TVVerService.GetBlockHash(ms, MD5_BLOCK_ALIGNMENT);
            //informa que operação pode ser iniciada
            Self.Context.Connection.IOHandler.WriteLn(STR_OK_PACK);
            //informa que serão enviados jumpBytes no streamer
            Self.Context.Connection.IOHandler.WriteLn(IntToStr(jumpBytes));
            //Escreve o streamer
            ms.Position := 0;
            Self.Context.Connection.IOHandler.Write(ms);
            //Escreve hash calculado do lado do servidor no momento
            Self.Context.Connection.IOHandler.WriteLn(segHash);
            //Escreve bytes faltantes
            Result := (IntToStr(Self.FSessionFileTransfer.Size - Self.FSessionFileTransfer.Position));
        finally
            ms.Free;
        end;
    except
        on E : Exception do begin
            Result := HTTPEncode(E.Message) + TOKEN_DELIMITER + STR_FAIL_PROTOCOL;
            Exit;
        end
    end;
    Result := HttpEncode(Result) + TOKEN_DELIMITER + STR_OK_PACK; //resposta normal deste método quanto falta
end;

function TServerSyncSession.ExecRegisterStatus : string;
    //leitura do status do cliente
    //grava retorno da operação
var
    Data : string;
    filename : string;
    sl : TStringList;
begin
    Data     := Self.Context.Connection.IOHandler.ReadLn();
	filename := GlobalInfo.PathClientInfo;
    ForceDirectories(filename);
    filename := TFileHnd.ConcatPath([filename, Self.FClientName + '.txt']);
    sl := TStringList.Create;
    try
        sl.Text := HTTPDecode(Data);
        sl.SaveToFile(filename);
    finally
        sl.Free;
    end;
    Result := HTTPEncode('OK') + TOKEN_DELIMITER + STR_OK_PACK;
end;

end.
