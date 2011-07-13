{$IFDEF adumMainForm}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ADUserMgr.inc}


unit adumMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, adumMainDataModule, FileInfo, ToolWin, ActnMan, ActnCtrls, ComCtrls, PlatformDefaultStyleActnCtrls, ActnList, ImgList,
  StdActns;

type
    TfrmADUserMgr = class(TForm)
        statbarMain :    TStatusBar;
        acttbTopMain :   TActionToolBar;
        actmgrMainForm : TActionManager;
    ilMainForm: TImageList;
    actSave: TFileSaveAs;
        procedure FormCreate(Sender : TObject);
        procedure FormShow(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    frmADUserMgr : TfrmADUserMgr;

implementation

uses
    adumFrameStatusOperation;

{$R *.dfm}


procedure TfrmADUserMgr.FormCreate(Sender : TObject);
var
    fileInfo : TFileVersionInfo;
begin
    fileInfo := TFileVersionInfo.Create(nil);
    try
        fileInfo.FileName := ParamStr(0);
        {$IFDEF DEBUG}
        Self.Caption      := Self.Caption + '*** Depuração **** - ' + fileInfo.FileVersion;
        {$ELSE}
        Self.Caption      := Self.Caption + fileInfo.FileVersion;
        {$ENDIF}
    finally
        fileInfo.Free;
    end;
end;

procedure TfrmADUserMgr.FormShow(Sender : TObject);
begin
    AppControl.LoadAllData(Self);
    AppControl.ShowUserBrowser(Self);
    {TODO -oroger -cdsg : Carregar todos os dados dos bancos externos}
end;

end.
