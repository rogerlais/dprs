unit svclTCPTransfer;

interface

uses
    SysUtils, Classes, Windows, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
    IdTCPServer, AppLog, XPFileEnumerator, IdGlobal;

const
    TOKEN_DELIMITER           = #13#10;
    STR_END_SESSION_SIGNATURE = '=end_session';
    STR_BEGIN_SESSION_SIGNATURE = '=start_session';


type
    TTransferFile = class
    private
        FAccesTime :    TDateTime;
        FModifiedTime : TDateTime;
        FCreatedTime :  TDateTime;
        FFilename :     string;
        FIsInputFile :  boolean;
        procedure SetFilename(const Value : string);
        procedure InvalidWriteOperation(const AttrName : string);
        function GetSize : int64;
        function GetHash : string;
    public
        property Filename : string read FFilename write SetFilename;
        property IsInputFile : boolean read FIsInputFile;
        property AccesTime : TDateTime read FAccesTime;
        property ModifiedTime : TDateTime read FModifiedTime;
        property CreatedTime : TDateTime read FCreatedTime;
        property Size : int64 read GetSize;
        property Hash : string read GetHash;
        constructor CreateOutput(const Filename : string);
        constructor Create();
    end;

type
    TDMTCPTransfer = class(TDataModule)
        tcpsrvr : TIdTCPServer;
        tcpclnt : TIdTCPClient;
        procedure tcpclntConnected(Sender : TObject);
        procedure tcpclntDisconnected(Sender : TObject);
        procedure DataModuleDestroy(Sender : TObject);
        procedure tcpsrvrExecute(AContext : TIdContext);
        procedure tcpsrvrStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
    private
        { Private declarations }
    public
        { Public declarations }
        procedure StartServer();
        procedure StartClient();
        procedure StopServer();
        procedure StopClient();
        procedure SendFile(AFile : TTransferFile);
    end;

var
    DMTCPTransfer : TDMTCPTransfer;

implementation

uses
    svclConfig, FileHnd, svclUtils, StrHnd;

{$R *.dfm}

procedure TDMTCPTransfer.DataModuleDestroy(Sender : TObject);
begin
    //Fecha clientes e servidor
	 Self.StopClient;
	 Self.StopServer;
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
    s :   string;
    fmt : TFormatSettings;
begin
    if (not Self.tcpclnt.Connected) then begin
        raise ESVCLException.Create('Canal com o servidor não estabelecido antecipadamente');
    end;
    SysUtils.GetLocaleFormatSettings(Windows.LOCALE_SYSTEM_DEFAULT, fmt);
    fmt.DecimalSeparator := '.';
    s := AFile.FFilename + TOKEN_DELIMITER +
        FloatToStr(AFile.FAccesTime, fmt) + TOKEN_DELIMITER +
        FloatToStr(AFile.FModifiedTime, fmt) + TOKEN_DELIMITER +
        FloatToStr(AFile.FCreatedTime, fmt) + TOKEN_DELIMITER +
        FloatToStr(AFile.Size, fmt) + TOKEN_DELIMITER + AFile.Hash;
    Self.tcpclnt.IOHandler.WriteLn(s);
    Self.tcpclnt.IOHandler.WriteFile(AFile.Filename);
    s := Self.tcpclnt.IOHandler.ReadLn();
    if (s <> 'OK') then begin
        raise ESVCLException.CreateFmt('Retorno de erro de envio: "%s" para arquivo="%s".', [s, AFile.Filename]);
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
    Self.tcpclnt.ConnectTimeout := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
    Self.tcpclnt.Host      := GlobalConfig.PrimaryComputerName;
    Self.tcpclnt.Port      := GlobalConfig.NetServicePort;
    Self.tcpclnt.OnDisconnected := tcpclntDisconnected;
    Self.tcpclnt.OnConnected := tcpclntConnected;
    Self.tcpclnt.ConnectTimeout := 0;
    Self.tcpclnt.IPVersion := Id_IPv4;
    Self.tcpclnt.ReadTimeout := -1;
    TLogFile.LogDebug(Format('Falando na porta: %d', [GlobalConfig.NetServicePort]), DBGLEVEL_DETAILED);
end;


procedure TDMTCPTransfer.StartServer;
///<summary>
///Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas)
///</summary>
///<remarks>
///
///</remarks>
begin
	 Self.tcpsrvr.OnStatus    := tcpsrvrStatus;
	 Self.tcpsrvr.DefaultPort := GlobalConfig.NetServicePort;
	 Self.tcpsrvr.OnExecute   := tcpsrvrExecute;
	 Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	 Self.tcpsrvr.Active      := True;
	 Self.tcpsrvr.StartListening;
	 TLogFile.LogDebug(Format('Escutando na porta: %d', [GlobalConfig.NetServicePort]), DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.StopClient;
///<summary>
///Atividade opcional, pois o processamento por sessão é rápido
///</summary>
///<remarks>
///
///</remarks>
begin
	 Self.tcpclnt.Disconnect;
end;

procedure TDMTCPTransfer.StopServer;
begin
	 Self.tcpsrvr.StopListening;
	 Self.tcpsrvr.Active := False;
    TLogFile.LogDebug('Servidor interrompido!', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpclntConnected(Sender : TObject);
begin
    TLogFile.LogDebug('Conectado ao servidor', DBGLEVEL_DETAILED);
end;

procedure TDMTCPTransfer.tcpclntDisconnected(Sender : TObject);
begin
    TLogFile.LogDebug('Desconectado do servidor', DBGLEVEL_DETAILED);
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
    sfilename, smodifiedDAte, saccessDate, screateDate, sFileSize, sHash : string;
    retSignature, retHash : string;
    inStrm :    TMemoryStream;
    nFileSize : int64;
begin
    TLogFile.LogDebug(Format('Cliente conectado: %s', [AContext.Connection.Socket.Binding.PeerIP]), DBGLEVEL_DETAILED);
    AContext.Connection.IOHandler.AfterAccept; //processamento pos conexao com sucesso
    try
        retSignature := AContext.Connection.IOHandler.ReadLn(); //Aguarda a assinatura do cliente para iniciar operação
        if (not TStrHnd.endsWith(retSignature, STR_BEGIN_SESSION_SIGNATURE)) then begin
            //Cancela a sessão por falha de protocolo
            TLogFile.LogDebug(
                Format('Falha de protocolo, cadeia recebida=%s', [retSignature]), DBGLEVEL_ALERT_ONLY);
        end;

		 repeat
		 	{TODO -oroger -curgente : testar se a leitura não puder ser completa, qual comportamento das leituras neste momento }
			 {TODO -oroger -cdsg : Linha incial de dados deve conter os atributos do arquivo(fullname, createdDate, accessDate, modifiedDate, Size ) }
			 //No inicio da operação, captura as cadeias. Caso a linha possua o token de final de sessão desconecta(o servidor espera uma nova sessão)
			 //Se a cadeia possui o token de inicio de transferecia pega demais dados
            retSignature := AContext.Connection.IOHandler.ReadLn();
            if (TStrHnd.endsWith(retSignature, STR_END_SESSION_SIGNATURE)) then begin
                System.Continue;
            end;
            sfilename := retSignature;
            screateDate := AContext.Connection.IOHandler.ReadLn();
            saccessDate := AContext.Connection.IOHandler.ReadLn();
            smodifiedDAte := AContext.Connection.IOHandler.ReadLn();
            sFileSize := AContext.Connection.IOHandler.ReadLn();
            sHash := AContext.Connection.IOHandler.ReadLn();

            TLogFile.LogDebug(Format(
                'Recebida cadeia do cliente ao servidor:'#13#10'arquivo="%s"'#13#10'criação=%s'#13#10 +
                'acesso=%s'#13#10'Modificação=%s'#13#10'tamanho=%s'#13#10'hash=$s'#13#10,
                [sfilename, smodifiedDate, saccessDate, screateDate, sFileSize, sHash]), DBGLEVEL_DETAILED);

            nFileSize := StrToInt64(sFileSize); //Tamanho do stream a ser lido pela rede

            inStrm := TMemoryStream.Create();
            try

                AContext.Connection.IOHandler.ReadStream(inStrm, nFileSize);
            finally
                if (inStrm.Size = nFileSize) then begin //Recepção ok -> testar integridade
                    retHash := MD5(inStrm);
                    if (SameText(retHash, sHash)) then begin
                        AContext.Connection.IOHandler.WriteLn('OK'); //informa OK e em seguida o tamanho do streamer lido
                    end else begin
                        AContext.Connection.IOHandler.WriteLn('FAIL HASH'); //informa OK e em seguida o tamanho do streamer lido
                    end;
                end else begin  //Erro de recepção rejeitar arquivo
                    AContext.Connection.IOHandler.WriteLn('FAIL SIZE'); //informa OK e em seguida o tamanho do streamer lido
                end;
                inStrm.Free;
            end;
        until (TStrHnd.endsWith(retSignature, STR_END_SESSION_SIGNATURE)); // assinatura de fim de sessão
    finally
        //Finaliza a sessão
		 AContext.Connection.Disconnect;
        TLogFile.LogDebug('Cliente desconectado', DBGLEVEL_DETAILED);
	 end;
end;

procedure TDMTCPTransfer.tcpsrvrStatus(ASender : TObject; const AStatus : TIdStatus; const AStatusText : string);
begin
    TLogFile.LogDebug(Format('Status do servidor: "%s"', [AStatusText]), DBGLEVEL_DETAILED);
end;

{ TTransferFile }

constructor TTransferFile.Create;
begin
    Self.FIsInputFile := True; //Atributo RO indica que o arquivo será lido como entrada da transmissão
end;

constructor TTransferFile.CreateOutput(const Filename : string);
begin
    Self.FIsInputFile := False;
    Self.FFilename    := Filename;
    {TODO -oroger -cdsg : Leitura dos atributos do arquivo para repassar para a saida}
    FileHnd.TFileHnd.FileTimeProperties(Self.FFilename, Self.FCreatedTime, Self.FAccesTime, Self.FModifiedTime);
end;

function TTransferFile.GetHash : string;
begin
    Result := MD5(Self.FFilename);
end;

function TTransferFile.GetSize : int64;
begin
    Result := TFileHnd.FileSize(Self.FFilename);
end;

procedure TTransferFile.InvalidWriteOperation(const AttrName : string);
begin
    raise Exception.CreateFmt('Atributo "%s" para arquivo tipo entrada não pode ter este atributo altereado.', [AttrName]);
end;

procedure TTransferFile.SetFilename(const Value : string);
begin
    if (not Self.FIsInputFile) then begin
        {TODO -oroger -cdsg : diferenciar a carga nomral do construtor para carregar pelo streamer os dados das datas do arquivo }
        Self.FFilename := Value;
    end else begin
        Self.InvalidWriteOperation('Nome do arquivo');
    end;
end;

end.
