program SvcLoaderInteractiveDebugger;

uses
  Forms,
  svclDemoForm in 'svclDemoForm.pas' {Form1},
  svclTransBio in 'svclTransBio.pas',
  svclBiometricFiles in 'svclBiometricFiles.pas' {BioFilesService: TService},
  svclConfig in 'svclConfig.pas',
  TREUtils in '..\..\..\..\Pcks\TRE\Src\TREUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBioFilesService, BioFilesService);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
