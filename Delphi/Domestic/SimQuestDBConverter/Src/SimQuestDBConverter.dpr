program SimQuestDBConverter;

uses
  Forms,
  sqdbcMainForm in 'sqdbcMainForm.pas' {Form1},
  sqdbcConfig in 'sqdbcConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
