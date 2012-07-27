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
        lstFoundFiles : TListBox;
        btnSearch :     TBitBtn;
        procedure btnSearchClick(Sender : TObject);
        procedure FormCreate(Sender : TObject);
    private
        { Private declarations }
    public
        { Public declarations }
    end;

var
    FUMainWindow : TFUMainWindow;

implementation

uses
    fuMainDataModule, FileHnd, AppLog;

{$R *.dfm}

procedure TFUMainWindow.btnSearchClick(Sender : TObject);
begin
    DMMainController.CheckUpdate(Self.lstFoundFiles.Items);
end;

procedure TFUMainWindow.FormCreate(Sender : TObject);
begin
    {$IFDEF DEBUG}
    Self.Caption := 'Atualizador de Sistemas Administrativos - **** DEBUG *** V: ' + TFileHnd.VersionInfo(ParamStr(0));
    {$ELSE}
    Self.Caption := 'Atualizador de Sistemas Administrativos - V: ' + TFileHnd.VersionInfo(ParamStr(0));
    {$ENDIF}
end;

end.
