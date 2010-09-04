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
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainDataModule: TMainDataModule;

implementation

{$R *.dfm}


procedure TMainDataModule.DataModuleCreate(Sender: TObject);
begin
     Self.AfterConstruction;
end;

end.
