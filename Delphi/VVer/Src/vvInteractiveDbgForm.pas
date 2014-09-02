{$IFDEF vvInteractiveDbgForm}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvInteractiveDbgForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, SvcMgr, vvSvcDM;

type
  TForm2 = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    btnStartClient: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStartClientClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

uses
  vvsConfig;

{$R *.dfm}

procedure TForm2.btnStartClick(Sender: TObject);
var
	 ret : boolean;
begin
	 ret := False;
	 VVerService.ServiceStart( VVerService, ret);
end;

procedure TForm2.btnStartClientClick(Sender: TObject);
var
	 ret : boolean;
begin
	if ( VVerService.Status <> csRunning ) then begin
		VVerService.ServiceContinue( VVerService, ret);
	end else begin
		VVerService.ServicePause( VVerService, ret);
	end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
	Self.Caption := Self.Caption + Format( ' - Instância( %s )', [ VVSvcConfig.InstanceName ] );
end;

end.
