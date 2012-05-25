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
  ShellFilesHnd in '..\..\..\..\..\Pcks\ShellLib\Src\ShellFilesHnd.pas',
  AppLog in '..\..\..\..\..\Pcks\XPLib\Src\AppLog.pas',
  FileHnd in '..\..\..\..\..\Pcks\XPLib\Src\FileHnd.pas';

{$R *.RES}

begin
	Application.CreateForm(TDMMainController, DMMainController);
  Application.Run;
end.
