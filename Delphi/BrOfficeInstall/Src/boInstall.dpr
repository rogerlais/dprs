program boInstall;

uses
  Forms,
  boInstMainForm in 'boInstMainForm.pas' {Form1},
  boInstUtils in 'boInstUtils.pas',
  boInstStation in 'boInstStation.pas',
  boinstConfig in 'boinstConfig.pas',
  boinstDataModule in 'boinstDataModule.pas' {MainDM: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Instalador automático BrOffice';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TMainDM, MainDM);
  Application.Run;
end.
