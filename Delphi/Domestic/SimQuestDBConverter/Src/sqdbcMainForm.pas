unit sqdbcMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, FileCtrl, Mask, JvExMask, JvToolEdit;

type
  TForm1 = class(TForm)
    edtSourceDir: TJvDirectoryEdit;
    edtDestDir: TJvDirectoryEdit;
    fllstSource: TFileListBox;
    pnlBottom: TPanel;
    btnConvert: TBitBtn;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
    sqdbcConfig;

{$R *.dfm}



procedure TForm1.FormCreate(Sender: TObject);
begin
     Self.edtSourceDir.Directory:=GlobalConfig.SourceDir;
     Self.edtDestDir.Directory:=GlobalConfig.DestDir;
     Self.fllstSource.Directory:=GlobalConfig.SourceDir;
     FileHnd
end;

end.

