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
    Action1: TAction;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

end.
