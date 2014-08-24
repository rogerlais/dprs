unit sqdbcMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, FileCtrl, Mask, JvExMask, JvToolEdit, HKStreamCol, JvExStdCtrls, JvRichEdit,
    JvComponentBase, JvRichEditToHtml, RpDefine, RpRender, RpRenderHTML, RpSystem, RpBase, RpFiler, RpRave;

type
    TForm1 = class(TForm)
        edtSourceDir :   TJvDirectoryEdit;
        edtDestDir :     TJvDirectoryEdit;
        fllstSource :    TFileListBox;
        pnlBottom :      TPanel;
        btnConvert :     TBitBtn;
        hkstrms :        THKStreams;
        jvrchdthtml :    TJvRichEditToHtml;
        edtRTF :         TJvRichEdit;
        rvrndrhtml :     TRvRenderHTML;
        rvsystm :        TRvSystem;
        rvprjct :        TRvProject;
        btnGenerateRTF : TBitBtn;
        procedure FormCreate(Sender : TObject);
        procedure edtSourceDirChange(Sender : TObject);
        procedure fllstSourceChange(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
        procedure btnConvertClick(Sender : TObject);
        procedure rvrndrhtmlDecodeImage(Sender : TObject; ImageStream : TStream; ImageType : string; Bitmap : TBitmap);
        procedure btnGenerateRTFClick(Sender : TObject);
    private
        { Private declarations }
        procedure LoadRTFFile(const Filename : string);
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

uses
    sqdbcConfig, FileHnd, RpCon, RpConDS, RpDevice, RvClass, RvCsData, RvCsDraw, RvCsStd, RvCsRpt,
    RvData, RvDefine, RvDirectDataView, RvUtil, XPFileEnumerator;

{$R *.dfm}



procedure TForm1.btnConvertClick(Sender : TObject);
var
    page : TRavePage;
begin
     {
     Self.jvrchdthtml.ConvertToHtml(Self.edtRTF, TFileHnd.ConcatPath([Self.edtDestDir.Directory,
         ExtractFileName(Self.fllstSource.FileName)]));

      }

    //Tentativa via Rave Reports prar html
    //Ajuste do render html

    Self.rvsystm.DefaultDest    := rdFile;
    Self.rvsystm.DoNativeOutput := False;
    Self.rvsystm.RenderObject   := Self.rvrndrhtml;
    Self.rvsystm.OutputFileName := 'RogerSQTesteHTML.html';
    Self.rvsystm.SystemSetups   := Self.rvsystm.SystemSetups - [ssAllowSetup];

    Self.rvprjct.Engine := Self.rvsystm;
    Self.rvprjct.Execute;


    Page := Self.rvprjct.ProjMan.FindRaveComponent('Report1.Page1', nil) as TRavePage;

end;

procedure TForm1.btnGenerateRTFClick(Sender : TObject);
var
    FileEnum : IEnumerable<TFileSystemEntry>;
    f :   TFileSystemEntry;
    buf : TMemoryStream;
    outPath, OutName : string;
begin
    OutPath := TFileHnd.ConcatPath([Self.edtDestDir.Directory, 'RTFs']);
    ForceDirectories(outPath);
    FileEnum := TDirectory.FileSystemEntries(Self.edtSourceDir.Directory, False);
    for f in FileEnum do begin
		 if (f.Name <> '.') and (f.Name <> '..') then begin
			 Self.hkstrms.ClearStreams;
			 Self.hkstrms.LoadFromFile(f.FullName);
            buf := TMemoryStream.Create;
            try
                Self.hkstrms.GetStream('1', buf);
                OutName := TFileHnd.ForceFileExtension(TFileHnd.ConcatPath([outPath, f.Name]), 'rtf');
                buf.SaveToFile(OutName);
            finally
                buf.Free;
            end;
        end;
    end;
end;

procedure TForm1.edtSourceDirChange(Sender : TObject);
begin
    Self.fllstSource.Directory := Self.edtSourceDir.Directory;
end;

procedure TForm1.fllstSourceChange(Sender : TObject);
begin
    if Self.fllstSource.SelCount = 1 then begin
        Self.LoadRTFFile(Self.fllstSource.FileName);
    end else begin
        Self.edtRTF.Clear;
    end;

end;

procedure TForm1.FormCloseQuery(Sender : TObject; var CanClose : boolean);
begin
    GlobalConfig.SourceDir := Self.edtSourceDir.Directory;
    GlobalConfig.DestDir   := Self.edtDestDir.Directory;
end;

procedure TForm1.FormCreate(Sender : TObject);
begin
    Self.edtSourceDir.Directory := TFileHnd.DeepExistingPath(GlobalConfig.SourceDir);
    Self.edtDestDir.Directory   := TFileHnd.DeepExistingPath(GlobalConfig.DestDir);
    Self.fllstSource.Directory  := Self.edtSourceDir.Directory;
end;

procedure TForm1.LoadRTFFile(const Filename : string);
var
    buf : TMemoryStream;
begin
    Self.hkstrms.ClearStreams;
    Self.hkstrms.LoadFromFile(Filename);
    buf := TMemoryStream.Create;
    try
        Self.hkstrms.GetStream('1', buf);
        Self.edtRTF.Lines.LoadFromStream(buf);
    finally
        buf.Free;
    end;
end;

procedure TForm1.rvrndrhtmlDecodeImage(Sender : TObject; ImageStream : TStream; ImageType : string; Bitmap : TBitmap);
begin
    if Sender = nil then begin
        MessageDlg('pau', mtInformation, [mbOK], 0);
    end;
end;

end.
