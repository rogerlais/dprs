unit boinstDataModule;

interface

uses
    SysUtils, Classes, JvComponentBase, JvCreateProcess;

type
    TMainDM = class(TDataModule)
        InstallProcess :   TJvCreateProcess;
        UninstallProcess : TJvCreateProcess;
        procedure InstallProcessTerminate(Sender : TObject; ExitCode : cardinal);
        procedure UninstallProcessTerminate(Sender : TObject; ExitCode : cardinal);
    private
        FInstallExitCode :   cardinal;
        FUninstallExitcode : cardinal;
        { Private declarations }
    public
        { Public declarations }
        property InstallExitCode : cardinal read FInstallExitCode;
        property UninstallExitCode : cardinal read FUninstallExitcode;
    end;

var
    MainDM : TMainDM;

implementation

{$R *.dfm}

procedure TMainDM.InstallProcessTerminate(Sender : TObject; ExitCode : cardinal);
begin
    Self.FInstallExitCode := ExitCode;
end;

procedure TMainDM.UninstallProcessTerminate(Sender : TObject; ExitCode : cardinal);
{{--------------------------------------------------------------------------------------------------------------------------------
TMainDM.UninstallProcessTerminate

Recupera o codigo de saida do processo de desinstalação

Revision: 11/3/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Self.FUninstallExitCode := ExitCode;
end;

end.
