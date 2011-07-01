program ADUserMgr;

uses
  Forms,
  adumMainForm in 'adumMainForm.pas' {frmADUserMgr},
  adumMainDataModule in 'adumMainDataModule.pas' {DtMdMainADUserMgr: TDataModule},
  adumFrameUserBrowser in 'adumFrameUserBrowser.pas' {FrmUserBrowser: TFrame},
  adumFrameStatusOperation in 'adumFrameStatusOperation.pas' {FrameStatusOperation: TFrame},
  adumConfig in 'adumConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDtMdMainADUserMgr, DtMdMainADUserMgr);
  Application.CreateForm(TfrmADUserMgr, frmADUserMgr);
  Application.Run;
end.
