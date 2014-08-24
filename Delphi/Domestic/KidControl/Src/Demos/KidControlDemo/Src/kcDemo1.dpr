program kcDemo1;

uses
  Forms,
  kcDemo1Main in 'kcDemo1Main.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
