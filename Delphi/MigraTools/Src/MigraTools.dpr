program MigraTools;

uses
  Forms,
  mtMainForm in 'mtMainForm.pas' {MigraToolsMainForm},
  mtUtils in 'mtUtils.pas',
  mtConfig in 'mtConfig.pas',
  APIHnd in '..\..\..\..\Pcks\XPLib\Src\APIHnd.pas',
  mtDataModule in 'mtDataModule.pas' {MainDataModule: TDataModule},
  TREConfig in '..\..\..\..\Pcks\TRE\Src\TREConfig.pas',
  TREZones in '..\..\..\..\Pcks\TRE\Src\TREZones.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMigraToolsMainForm, MigraToolsMainForm);
  Application.CreateForm(TMainDataModule, MainDataModule);
  Application.Run;
end.
