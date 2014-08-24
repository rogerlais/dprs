program PrinterToHostFile;

uses
  Forms,
  p2hMainForm in 'p2hMainForm.pas' {PthfMainForm},
  p2hUtils in 'p2hUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Portas IP para impressoras de rede';
  Application.CreateForm(TPthfMainForm, PthfMainForm);
  Application.Run;
end.
