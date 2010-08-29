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
    procedure btnTestClick(Sender: TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    MainForm : TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.btnCancelClick(Sender : TObject);
begin
    Self.Close;
    AppLog.AppFatalError('Cancelado pelo usuário', 1);
end;

procedure TMainForm.btnCloseClick(Sender : TObject);
begin
    Self.Close;
end;

procedure TMainForm.btnTestClick(Sender: TObject);
begin
   {TODO -oroger -cdsg : Realizar os testes pontuais}
end;

procedure TMainForm.FormCreate(Sender : TObject);
begin
   {$IFDEF DEBUG}
    Self.btnClose.Visible := True;
    Self.btnTest.Visible  := True;
   {$ELSE}
   Self.btnClose.Visible:=False;
   Self.btnTest.Visible:=False;
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
