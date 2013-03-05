unit svclTCPTransfer;

interface

uses
  SysUtils, Classes, IdContext, IdTCPConnection, IdTCPClient, IdBaseComponent, IdComponent, IdCustomTCPServer, IdTCPServer;

type
  TDMTCPTransfer = class(TDataModule)
    tcpsrvr: TIdTCPServer;
    tcpclnt: TIdTCPClient;
  private
    { Private declarations }
  public
	 { Public declarations }
	 procedure SetupServer();
	 procedure SetupClient();
  end;

var
  DMTCPTransfer: TDMTCPTransfer;

implementation

uses
  svclConfig;

{$R *.dfm}

{ TDataModule1 }

procedure TDMTCPTransfer.SetupClient;
begin
	{TODO -oroger -cdsg : Ajusta o container para funcionar apenas como cliente(envio de arquivos apenas) }
end;

procedure TDMTCPTransfer.SetupServer;
begin
	{TODO -oroger -cdsg : Ajusta o container para funcionar apenas como servidor(recebimento de arquivos apenas) }
end;

end.
