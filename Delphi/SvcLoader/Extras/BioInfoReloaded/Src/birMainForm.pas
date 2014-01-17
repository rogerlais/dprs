unit birMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Grids, DBGrids, birMainDM, ComCtrls, ActnList, PlatformDefaultStyleActnCtrls, ActnMan, ImgList, ToolWin, ActnCtrls;

type
  TForm1 = class(TForm)
    dbgrdMain: TDBGrid;
    statbar: TStatusBar;
    acttbMainForm: TActionToolBar;
    ilMain: TImageList;
    actmgrMain: TActionManager;
    actReadClipboard: TAction;
    actConfig: TAction;
    actLocate: TAction;
    procedure dbgrdMainTitleClick(Column: TColumn);
	 procedure FormShow(Sender: TObject);
  private
	 { Private declarations }
	 procedure CreateFilterControls();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.CreateFilterControls;
var
	x : Integer;
begin
	for x := 0 to Self.dbgrdMain.Columns.Count - 1 do begin


   end;
end;

procedure TForm1.dbgrdMainTitleClick(Column: TColumn);
begin
	{TODO -oroger -cdsg : Identificar coluna e ordenar por ela}
end;

procedure TForm1.FormShow(Sender: TObject);
begin
	Self.CreateFilterControls();
end;

end.
