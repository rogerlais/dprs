{$IFDEF svclDemoForm}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclDemoForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type
  TForm1 = class(TForm)
    btnStart: TBitBtn;
    btnPause: TBitBtn;
    btnStop: TBitBtn;
    btnClose: TBitBtn;
    tmrServiceThread: TTimer;
    btnRegister: TBitBtn;
    procedure btnStartClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tmrServiceThreadTimer(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  svclBiometricFiles, svclConfig;

{$R *.dfm}

procedure TForm1.btnCloseClick(Sender: TObject);
begin
	Self.Close;
end;

procedure TForm1.btnRegisterClick(Sender: TObject);
begin
	MessageDlg(Format( 'conta = %s, senha=%s', [ GlobalConfig.ServiceAccountName, GlobalConfig.ServiceAccountPassword ]),  mtInformation, [mbOK], 0);
end;

procedure TForm1.btnStartClick(Sender: TObject);
var
	Started : Boolean;
begin
   Started := False;
	BioFilesService.ServiceStart( BioFilesService, Started );
	Self.tmrServiceThread.Enabled:=True;
end;

procedure TForm1.tmrServiceThreadTimer(Sender: TObject);
begin
	BioFilesService.TimeCycleEvent();
end;

end.
