program WKSPrep;

uses
  Forms,
  wpMainForm in 'wpMainForm.pas' {Form1},
  wpController in 'wpController.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
