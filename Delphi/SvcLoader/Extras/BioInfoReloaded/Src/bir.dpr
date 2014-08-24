program bir;

uses
  Forms,
  birMainForm in 'birMainForm.pas' {Form1},
  birMainDM in 'birMainDM.pas' {MainDM: TDataModule},
  birConfigForm in 'birConfigForm.pas' {ConfigForm},
  JvSearchFiles in '..\..\..\..\..\..\Pcks\Externals\jedi\jvcl\run\JvSearchFiles.pas',
  StrHnd in '..\..\..\..\..\..\Pcks\XPLib\Src\StrHnd.pas',
  StreamHnd in '..\..\..\..\..\..\Pcks\StfLib\Src\StreamHnd.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TMainDM, MainDM);
  Application.CreateForm(TConfigForm, ConfigForm);
  Application.Run;
end.
