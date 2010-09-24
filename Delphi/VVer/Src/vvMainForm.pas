{$IFDEF vvMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}

unit vvMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, EnhGrids, Buttons, vvConfig;

type
  TForm1 = class(TForm)
    btnOK: TBitBtn;
    grdList: TEnhStringGrid;
    lblMainLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { Private declarations }
  public
	 { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

const
	COL_DESC = 0;
	COL_VER = 1;
	COL_EXPEC = 2;

procedure TForm1.btnOKClick(Sender: TObject);
begin
	Self.Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
	x: Integer;
	p : TProgItem;
begin
	Self.grdList.RowCount:=GlobalInfo.ProgCount + 1;
	Self.grdList.ColCount:=3;
	Self.grdList.FixedRows:=1;
	Self.grdList.Cells[COL_DESC, 0]:='Descrição';
	Self.grdList.Cells[COL_VER, 0]:='Versão Instalada';
	Self.grdList.Cells[COL_EXPEC, 0]:='Versão Esperada';
	for x := 1 to GlobalInfo.ProgCount do begin
		p:=GlobalInfo.Items[x-1];
		//Atribuição da exibição
		Self.grdList.Cells[COL_DESC, x]:=p.Desc;
		Self.grdList.Cells[COL_VER, x]:=p.CurrentVersion;
		Self.grdList.Cells[COL_EXPEC, x]:=p.ExpectedVerEx;
		//Atibuição dos objetos
		Self.grdList.Objects[COL_DESC, x]:=p;
		Self.grdList.Objects[COL_VER, x]:=p;
		Self.grdList.Objects[COL_EXPEC, x]:=p;
	end;
end;

end.
