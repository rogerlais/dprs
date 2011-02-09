program SvcLoaderInteractiveDebugger;

uses
  Forms,
  svclDemoForm in 'svclDemoForm.pas' {Form1},
  svclTransBio in 'svclTransBio.pas',
  svclBiometricFiles in 'svclBiometricFiles.pas' {BioFilesService: TService},
  FSEnum in 'FSEnum.pas',
  svclConfig in 'svclConfig.pas',
  WNetExHnd in '..\..\..\..\Pcks\WinNetLib\Src\WNetExHnd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBioFilesService, BioFilesService);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
