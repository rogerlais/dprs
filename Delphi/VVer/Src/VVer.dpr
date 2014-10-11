program VVer;

uses
  Forms,
  vvMainForm in 'vvMainForm.pas' {Form1},
  vvConfig in 'vvConfig.pas',
  vvMainDataModule in 'vvMainDataModule.pas' {dtmdMain: TDataModule},
  TREUtils in '..\..\..\..\Pcks\TRE\Src\TREUtils.pas',
  vvProgItem in 'vvProgItem.pas',
  FileInfo in '..\..\..\..\Pcks\WinSysLib\Src\FileInfo.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TdtmdMain, dtmdMain);
  Application.Run;
end.
