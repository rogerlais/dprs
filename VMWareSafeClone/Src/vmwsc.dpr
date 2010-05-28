program vmwsc;

uses
  Forms,
  vwscMainForm in 'vwscMainForm.pas' {VMCloneMainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TVMCloneMainForm, VMCloneMainForm);
  Application.Run;
end.
