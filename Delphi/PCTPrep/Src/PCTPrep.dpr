program PCTPrep;

uses
  Forms,
  pctprepMainForm in 'pctprepMainForm.pas' {MainForm},
  pctprepUtils in 'pctprepUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
