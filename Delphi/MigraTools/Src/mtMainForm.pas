{$IFDEF mtMainForm }
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, CheckLst, StrHnd;

type
    TMigraToolsMainForm = class(TForm)
        statStatusBar :  TStatusBar;
        pnlBottomPanel : TPanel;
        pnlTopPanel :    TPanel;
        btnClose :       TBitBtn;
        pgc1 :           TPageControl;
        tsPasswords :    TTabSheet;
        tsPrinters :     TTabSheet;
        chklstAccounts : TCheckListBox;
        cbbAccountFilter : TComboBox;
        lblAccountFilter : TLabel;
        btnSetDefaulPasswords : TBitBtn;
        lblLocal :       TLabel;
        cbbLocalDomain : TComboBox;
        btnChepass :     TBitBtn;
        lblAccounts :    TLabel;
        btnSetScanner :  TBitBtn;
        procedure btnSetDefaulPasswordsClick(Sender : TObject);
        procedure FormCreate(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    MigraToolsMainForm : TMigraToolsMainForm;

implementation

{$R *.dfm}

uses
    lmCons, mtUtils, APIHnd;

procedure TMigraToolsMainForm.btnSetDefaulPasswordsClick(Sender : TObject);
var
    User : TZEUser;
    ret :  NET_API_STATUS;
begin
    User := TZEUser.Create('apolo');
    try
        ret := User.SetLocalPassword('esmeralda');
        TAPIHnd.CheckAPI(ret);
    finally
        User.Free;
    end;
end;

procedure TMigraToolsMainForm.FormCreate(Sender : TObject);
begin
    {$IFDEF DEBUG}
    Self.chklstAccounts.Checked[Self.chklstAccounts.Count - 1] := True;
    {$ENDIF}
end;

end.
