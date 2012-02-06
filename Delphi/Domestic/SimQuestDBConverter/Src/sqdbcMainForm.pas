unit sqdbcMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls, Buttons, ExtCtrls, FileCtrl, Mask, JvExMask, JvToolEdit, HKStreamCol, JvExStdCtrls, JvRichEdit,
    JvComponentBase, JvRichEditToHtml, RpDefine, RpRender, RpRenderHTML, RpSystem, RpBase, RpFiler, RpRave;

type
    TForm1 = class(TForm)
        edtSourceDir : TJvDirectoryEdit;
        edtDestDir :   TJvDirectoryEdit;
        fllstSource :  TFileListBox;
        pnlBottom :    TPanel;
        btnConvert :   TBitBtn;
        hkstrms :      THKStreams;
        jvrchdthtml :  TJvRichEditToHtml;
        edtRTF :       TJvRichEdit;
        rvrndrhtml :   TRvRenderHTML;
        rvsystm :      TRvSystem;
        rvprjct :      TRvProject;
        procedure FormCreate(Sender : TObject);
        procedure edtSourceDirChange(Sender : TObject);
        procedure fllstSourceChange(Sender : TObject);
        procedure FormCloseQuery(Sender : TObject; var CanClose : boolean);
        procedure btnConvertClick(Sender : TObject);
        procedure rvrndrhtmlDecodeImage(Sender : TObject; ImageStream : TStream; ImageType : string; Bitmap : TBitmap);
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
    sqdbcConfig, FileHnd;

{$R *.dfm}



procedure TForm1.btnConvertClick(Sender : TObject);
begin
    {
    Self.jvrchdthtml.ConvertToHtml(Self.edtRTF, TFileHnd.ConcatPath([Self.edtDestDir.Directory,
        ExtractFileName(Self.fllstSource.FileName)]));

    }

    //Tentativa via Rave Reports prar html
    //Ajuste do render html

  Self.rvsystm.DefaultDest := rdFile;
  Self.rvsystm.DoNativeOutput := False;
  Self.rvsystm.RenderObject := Self.rvrndrhtml;
  Self.rvsystm.OutputFileName := 'RogerSQTesteHTML.html';
  Self.rvsystm.SystemSetups := Self.rvsystm.SystemSetups - [ssAllowSetup];

  Self.rvsystm.
  Self.rvprjct.Engine := Self.rvsystm;
  Self.rvprjct.Execute;

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
    Self.edtSourceDir.Directory := TFileHnd.DirPathExisting(GlobalConfig.SourceDir);
    Self.edtDestDir.Directory   := TFileHnd.DirPathExisting(GlobalConfig.DestDir);
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
