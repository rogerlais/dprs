program MigraTools;

uses
  Forms,
  mtMainForm in 'mtMainForm.pas' {MigraToolsMainForm},
  mtUtils in 'mtUtils.pas',
  mtConfig in 'mtConfig.pas',
  mtDataModule in 'mtDataModule.pas' {MainDataModule: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'SESOP - Ferramenta de Migração';
  Application.CreateForm(TMigraToolsMainForm, MigraToolsMainForm);
  Application.CreateForm(TMainDataModule, MainDataModule);
  Application.Run;
end.
