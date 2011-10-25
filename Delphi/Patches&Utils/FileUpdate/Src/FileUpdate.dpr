{$IFDEF FileUpdate}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

program FileUpdate;

uses
  SysUtils,
  Forms,
  fuMainDataModule in 'fuMainDataModule.pas' {DMMainController: TDataModule},
  fuMainForm in 'fuMainForm.pas' {FUMainWindow};


{$R *.RES}

begin
	Application.CreateForm( TDMMainController, DMMainController );
	Application.CreateForm( TFUMainWindow, FUMainWindow );
	Application.Run;
end.
