program DemoTCPFileTransferServer;

uses
  Forms,
  tftDemoMainForm in 'tftDemoMainForm.pas' {Form3},
  svclTCPTransfer in '..\..\Src\svclTCPTransfer.pas' {DMTCPTransfer: TDataModule},
  svclConfig in '..\..\Src\svclConfig.pas',
  svclUtils in '..\..\Src\svclUtils.pas',
  svclEditConfigForm in '..\..\Src\svclEditConfigForm.pas',
  svclTransBio in '..\..\Src\svclTransBio.pas',
  svclBiometricFiles in '..\..\Src\svclBiometricFiles.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TBioFilesService, BioFilesService);
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TDMTCPTransfer, DMTCPTransfer);
  Application.Run;
end.
