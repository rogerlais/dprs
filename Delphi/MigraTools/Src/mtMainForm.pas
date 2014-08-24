{$IFDEF mtMainForm }
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, ComCtrls, CheckLst, StrHnd, mtUtils, FileInfo,
    JvComponentBase, JvCreateProcess, XMLDoc, XMLIntf;

type
    TMigraToolsMainForm = class(TForm)
        statStatusBar :  TStatusBar;
        pnlBottomPanel : TPanel;
        pnlTopPanel :    TPanel;
        btnClose :       TBitBtn;
        fileVerMain :    TFileVersionInfo;
        ProcessControl : TJvCreateProcess;
        pgc1 :           TPageControl;
        tsPasswords :    TTabSheet;
        lblAccountFilter : TLabel;
        lblLocal :       TLabel;
        lblAccounts :    TLabel;
        chklstAccounts : TCheckListBox;
        cbbAccountFilter : TComboBox;
        btnSetDefaulPasswords : TBitBtn;
        cbbLocalDomain : TComboBox;
        btnChepass :     TBitBtn;
        ledtNewAccount : TLabeledEdit;
        ledtNewPass :    TLabeledEdit;
        btnAddNewUser :  TBitBtn;
        btnTestXML :     TBitBtn;
        procedure FormCreate(Sender : TObject);
        procedure btnSetDefaulPasswordsClick(Sender : TObject);
        procedure chklstAccountsClickCheck(Sender : TObject);
        procedure btnAddNewUserClick(Sender : TObject);
        procedure ProcessControlTerminate(Sender : TObject; ExitCode : cardinal);
        procedure btnTestXMLClick(Sender : TObject);
    private
        { Private declarations }
        FUserList : TZEUserList;
        FAutoMode : boolean;
    public
        { Public declarations }
        constructor Create(AOwner : TComponent); override;
        destructor Destroy; override;
        procedure SaveGlobalLog();
    end;

var
    MigraToolsMainForm : TMigraToolsMainForm;

implementation

{$R *.dfm}

uses
    lmCons, APIHnd, FileHnd, ShellAPI, mtConfig;


function ImpersonateADMUser() : Integer;
    //----------------------------------------------------------------------------------------------------------------------------------
var
    TKHandle :   THandle;
    User, Pass : PChar;
begin
	 User   := PChar('admroger');
	 Pass   := PChar('EUEUEUEUEU');
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
    if (Self.ledtNewAccount.Text <> EmptyStr) then begin
        if Self.ledtNewPass.Text <> EmptyStr then begin
            if Self.FUserList.Find(Self.ledtNewAccount.Text) <> nil then begin
                raise Exception.CreateFmt('Conta "%s" já existe', [Self.ledtNewAccount.Text]);
            end;
            newUser := TZEUser.Create(Self.ledtNewAccount.Text, Self.ledtNewPass.Text);
            newUser.Checked := True;    //Atenção para todos os casos de inserção/alteração
            Self.FUserList.Add(newUser);
            index := Self.chklstAccounts.Items.AddObject(newUser.UserName, newUser);
            Self.chklstAccounts.Checked[index] := newUser.Checked;
        end else begin
            raise Exception.Create('Senha requerida');
        end;
    end else begin
        raise Exception.Create('Nome de usuário inválido');
    end;
end;

procedure TMigraToolsMainForm.btnSetDefaulPasswordsClick(Sender : TObject);
var
    log : string;
begin
    TControl(Sender).Enabled := False;
    try
        {$IFDEF DEBUG}
        TAPIHnd.CheckAPI(ImpersonateADMUser());
        {$ENDIF}
        log := Self.FUserList.SetPasswords();
        if log <> EmptyStr then begin
            raise Exception.Create('Ocorreram falhas no ajuste das senhas:'#13 + log);
        end;
    finally
		 TControl(Sender).Enabled := True;
		 Self.SaveGlobalLog;
    end;
end;

procedure TMigraToolsMainForm.btnTestXMLClick(Sender : TObject);
var
    Root : IXMLNode;
    Doc :  TXMLDocument;
begin
    Doc := TXMLDocument.Create(self);
    doc.LoadFromFile('.\TestConfigOut.xml');
    Doc.Options := Doc.Options + [doAutoSave, doNodeAutoIndent];
    Root := Doc.DocumentElement;
    GlobalConfig.CentralMapping.LoadHardCoded;
    GlobalConfig.SaveTo(Root);
end;

procedure TMigraToolsMainForm.chklstAccountsClickCheck(Sender : TObject);
var
    cb : TCheckListBox;
begin
    cb := TCheckListBox(Sender);
    TZEUser(cb.Items.Objects[cb.ItemIndex]).Checked := cb.Checked[cb.ItemIndex];
end;

constructor TMigraToolsMainForm.Create(AOwner : TComponent);
var
    x :   Integer;
    log : string;
begin
    inherited;
    Self.FAutoMode := False;
    Self.FUserList := TZEUserList.Create;

    try
        //Testa execução automatica para todas as contas carregadas
        for x := 0 to ParamCount do begin
            if SameText(ParamStr(x), '/auto') then begin
                //oculta janela
                Self.Visible := False;
                Application.ShowMainForm := False;

                //Executa operação
                Self.FAutoMode := True;
                log := Self.FUserList.SetPasswords();
                if log <> EmptyStr then begin
                    raise Exception.Create('Ocorreram falhas no ajuste das senhas:'#13 + log);
                end;
            end;
        end;
    finally
        Self.SaveGlobalLog;
    end;
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
	 {$IFDEF DEBUG}
	 Self.Caption := 'Ferramentas de Migração - ***Versão Depuração***' + Self.fileVerMain.FileVersion;
	 {$ELSE}
	 Self.Caption := 'Ferramentas de Migração - ' + Self.fileVerMain.FileVersion;
	 {$ENDIF}
end;

procedure TMigraToolsMainForm.ProcessControlTerminate(Sender : TObject; ExitCode : cardinal);
begin
    if Self.FAutoMode then begin
        Application.Terminate;
    end;
end;

procedure TMigraToolsMainForm.SaveGlobalLog;
var
    fName : string;
begin
    fName := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'AltSenha.txt']);
    if (Pos('=', GlobalSaveLog.Text) <> 0) then begin
        GlobalSaveLog.SaveToFile(fName);
        Self.ProcessControl.CommandLine := 'c:\Windows\notepad.exe ' + '"' + fName + '"';
        //ShellExecute( 0, 'open', PWideChar(fName), nil, nil, SW_SHOWNORMAL );
        Self.ProcessControl.Run;
    end;
end;

end.
