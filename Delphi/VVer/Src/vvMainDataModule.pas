{$IFDEF vvMainDataModule}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvMainDataModule;

interface

uses
    SysUtils, Classes, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdHTTP, IdMessage,
	 IdExplicitTLSClientServerBase, vvsConsts,
	 IdMessageClient, IdSMTPBase, IdSMTP, IdMailBox, FileInfo, Forms;

type
    TdtmdMain = class(TDataModule)
        httpLoader :    TIdHTTP;
        smtpSender :    TIdSMTP;
        mailMsgNotify : TIdMessage;
        fvVersion :     TFileVersionInfo;
        procedure DataModuleCreate(Sender : TObject);
    private
        { Private declarations }
        procedure AddDestinations();
    public
        { Public declarations }
        procedure SendNotification();
    end;

var
    dtmdMain : TdtmdMain;

implementation

uses
	 FileHnd, vvConfig, StrHnd, IdEMailAddress, WinNetHnd, AppLog, vvMainForm, Str_Pas, TREUtils;

{$R *.dfm}

{ TdtmdMain }

procedure TdtmdMain.AddDestinations;
var
    dst : TIdEMailAddressItem;
    lst : TStringList;
    x :   Integer;
begin
    lst := TStringList.Create;
    try
        lst.Delimiter     := ',';
        lst.DelimitedText := GlobalInfo.NotificationList;
        for x := 0 to lst.Count - 1 do begin
            dst      := Self.mailMsgNotify.Recipients.Add();
            dst.Address := lst.Strings[x];
            dst.Name := 'SESOP - Verificador de Sistemas eleitorais';
        end;
    finally
        lst.Free;
    end;
end;

procedure TdtmdMain.DataModuleCreate(Sender : TObject);
var
    x : Integer;
    autoMode : boolean;
begin
	 autoMode := False;
	 for x := 0 to ParamCount do begin
		 if SameText(ParamStr(X), '/auto') then begin
			 autoMode := True;
			 Break;
		 end;
	 end;
	 if (autoMode) then begin
		Application.ShowMainForm := False;
		 //Envio da notificação
		 Self.SendNotification();
		 Application.Terminate;
	 end else begin
		Application.CreateForm(TForm1, Form1);
    end;
end;

procedure TdtmdMain.SendNotification;
const
	 //Modelo = VVer - Versão <1.0.2012.2> - <ZPB080STD01> - 201209242359 - Pendente';
	 SUBJECT_TEMPLATE = 'VVer - Versão: %s - %s - %s - %s';
begin
	mailMsgNotify.AttachmentEncoding := 'UUE';
	mailMsgNotify.Encoding := meDefault;
	mailMsgNotify.ConvertPreamble := True;
	mailMsgNotify.From.Address := GlobalInfo.SenderAddress;
	mailMsgNotify.From.Name := Application.Title; //'VVer - Verificador de sistemas 2012 - T1';
	mailMsgNotify.From.Text := Format( ' %s <%s>', [ Application.Title, GlobalInfo.SenderAddress ] ); // 'VVer - Verificador de sistemas 2012 - T1 <sesop@tre-pb.gov.br>';
	mailMsgNotify.From.Domain := Str_Pas.GetDelimitedSubStr( '@', GlobalInfo.SenderAddress, 1 );
	mailMsgNotify.From.User := Str_Pas.GetDelimitedSubStr( '@', GlobalInfo.SenderAddress, 0 );
	mailMsgNotify.Sender.Address := GlobalInfo.SenderAddress;
	mailMsgNotify.Sender.Name := GlobalInfo.SenderDescription;
	mailMsgNotify.Sender.Text := Format( '"%s" <%s>', [ GlobalInfo.SenderDescription, GlobalInfo.SenderAddress ] );
	mailMsgNotify.Sender.Domain := mailMsgNotify.From.Domain;
	mailMsgNotify.Sender.User := mailMsgNotify.From.User;

 {
  object mailMsgNotify: TIdMessage
	 FromList = <
	   item
		 Address = 'sesop@tre-pb.gov.br'
		 Name = 'VVer - Verificador de sistemas 2012 - T1'
		 Text = 'VVer - Verificador de sistemas 2012 - T1 <sesop@tre-pb.gov.br>'
		 Domain = 'tre-pb.gov.br'
		 User = 'sesop'
	   end>

	 ReplyTo = <
	   item
		 Address = 'sesop@tre-pb.gov.br'
		 Name = 'SESOP'
		 Text = 'SESOP <sesop@tre-pb.gov.br>'
		 Domain = 'tre-pb.gov.br'
		 User = 'sesop'
	   end>
}


	 //Coletar informações de destino de mensagem com possibilidade de macros no mesmo arquivo de configuração
    Self.AddDestinations();
    Self.mailMsgNotify.Subject   := Format(SUBJECT_TEMPLATE, [Self.fvVersion.FileVersion, WinNetHnd.GetComputerName(),
        FormatDateTime('yyyyMMDDhhmm', Now()), GlobalInfo.GlobalStatus]);
    Self.mailMsgNotify.Body.Text := GlobalInfo.InfoText;
    Self.smtpSender.Connect;
    Self.smtpSender.Send(Self.mailMsgNotify);
    Self.smtpSender.Disconnect(True);
end;

end.
