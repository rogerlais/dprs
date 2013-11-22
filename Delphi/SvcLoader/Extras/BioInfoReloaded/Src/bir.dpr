program bir;

uses
  Forms,
  birMainForm in 'birMainForm.pas' {Form1},
  birMainDM in 'birMainDM.pas' {DataModule1: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.
