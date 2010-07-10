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
        edtNewAccount :  TLabeledEdit;
        edtNewPass :     TLabeledEdit;
        btnAddNewUser :  TBitBtn;
        procedure FormCreate(Sender : TObject);
        procedure btnSetDefaulPasswordsClick(Sender : TObject);
        procedure chklstAccountsClickCheck(Sender : TObject);
        procedure btnAddNewUserClick(Sender : TObject);
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


function ImpersonateADMUser() : Integer;
    //----------------------------------------------------------------------------------------------------------------------------------
var
    TKHandle :   THandle;
    User, Pass : PChar;
begin
    User   := PChar('admdanusio');
    Pass   := PChar('ventilador');
    Result := ERROR_SUCCESS;
    SetLastError(Result);
    if LogonUser(User, nil, Pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, TKHandle) then begin
        if not ImpersonateLoggedOnUser(TKHandle) then begin
            Result := GetLastError();
        end;
    end else begin
        Result := GetLastError();
    end;
end;


procedure TMigraToolsMainForm.btnAddNewUserClick(Sender : TObject);
var
    newUser : TZEUser;
    index :   Integer;
begin
    {TODO -oroger -cfuture : filtro deve impedir duplicidade de conta}
    if (Self.edtNewAccount.Text <> EmptyStr) then begin
        if Self.edtNewPass.Text <> EmptyStr then begin
            newUser := TZEUser.Create(Self.edtNewAccount.Text, Self.edtNewPass.Text);
            newUser.Checked := True;
            Self.FUserList.Add(newUser);
            index := Self.chklstAccounts.Items.AddObject(newUser.UserName, newUser);
            Self.chklstAccounts.Checked[index] := newUser.Checked;
        end else begin
            raise Exception.Create('Senha requerida');
        end;
    end else begin
        raise Exception.Create('Nome de conta inválido');
    end;
end;

procedure TMigraToolsMainForm.btnSetDefaulPasswordsClick(Sender : TObject);
var
    log : string;
begin
    {$IFDEF DEBUG}
		TAPIHnd.CheckAPI( ImpersonateADMUser() );
		{$ENDIF}
    log := Self.FUserList.SetPasswords();
    if log <> EmptyStr then begin
        raise Exception.Create('Ocorreram falhas no ajuste das senhas:'#13 + log);
    end;
end;

procedure TMigraToolsMainForm.chklstAccountsClickCheck(Sender : TObject);
var
    cb : TCheckListBox;
begin
    cb := TCheckListBox(Sender);
    TZEUser(cb.Items.Objects[cb.ItemIndex]).Checked := cb.Checked[cb.ItemIndex];
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
        Self.chklstAccounts.Sorted := True;
        Self.chklstAccounts.Items.Clear;
        for x := 0 to Self.FUserList.Count - 1 do begin
            Self.chklstAccounts.Items.AddObject(Self.FUserList.Items[x].UserName, Self.FUserList.Items[x]);

        end;
        //Marca todos inicialmente
        for x := 0 to Self.chklstAccounts.Items.Count - 1 do begin
            Self.chklstAccounts.Checked[x] := Self.FUserList.Items[x].Checked;
        end;
    finally
        Self.chklstAccounts.Items.EndUpdate;
    end;
end;

end.
