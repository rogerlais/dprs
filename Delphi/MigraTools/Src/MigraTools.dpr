program MigraTools;

uses
  Forms,
  mtMainForm in 'mtMainForm.pas' {MigraToolsMainForm},
  mtUtils in 'mtUtils.pas',
  mtConfig in 'mtConfig.pas',
  TREConfig in '..\..\..\..\Pcks\TRE\Src\TREConfig.pas',
  AppLog in '..\..\..\..\Pcks\XPLib\Src\AppLog.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMigraToolsMainForm, MigraToolsMainForm);
  Application.Run;
end.
