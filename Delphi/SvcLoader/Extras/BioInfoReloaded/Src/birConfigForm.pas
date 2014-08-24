{$IFDEF birConfigForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I bir.inc}

unit birConfigForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls, Mask, JvExMask, JvToolEdit;

type
  TConfigForm = class(TForm)
    edtDirOrderedPath: TJvDirectoryEdit;
    pnlBottom: TPanel;
    btnOk: TBitBtn;
    btnCancel: TBitBtn;
    lblOrderedPath: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ConfigForm: TConfigForm;

implementation

{$R *.dfm}

end.
