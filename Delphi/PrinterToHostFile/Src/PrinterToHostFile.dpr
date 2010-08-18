program PrinterToHostFile;

uses
  Forms,
  p2hMainForm in 'p2hMainForm.pas' {PthfMainForm},
  p2hUtils in 'p2hUtils.pas',
  TREZones in '..\..\..\Pcks\TRE\Src\TREZones.pas',
  TREUtils in '..\..\..\Pcks\TRE\Src\TREUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TPthfMainForm, PthfMainForm);
  Application.Run;
end.
