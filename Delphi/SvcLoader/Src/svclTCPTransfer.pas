unit svclTCPTransfer;

interface

uses
    SysUtils, Classes, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer,
    IdTCPServer, AppLog, XPFileEnumerator;

type
    TTransferFile = class(TComponent)
    private
        FAccesTime :    TDateTime;
        FModifiedTime : TDateTime;
        FCreatedTime :  TDateTime;
        FFilename :     string;
        procedure SetFilename(const Value : string);
    public
        property Filename : string read FFilename write SetFilename;
        property AccesTime : TDateTime read FAccesTime;
        property ModifiedTime : TDateTime read FModifiedTime;
        property CreatedTime : TDateTime read FCreatedTime;
    end;

type
    TDMTCPTransfer = class(TDataModule)
        tcpsrvr : TIdTCPServer;
        tcpclnt : TIdTCPClient;
        procedure tcpclntConnected(Sender : TObject);
        procedure tcpclntDisconnected(Sender : TObject);
        procedure DataModuleDestroy(Sender : TObject);
        procedure tcpsrvrExecute(AContext : TIdContext);
    private
        { Private declarations }
    public
        { Public declarations }
        procedure SetupServer();
        procedure SetupClient();
        procedure SendFile(AFile : TTransferFile);
    end;

var
    DMTCPTransfer : TDMTCPTransfer;

implementation

uses
    svclConfig;

{$R *.dfm}

procedure TDMTCPTransfer.DataModuleDestroy(Sender : TObject);
begin
    //Fecha clientes e servidor
    Self.tcpclnt.Disconnect;
    Self.tcpsrvr.Active := False;
end;

procedure TDMTCPTransfer.SendFile(AFile : TTransferFile);
begin
    {TODO -oroger -cdsg : realiza a transferencia do arquivo para o servidor}
end;

procedure TDMTCPTransfer.SetupClient;
begin
    {TODO -oroger -cdsg : Ajusta o container para funcionar apenas como cliente(envio de arquivos apenas) }
end;

procedure TDMTCPTransfer.SetupServer;
begin
    {TODO -oroger -cdsg : Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas) }
    Self.tcpsrvr.TerminateWaitTime := 65000; //Tempo superior ao limite de novo ciclo de todos os clientes
    Self.tcpsrvr.DefaultPort := GlobalConfig.NetServicePort;
    Self.tcpsrvr.Active      := True;
    Self.tcpsrvr.StartListening;
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
        [sfilename, smodifiedDate, saccessDate, screateDate, sFileSize]));

    AContext.Connection.IOHandler.WriteLn('OK'); //informa OK e em seguida o tamanho do streamer lido
    {TODO -oroger -cdsg : Confirmar que a quantidade lida bate com a informada originalmente abaixo }
    AContext.Connection.IOHandler.WriteLn(sFileSize);

    //Finaliza a sessão
    AContext.Connection.Disconnect;

end;

{ TTransferFile }

procedure TTransferFile.SetFilename(const Value : string);
begin
    {TODO -oroger -cdsg : diferenciar a carga nomral do construtor para carregar pelo streamer os dados das datas do arquivo }
    Self.FFilename := Value;
    if not (csLoading in Self.ComponentState) then begin
        {TODO -oroger -cdsg : Carga dos atributos das datas do arquivos }
    end;
end;

end.
