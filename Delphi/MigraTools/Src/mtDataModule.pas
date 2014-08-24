{$IFDEF mtDataModule.pas}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtDataModule;

interface

uses
  SysUtils, Classes;

type
  TMainDataModule = class(TDataModule)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainDataModule: TMainDataModule;

implementation

{$R *.dfm}


end.
