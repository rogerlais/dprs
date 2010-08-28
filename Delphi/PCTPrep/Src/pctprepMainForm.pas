unit pctprepMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, AppLog;

type
  TForm1 = class(TForm)
    lblZone: TLabel;
    lblPctNumber: TLabel;
    lstZone: TListBox;
    lstPctNumber: TListBox;
    pnlComputerName: TPanel;
    pnlComputerIp: TPanel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    pnlButtons: TPanel;
    btnInserir: TBitBtn;
    pnltest: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnCancelClick(Sender: TObject);
begin
     Self.Close;
     AppLog.AppFatalError('Cancelado pelo usuário', 1 );
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
     Self.pnlComputerName.Caption:='Indefinido';
     Self.pnlComputerIp.Caption:='Indefinido';
end;

procedure TForm1.FormShow(Sender: TObject);
begin
     Self.pnlComputerName.Visible:=True;
     Self.pnlComputerIp.Visible:=True;
end;

end.
