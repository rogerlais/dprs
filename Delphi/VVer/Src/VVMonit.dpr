program VVMonit;

uses
  Forms,
  vvsmMonitorMainForm in 'vvsmMonitorMainForm.pas' {VVMMonitorMainForm},
  vvsmMainDatamodule in 'vvsmMainDatamodule.pas' {VVSMMainDM: TDataModule},
  vvConfig in 'vvConfig.pas',
  vvsFileMgmt in 'vvsFileMgmt.pas',
  vvProgItem in 'vvProgItem.pas',
  vvsConsts in 'vvsConsts.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Verificador de Versões - Módulo Monitor';
  Application.CreateForm(TVVSMMainDM, VVSMMainDM);
  Application.CreateForm(TVVMMonitorMainForm, VVMMonitorMainForm);
  Application.Run;
end.
