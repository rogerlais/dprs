{$IFDEF FileUpdate}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

program FileUpdate;

uses
  SysUtils,
  Forms,
  fuMainDataModule in 'fuMainDataModule.pas' {DMMainController: TDataModule},
  fuMainForm in 'fuMainForm.pas' {FUMainWindow},
  fuCustomLog in 'fuCustomLog.pas',
  fuUserSwitcher in 'fuUserSwitcher.pas';

{$R *.RES}

begin
	Application.CreateForm(TDMMainController, DMMainController);
  Application.Run;
end.
