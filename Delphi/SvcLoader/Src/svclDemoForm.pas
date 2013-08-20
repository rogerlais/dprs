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
        btnStart :         TBitBtn;
        btnPause :         TBitBtn;
        btnStop :          TBitBtn;
        btnClose :         TBitBtn;
        tmrServiceThread : TTimer;
        btnEditConfig :    TBitBtn;
        procedure btnStartClick(Sender : TObject);
        procedure btnCloseClick(Sender : TObject);
        procedure tmrServiceThreadTimer(Sender : TObject);
        procedure btnServiceLogonClick(Sender : TObject);
        procedure btnEditConfigClick(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    svclBiometricFiles, svclConfig, JwaWindows, svclUtils, WinNetHnd, StrHnd, WNetExHnd, svclEditConfigForm;

{$R *.dfm}

procedure TForm1.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TForm1.btnEditConfigClick(Sender : TObject);
begin
    TEditConfigForm.EditConfig();
end;

procedure TForm1.btnServiceLogonClick(Sender : TObject);
var
    lStatus : DWORD;
begin
    //lStatus := AddPrivilegeToAccount('Administrators'{or any account/group name}, 'SeServiceLogonRight');
    lStatus := AddPrivilegeToAccount('TRE-PB\Roger'{or any account/group name}, SE_SERVICE_LOGON_NAME);
    if lStatus = ERROR_SUCCESS then begin
        Caption := 'OK';
    end else begin
        Caption := SysErrorMessage(lStatus);
    end;
end;

procedure TForm1.btnStartClick(Sender : TObject);
var
    ret : boolean;
begin
    ret := False;
    BioFilesService.ServiceStart(BioFilesService, ret);
    Self.tmrServiceThread.Enabled := True;
end;

procedure TForm1.tmrServiceThreadTimer(Sender : TObject);
begin
    BioFilesService.TimeCycleEvent();
end;

end.
