unit svclTCPTransfer;

interface

uses
    SysUtils, Classes, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
    IdTCPServer, AppLog, XPFileEnumerator;

type
	 TTransferFile = class
	 private
		 FAccesTime :    TDateTime;
		 FModifiedTime : TDateTime;
		 FCreatedTime :  TDateTime;
		 FFilename :     string;
	 	 FIsInputFile: Boolean;
		 procedure SetFilename(const Value : string);
	 	 procedure InvalidWriteOperation( const AttrName : string );
	 public
		 property Filename : string read FFilename write SetFilename;
		 property IsInputFile : Boolean read FIsInputFile;
		 property AccesTime : TDateTime read FAccesTime;
		 property ModifiedTime : TDateTime read FModifiedTime;
		 property CreatedTime : TDateTime read FCreatedTime;
		 constructor CreateOutput( const Filename : string );
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
    procedure tcpsrvrStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
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
	 svclConfig, FileHnd;

{$R *.dfm}

procedure TDMTCPTransfer.DataModuleDestroy(Sender : TObject);
begin
    //Fecha clientes e servidor
    Self.tcpclnt.Disconnect;
    Self.tcpsrvr.Active := False;
end;

procedure TDMTCPTransfer.SendFile(AFile : TTransferFile);
var
	s : string;
begin
	 {TODO -oroger -cdsg : realiza a transferencia do arquivo para o servidor}
	 s:=AFile.ToString;
	 Self.tcpclnt.Connect;
	 Self.tcpclnt.IOHandler.WriteLn( s );
end;

procedure TDMTCPTransfer.StartClient;
begin
	 {TODO -oroger -cdsg : Ajusta o container para funcionar apenas como cliente(envio de arquivos apenas) }
	 Self.tcpclnt.ConnectTimeout:= 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	 Self.tcpclnt.Host:= GlobalConfig.PrimaryBackupPath
	 GlobalConfig.NetServicePort;
	 Self.tcpclnt.Active      := True;
	 Self.tcpclnt.StartListening;
	 TLogFile.LogDebug( Format( 'Escutando na porta: %d', [ GlobalConfig.NetServicePort ]  ), DBGLEVEL_DETAILED );
end;


procedure TDMTCPTransfer.StartServer;
begin
	 {TODO -oroger -cdsg : Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas) }
	 Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
	 Self.tcpsrvr.DefaultPort := GlobalConfig.NetServicePort;
	 Self.tcpsrvr.Active      := True;
	 Self.tcpsrvr.StartListening;
	 TLogFile.LogDebug( Format( 'Escutando na porta: %d', [ GlobalConfig.NetServicePort ]  ), DBGLEVEL_DETAILED );
end;

procedure TDMTCPTransfer.StopClient;
begin
	{TODO -oroger -cdsg : Atividade opcional, pois o processamento por sessão é rápido}
end;

procedure TDMTCPTransfer.StopServer;
begin
	Self.tcpsrvr.StopListening;
	Self.tcpsrvr.Active:=False;
	TLogFile.LogDebug( 'Servidor interrompido!', DBGLEVEL_DETAILED );
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
    sfilename, smodifiedDAte, saccessDate, screateDate, sFileSize : string;
begin
    AContext.Connection.IOHandler.AfterAccept;
    {TODO -oroger -cdsg : Linha incial de dados deve conter os atributos do arquivo(fullname, createdDate, accessDate, modifiedDate, Size ) }
    sfilename     := AContext.Connection.IOHandler.ReadLn();
    screateDate   := AContext.Connection.IOHandler.ReadLn();
    saccessDate   := AContext.Connection.IOHandler.ReadLn();
    smodifiedDAte := AContext.Connection.IOHandler.ReadLn();
    sFileSize     := AContext.Connection.IOHandler.ReadLn();


    TLogFile.LogDebug(Format(
        'Recebida cadeia do cliente ao servidor: arquivo="%s" , criação=%s, acesso=%s, Modiciação=%s, tamanho=%s',
		 [sfilename, smodifiedDate, saccessDate, screateDate, sFileSize]), DBGLEVEL_DETAILED );

    AContext.Connection.IOHandler.WriteLn('OK'); //informa OK e em seguida o tamanho do streamer lido
    {TODO -oroger -cdsg : Confirmar que a quantidade lida bate com a informada originalmente abaixo }
    AContext.Connection.IOHandler.WriteLn(sFileSize);

    //Finaliza a sessão
    AContext.Connection.Disconnect;

end;

procedure TDMTCPTransfer.tcpsrvrStatus(ASender: TObject; const AStatus: TIdStatus; const AStatusText: string);
begin
	TLogFile.LogDebug( Format( 'Status do servidor: "%s"', [ AStatusText ]  ), DBGLEVEL_DETAILED );
end;

{ TTransferFile }

constructor TTransferFile.Create;
begin
	Self.FIsInputFile:=True; //Atributo RO indica que o arquivo será lido como entrada da transmissão
end;

constructor TTransferFile.CreateOutput(const Filename: string);
begin
	Self.FIsInputFile:=False;
	Self.FFilename:=Filename;
	{TODO -oroger -cdsg : Leitura dos atributos do arquivo para repassar para a saida}
	FileHnd.TFileHnd.FileTimeProperties( Self.FFilename, Self.FCreatedTime, Self.FAccesTime, Self.FModifiedTime );
end;

procedure TTransferFile.InvalidWriteOperation(const AttrName: string);
begin
	raise Exception.CreateFmt('Atributo "%s" para arquivo tipo entrada não pode ter este atributo altereado.', [ AttrName ]);
end;

procedure TTransferFile.SetFilename(const Value : string);
begin
	if ( not Self.FIsInputFile ) then begin
	 {TODO -oroger -cdsg : diferenciar a carga nomral do construtor para carregar pelo streamer os dados das datas do arquivo }
	 Self.FFilename := Value;
	end else begin
    	Self.InvalidWriteOperation( 'Nome do arquivo' );
   end;
end;

end.
