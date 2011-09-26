{$IFDEF fuMainDataModule}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuMainDataModule;

interface

uses
  SysUtils, Classes, JvComponentBase, JvSearchFiles, AppSettings;

type
  TDMMainController = class(TDataModule)
    srchfl1: TJvSearchFiles;
    procedure srchfl1FindFile(Sender: TObject; const AName: string);
  private
    { Private declarations }
  public
	 { Public declarations }
	 procedure RunUpdates;
  end;

var
  DMMainController: TDMMainController;

implementation

{$R *.dfm}

procedure TDMMainController.RunUpdates;
begin
	Self.srchfl1.Search;
end;

procedure TDMMainController.srchfl1FindFile(Sender: TObject; const AName: string);
begin
	WriteLn( System.Output, 'Encontrei em: ' + AName );
end;

end.
