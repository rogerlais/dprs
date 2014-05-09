{$IFDEF birMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I bir.inc}

unit birMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, Grids, DBGrids, birMainDM, ComCtrls, ActnList, PlatformDefaultStyleActnCtrls, ActnMan, ImgList, ToolWin, ActnCtrls,
    JvBaseDlg, JvSelectDirectory;

type
    TForm1 = class(TForm)
        dbgrdMain :        TDBGrid;
        statbar :          TStatusBar;
        acttbMainForm :    TActionToolBar;
        ilMain :           TImageList;
        actmgrMain :       TActionManager;
        actReadClipboard : TAction;
        actConfig :        TAction;
        actLocate :        TAction;
        actExportBioFiles : TAction;
        sldirOutPath :     TJvSelectDirectory;
        procedure dbgrdMainTitleClick(Column : TColumn);
        procedure FormShow(Sender : TObject);
        procedure actReadClipboardExecute(Sender : TObject);
        procedure actLocateExecute(Sender : TObject);
        procedure actExportBioFilesExecute(Sender : TObject);
        procedure dbgrdMainKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
    private
        { Private declarations }
        procedure CreateFilterControls();
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    CtrlsHnd, FileHnd, StreamHnd;

{$R *.dfm}

procedure TForm1.actExportBioFilesExecute(Sender : TObject);
var
    ret, x : Integer;
    outDir, srcName, destName : string;
begin
    {TODO -oroger -cdsg : varrer a tabela e salvar os arquivos selecionados}
    //Self.sldirOutPath.InitialDir:=GetCurrentDir();
    if (Self.sldirOutPath.Execute(Self.Handle)) then begin
        outDir := Self.sldirOutPath.Directory;
        for x := 0 to Self.dbgrdMain.SelectedRows.Count - 1 do begin
            Self.dbgrdMain.DataSource.DataSet.GotoBookmark(Self.dbgrdMain.SelectedRows.Items[x]);
            srcName  := Self.dbgrdMain.Columns.Items[0].Field.AsString;
            destName := TFileHnd.ConcatPath([outDir, ExtractFileName(srcName)]);
            if (FileExists(destName)) then begin
                if (THashHnd.CompareFiles(srcName, destName) <> []) then begin
                    MessageDlg('Arquivos: ' + srcName + ' diverge do arquivo ' + destName, mtInformation, [mbOK], 0);
                end;
            end else begin
                if (not Windows.CopyFile(PWideChar(srcName), PWideChar(destName), False)) then begin
                    MessageDlg(Format('Falha copiando %s '#13#10'%s', [srcName, SysErrorMessage(GetLastError())]), mtError, [mbOK], 0);
                end;
            end;
        end;
    end;
end;

procedure TForm1.actLocateExecute(Sender : TObject);
begin
    if MessageDlg('Processo STA Copie todo o conteúdo do relatórios de pend^ncias para a área de transferência e pression OK',
        mtConfirmation, mbOKCancel, 0) = mrOk then begin
        MainDM.ztblBioFiles.Open;
        MainDM.SearchFromClipBoard();
    end;
end;

procedure TForm1.actReadClipboardExecute(Sender : TObject);
begin
    MainDM.ImportFromClipBoard();
end;

procedure TForm1.CreateFilterControls;
var
    x : Integer;
begin
    for x := 0 to Self.dbgrdMain.Columns.Count - 1 do begin

    end;
end;

procedure TForm1.dbgrdMainKeyUp(Sender : TObject; var Key : Word; Shift : TShiftState);
begin
    {TODO -oroger -cdsg : adcionar a condição de ctrl + a}
    if ((Uppercase(char(Key)) = 'A') and (ssCtrl in Shift)) then begin
        Self.dbgrdMain.SelectedRows.Clear;
        with Self.dbgrdMain.DataSource.DataSet do begin
            DisableControls;
            First;
            try
                while not EOF do begin
                    Self.dbgrdMain.SelectedRows.CurrentRowSelected := True;
                    Next;
                end;
            finally
                EnableControls;
            end;
        end;
    end;
end;

procedure TForm1.dbgrdMainTitleClick(Column : TColumn);
begin
    {TODO -oroger -cdsg : Identificar coluna e ordenar por ela}
end;

procedure TForm1.FormShow(Sender : TObject);
begin
    Self.CreateFilterControls();
end;

end.
