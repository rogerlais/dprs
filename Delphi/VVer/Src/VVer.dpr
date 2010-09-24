program VVer;

uses
  Forms,
  vvMainForm in 'vvMainForm.pas' {Form1},
  vvConfig in 'vvConfig.pas',
  AppSettings in '..\..\..\..\Pcks\StfLib\Src\AppSettings.pas',
  EnhGrids in '..\..\..\..\Pcks\ECLib\Src\EnhGrids.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
