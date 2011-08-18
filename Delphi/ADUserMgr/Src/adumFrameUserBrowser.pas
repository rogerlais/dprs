{$IFDEF adumFrameUserBrowser}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ADUserMgr.inc}


unit adumFrameUserBrowser;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, DB, DBClient, SimpleDS, Grids, DBGrids, adumMainDataModule, StdCtrls, ExtCtrls, ComCtrls, ToolWin, ActnMan, ActnCtrls;

type
    TFrmUserBrowser = class(TFrame)
        dsUserFull :   TDataSource;
        pgcDetails :   TPageControl;
        tsAD :         TTabSheet;
        tsTitular :    TTabSheet;
        tsRequisit :   TTabSheet;
        tsEstag :      TTabSheet;
        pnlLeft :      TPanel;
        splSplitter :  TSplitter;
        dbgrdUserBrowser : TDBGrid;
        pnlBrowseFilters : TPanel;
        chkTitular :   TCheckBox;
        chkRequisit :  TCheckBox;
        chkEstag :     TCheckBox;
        chkTodos :     TCheckBox;
        edtLogin :     TLabeledEdit;
        edtFullName :  TLabeledEdit;
        edtRuledName : TLabeledEdit;
        procedure dsUserFullDataChange(Sender : TObject; Field : TField);
    private
        { Private declarations }
    public
        { Public declarations }
        procedure LoadData;

    end;

implementation

{$R *.dfm}


{ TFrmUserBrowser }

procedure TFrmUserBrowser.dsUserFullDataChange(Sender : TObject; Field : TField);
begin
    {TODO -oroger -cdsg : Recarregar os valores relativos a mudanca de registro}

end;

procedure TFrmUserBrowser.LoadData;
begin
    //Self.dsUserFull.DataSet:=adumMainDataModule.DtMdMainADUserMgr.dsExtUserTable;
    //Self.dsUserFull.DataSet.Active:=True;
end;

end.
