program VVer;

uses
  Forms,
  vvMainForm in 'vvMainForm.pas' {Form1},
  vvConfig in 'vvConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
