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
        btnRegister :      TBitBtn;
        btnServiceLogon :  TBitBtn;
    btnGetDomain: TBitBtn;
        procedure btnStartClick(Sender : TObject);
        procedure btnCloseClick(Sender : TObject);
        procedure tmrServiceThreadTimer(Sender : TObject);
        procedure btnRegisterClick(Sender : TObject);
        procedure btnServiceLogonClick(Sender : TObject);
    procedure btnGetDomainClick(Sender: TObject);
    private
		 { Private declarations }
		 function GetDomainNameEx( const Name : string ) : string;
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
	 svclBiometricFiles, svclConfig, JwaWindows, svclUtils, WNetExHnd, WinNetHnd;

{$R *.dfm}

procedure TForm1.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TForm1.btnGetDomainClick(Sender: TObject);
var
	ret : string;
begin
   --- usar GetDomainNameEx desta classe
	ret:=WinNetHnd.GetComputerName();
	InputQuery('Nome da estação', 'Estação:', ret );
	ret := WNetExHnd.GetWorkstationDomain( ret );
	MessageDlg(ret,  mtInformation, [mbOK], 0);
end;

procedure TForm1.btnRegisterClick(Sender : TObject);
begin
    MessageDlg(Format('conta = %s, senha=%s', [GlobalConfig.ServiceAccountName, GlobalConfig.ServiceAccountPassword]),
        mtInformation, [mbOK], 0);
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
    Started : boolean;
begin
    Started := False;
    BioFilesService.ServiceStart(BioFilesService, Started);
    Self.tmrServiceThread.Enabled := True;
end;

function TForm1.GetDomainNameEx(const Name: string): string;
var
  Count1, Count2: DWORD;
  Sd: PSID; // PSecurityDescriptor; // FPC requires PSID
  Snu: SID_Name_Use;
begin
  Count1 := 0;
  Count2 := 0;
  Sd := nil;
  Snu := SIDTypeUser;
  Result := '';
  LookUpAccountName(nil, PChar(Name), Sd, Count1, PChar(Result), Count2, Snu);
  // set buffer size to Count2 + 2 characters for safety
  SetLength(Result, Count2 + 1);
  Sd := AllocMem(Count1);
  try
	 if LookUpAccountName(nil, PChar(Name), Sd, Count1, PChar(Result), Count2, Snu) then
	   StrResetLength(Result) --Altera comprimento para o valor efetivo da cadeia??? dispensavel???
	 else
	   Result := EmptyStr;
  finally
	 FreeMem(Sd);
  end;
end;

procedure TForm1.tmrServiceThreadTimer(Sender : TObject);
begin
    BioFilesService.TimeCycleEvent();
end;

end.
