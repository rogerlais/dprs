{$IFDEF fuMainForm}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuMainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TFUMainWindow = class(TForm)
	 lstFoundFiles: TListBox;
	 btnSearch: TBitBtn;
  private
	 { Private declarations }
  public
	 { Public declarations }
  end;

var
  FUMainWindow: TFUMainWindow;

implementation

uses
	fuMainDataModule;

{$R *.dfm}

end.
