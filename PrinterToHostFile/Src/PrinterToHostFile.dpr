program PrinterToHostFile;

uses
  Forms,
  p2hMainForm in 'p2hMainForm.pas' {PthfMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPthfMainForm, PthfMainForm);
  Application.Run;
end.
