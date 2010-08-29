unit pctprepMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, AppLog;

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
        procedure FormCreate(Sender : TObject);
        procedure FormShow(Sender : TObject);
        procedure btnCancelClick(Sender : TObject);
        procedure btnCloseClick(Sender : TObject);
        procedure btnTestClick(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    MainForm : TMainForm;

implementation

{$R *.dfm}

uses
    pctprepUtils, APIHnd, LmCons, LmErr;

procedure TMainForm.btnCancelClick(Sender : TObject);
begin
    Self.Close;
    AppLog.AppFatalError('Cancelado pelo usuário', 1);
end;

procedure TMainForm.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TMainForm.btnTestClick(Sender : TObject);
var
	 ret :    NET_API_STATUS;
begin
	 {TODO -oroger -cdsg : Realizar os testes pontuais}
	 {
	 ret := RenameComputer('teste-pct', 'teste-pct descrição');
	 TAPIHnd.CheckAPI(ret);
	 TAPIHnd.CheckAPI(5);
	 }
	 ret:=SetIpConfig('10.12.3.240', '10.12.1.21', '255.255.255.0');
	 TAPIHnd.CheckAPI(ret);
end;

procedure TMainForm.FormCreate(Sender : TObject);
begin
   {$IFDEF DEBUG}
    Self.btnClose.Visible := True;
    Self.btnTest.Visible  := True;
   {$ELSE}
    Self.btnClose.Visible := False;
    Self.btnTest.Visible  := False;
   {$ENDIF}
    Self.pnlComputerName.Caption := 'Indefinido';
    Self.pnlComputerIp.Caption := 'Indefinido';
end;

procedure TMainForm.FormShow(Sender : TObject);
begin
    Self.pnlComputerName.Visible := True;
    Self.pnlComputerIp.Visible   := True;
end;

end.
