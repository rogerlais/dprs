program MigraTools;

uses
  Forms,
  mtMainForm in 'mtMainForm.pas' {MigraToolsMainForm},
  mtUtils in 'mtUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMigraToolsMainForm, MigraToolsMainForm);
  Application.Run;
end.
