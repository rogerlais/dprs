program MRFormat;

uses
  Forms,
  mrfMainForm in 'mrfMainForm.pas' {AppMainForm},
  uDriveEjector in 'uDriveEjector.pas',
  magfmtdisk in 'magfmtdisk.pas',
  uDiskEjectConst in 'uDiskEjectConst.pas',
  mrfConfiguration in 'mrfConfiguration.pas',
  uProcessAndWindowUtils in 'uProcessAndWindowUtils.pas',
  mrfConfigForm in 'mrfConfigForm.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TAppMainForm, AppMainForm);
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
