{$IFDEF mtMainForm }
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, CheckLst, StrHnd, mtUtils;

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
				procedure FormCreate(Sender : TObject);
    procedure btnSetDefaulPasswordsClick(Sender: TObject);
    private
        { Private declarations }
        FUserList : TZEUserList;
    public
        { Public declarations }
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
    end;

var
    MigraToolsMainForm : TMigraToolsMainForm;

implementation

{$R *.dfm}

uses
    lmCons, APIHnd;

procedure TMigraToolsMainForm.btnSetDefaulPasswordsClick(Sender: TObject);
var
	log : string;
begin
{
	log:=Self.FUserList.SetLocalPasswords();
	if log <> EmptyStr then begin
		raise Exception.Create('Falhas no ajuste das senhas locais'#13 + log);
	end;
}
	if Self.FUserList.isDomain then begin
			log:=Self.FUserList.SetDomainPasswords();
			if log <> EmptyStr then begin
				raise Exception.Create('Falhas no ajuste das senhas locais'#13 + log);
			end;
	end;
end;

constructor TMigraToolsMainForm.Create(AOwner : TComponent);
begin
		inherited;
    Self.FUserList := TZEUserList.Create;
end;

destructor TMigraToolsMainForm.Destroy;
begin
    Self.FUserList.Free;
    inherited;
end;

procedure TMigraToolsMainForm.FormCreate(Sender : TObject);
var
		x : Integer;
begin
    //Desabilita a página de impressoras nesta versão
    Self.pgc1.Pages[1].Enabled := False;

    //carga da lista de usuários
		Self.chklstAccounts.Items.BeginUpdate;
		try
			Self.chklstAccounts.Sorted:=True;
				Self.chklstAccounts.Items.Clear;
				for x := 0 to Self.FUserList.Count - 1 do begin
						Self.chklstAccounts.Items.Add( Self.FUserList.Items[x].UserName );
				end;
				//Marca todos inicialmente
				for x := 0 to Self.chklstAccounts.Items.Count - 1 do begin
						Self.chklstAccounts.Checked[x] := True;
        end;
    finally
        Self.chklstAccounts.Items.EndUpdate;
    end;
end;

end.
