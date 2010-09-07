{$IFDEF pctprepMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I PCTPrep.inc}

unit pctprepMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, pctprepUtils, AppLog, FileInfo, FileHnd, ComCtrls;

type
    TMainForm = class(TForm)
        lblZone :         TLabel;
        lblPctNumber :    TLabel;
        lstZone :         TListBox;
        lstPctNumber :    TListBox;
        pnlComputerName : TPanel;
        pnlComputerIp :   TPanel;
        btnOk :           TBitBtn;
        btnCancel :       TBitBtn;
        pnlButtons :      TPanel;
        btnInserir :      TBitBtn;
        btnClose :        TBitBtn;
        btnTest :         TBitBtn;
        fvVersion :       TFileVersionInfo;
        statBar :         TStatusBar;
        procedure FormCreate(Sender : TObject);
        procedure FormShow(Sender : TObject);
        procedure btnCancelClick(Sender : TObject);
        procedure btnCloseClick(Sender : TObject);
        procedure btnTestClick(Sender : TObject);
        procedure lstZoneClick(Sender : TObject);
        procedure lstPctNumberClick(Sender : TObject);
        procedure btnOkClick(Sender : TObject);
    private
        { Private declarations }
        loader : TTREPCTZoneList;
    public
        { Public declarations }
        destructor Destroy; override;
    end;

var
    MainForm : TMainForm;

implementation

{$R *.dfm}

uses
	 APIHnd, LmCons, LmErr, WinNetHnd, IdStackWindows;

procedure TMainForm.btnCancelClick(Sender : TObject);
begin
    Self.Close;
    AppLog.AppFatalError('Cancelado pelo usuário', 1);
end;

procedure TMainForm.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TMainForm.btnOkClick(Sender : TObject);
var
    ActivePct : TTREPct;
begin
    if Self.lstPctNumber.ItemIndex >= 0 then begin
        //Desabilita controles de alteração de estado
        TControl(Sender).Enabled := False;
        lstZone.Enabled := False;
        lstPctNumber.Enabled := False;
        //Identifica e altera de acordo com o PCT selecionado
        ActivePct := TTREPct(Self.lstPctNumber.Items.Objects[Self.lstPctNumber.ItemIndex]);
        ActivePct.Prepare;
        //Informa do sucesso
        MessageDlg('Operação concluída com sucesso!', mtInformation, [mbOK], 0);
        Self.Close;
    end;
end;

procedure TMainForm.btnTestClick(Sender : TObject);
{
var
	 ret : NET_API_STATUS;
}
begin
    {TODO -oroger -cdsg : Realizar os testes pontuais}
    //Renomear computador
     {
     ret := RenameComputer('teste-pct', 'teste-pct descrição');
     TAPIHnd.CheckAPI(ret);
     TAPIHnd.CheckAPI(5);
     }
    //Alteração de IP
    {
     ret:=SetIpConfig('10.12.3.240', '10.12.1.21', '255.255.255.0');
     TAPIHnd.CheckAPI(ret);
     }
    //Carga dos parametros de configuração
end;

destructor TMainForm.Destroy;
begin
	 Self.loader.Free;
	 inherited;
end;

procedure TMainForm.FormCreate(Sender : TObject);
var
	 IPGetter : TIdStackWindows;
begin
	  {$IFDEF DEBUG}
	 Self.btnClose.Visible := True;
	 Self.btnTest.Visible := True;
	 Self.Caption := 'Preparação de PCT - *** Depuração *** - ' + Self.fvVersion.FileVersion;
	 {$ELSE}
	 Self.btnClose.Visible := False;
	 Self.btnTest.Visible := False;
	 Self.Caption := 'Preparação de PCT - Versão: ' + Self.fvVersion.FileVersion;
	 Self.btnClose.Visible := False;
	 Self.btnTest.Visible := False;
	  {$ENDIF}
	  IPGetter := TIdStackWindows.Create;
	 try
		 Self.statBar.Panels[0].Text := 'Nome= ' + WinNetHnd.GetComputerName() + ' IP=' + IPGetter.LocalAddress;
	 finally
		 IPGetter.Free;
	 end;
	 Self.pnlComputerName.Caption := '';
	 Self.pnlComputerIp.Caption := '';
	 Self.btnOk.Enabled := False;
end;

procedure TMainForm.FormShow(Sender : TObject);
var
    fname : string;
begin
    Self.pnlComputerName.Visible := True;
    Self.pnlComputerIp.Visible   := True;

    //carga da lista de pcts
	  {$IFDEF DEBUG}
	  {$IFDEF REMOTE}
	  fname  := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'PCTs2010.csv']);
	  {$ELSE}
	  fname  := '..\Data\PCTs2010.csv';
	  {$ENDIF}
	  {$ELSE}
	 fname  := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'PCTs2010.csv']);
     {$ENDIF}
    loader := TTREPCTZoneList.Create;
    loader.LoadFromCSV(ExpandFileName(fname));
    Self.lstZone.Items.Assign(loader);
end;

procedure TMainForm.lstPctNumberClick(Sender : TObject);
var
    pct : TTREPct;
begin
    if Self.lstPctNumber.ItemIndex >= 0 then begin
        pct := TTREPct(Self.lstPctNumber.Items.Objects[Self.lstPctNumber.ItemIndex]);
    end else begin
        pct := nil;
    end;
    Self.btnOk.Enabled := Assigned(pct);
    if Assigned(pct) then begin
        Self.pnlComputerName.Caption := pct.Computername;
        Self.pnlComputerIp.Caption   := pct.Ip;
    end else begin
        Self.pnlComputerName.Caption := '';
        Self.pnlComputerIp.Caption   := '';
    end;
end;

procedure TMainForm.lstZoneClick(Sender : TObject);
var
    pctList : TTREPctZone;
begin
    if Self.lstZone.ItemIndex >= 0 then begin
        pctList := TTREPctZone(Self.lstZone.Items.Objects[Self.lstZone.ItemIndex]);
        Self.lstPctNumber.Items.Assign(pctList);
    end else begin
        Self.lstPctNumber.Clear;
    end;
end;

end.
