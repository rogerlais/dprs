{$IFDEF boinstConfig}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I boInstall.inc}

unit boinstConfig;

interface

uses
    SysUtils, Windows, WinReg32, AppSettings;

type
    TBOInstConfig = class(TBaseStartSettings)
    private
        function GetBaseProfileDate : TDateTime;
        function GetCurrentProfileDate : TDateTime;
        function GetInstallTempDir : string;
        function GetBaseProfileSourcePath : string;
        function GetMinDiskSpace : int64;
        function GetInstallDestination : string;
        function GetInstallPackageName : string;
        function GetInstallSourcePath : string;
        procedure SetCurrentProfileDate(const Value : TDateTime);
        function GetMinVersion : string;
        procedure SetInstallSourcePath(const Value : string);
        procedure SetBaseProfileSourcePath(const Value : string);
        procedure SetBaseProfileDate(const Value : TDateTime);
        procedure SetInstallDestination(const Value : string);
        procedure SetMinDiskSpace(const Value : int64);
        procedure SetInstallPackageName(const Value : string);
        procedure SetMinVersion(const Value : string);
    public
        property BaseProfileDate : TDateTime read GetBaseProfileDate write SetBaseProfileDate;
        property CurrentProfileDate : TDateTime read GetCurrentProfileDate write SetCurrentProfileDate;
        property InstallTempDir : string read GetInstallTempDir;
        property BaseProfileSourcePath : string read GetBaseProfileSourcePath write SetBaseProfileSourcePath;
        property MinDiskSpace : int64 read GetMinDiskSpace write SetMinDiskSpace;
        property InstallDestination : string read GetInstallDestination write SetInstallDestination;
        property InstallPackageName : string read GetInstallPackageName write SetInstallPackageName;
        property InstallSourcePath : string read GetInstallSourcePath write SetInstallSourcePath;
        property MinVersion : string read GetMinVersion write SetMinVersion;
    end;


var
    config : TBOInstConfig;

implementation

uses
    FileHnd;

const
    BO_INST_ROOT = 'BrOInstall';
    BO_REG_ROOT  = 'HKEY_USERS\.DEFAULT\Software\TRE-PB\BrOffice';


    //entradas fqn do registro
    EN_REG_CURRENT_PROFILE = BO_REG_ROOT + '\ForcedProfileDate';
    //entradas de startup
    EN_PROFILE_DATE   = 'ProfileDate';
    EN_MIN_DISK_SPACE = 'DiskSpaceRequired';
    EN_INSTALL_DIR    = 'InstallDir';
    EN_INSTALL_PACKAGE_NAME = 'InstallPackageName';
    EN_INSTALL_SOURCE_PATH = 'InstallSourcePath';
    EN_THRESHOLD_VERSION = 'MinVersion';
    EN_BASE_PROFILE   = 'BaseProfilePath';

    DV_MIN_VERSION = '3.2.0';

procedure InitConfig();
var
    path : string;
begin
    { TODO -oroger -cdsg : Capturar modo automatico de instalação (Empacotamento) }
    path   := ParamStr(0);
    path   := ChangeFileExt(path, '.ini');
    config := TBOInstConfig.Create(path, BO_INST_ROOT);
end;

{ TBOInstConfig }

function TBOInstConfig.GetBaseProfileSourcePath : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetBaseProfileSourcePath

Retorna o caminho expandido para servir de base para o perfil de usuário para esta versão

Revision: 10/3/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := SysUtils.ExpandFileName(Self.ReadStringDefault(EN_BASE_PROFILE, '.\BaseProfile'));
end;

function TBOInstConfig.GetCurrentProfileDate : TDateTime;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetCurrentProfileDate

Acessa o registro local do computador para ler o valor setado anteriormente por este aplicativo

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    reg : TRegistryNT;
begin
    reg := TRegistryNT.Create;
    try
        if (not reg.ReadFullDateTime(EN_REG_CURRENT_PROFILE, Result)) then begin
            reg.WriteFullDateTime(EN_REG_CURRENT_PROFILE, 0, True);
            Result := 0;
        end;
    finally
        reg.Free;
    end;
end;

function TBOInstConfig.GetInstallDestination : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetInstallDestination

Leitura do local de instalação

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := Self.ReadStringDefault(EN_INSTALL_DIR, 'D:\AplicTRE\BrOffice3');
end;

function TBOInstConfig.GetInstallPackageName : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetInstallPackageName

Leitura nome do pacote MSI a ser usado por esta versão de instalação

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := Self.ReadStringDefault(EN_INSTALL_PACKAGE_NAME, 'brofficeorg30.msi');
end;

function TBOInstConfig.GetInstallSourcePath : string;
begin
    Result := Self.ReadStringDefault(EN_INSTALL_SOURCE_PATH, '.\BrOfficeInstFiles');
end;

function TBOInstConfig.GetInstallTempDir : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetInstallTempDir

Retorna caminho temporario para os arquivos de instalação.
NOTA.: O caminho a ser retornado será no formato de nome curto para evitar atropelos nos mesmos

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := GetTempDir();
    Result := TFileHnd.ConcatPath([Result, 'BrOffice', 'install']);
    //***NOTA: Para API que retorna o nome curto funcionar eh necessario criar pasta antes
    if (not ForceDirectories(Result)) then begin
        raise Exception.CreateFmt('Erro criando repositório para a instalação: "%s"'#13'%s',
            [Result, SysErrorMessage(GetLastError())]);
    end;
    Result := FileShortName(Result);
end;

function TBOInstConfig.GetMinDiskSpace : int64;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetMinDiskSpace

Leitura do valor mínimo em disco para a instalação no disco de destino desejavel em bytes

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := Self.ReadIntegerDefault(EN_MIN_DISK_SPACE, 270000000);
end;

function TBOInstConfig.GetBaseProfileDate : TDateTime;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetProfileDate

Leitura da data de atualização do perfil informado no arquivo de configuração

Revision: 23/2/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    dummy : TDefaultSettingValue;
begin
    dummy := TDefaultSettingValue.Create(0);
    try
        Result := Self.ReadDateTime(EN_PROFILE_DATE, dummy);
    finally
        dummy.Free;
    end;
end;

procedure TBOInstConfig.SetBaseProfileDate(const Value : TDateTime);
begin
    Self.WriteDateTime(EN_PROFILE_DATE, Value);
end;

procedure TBOInstConfig.SetBaseProfileSourcePath(const Value : string);
begin
    Self.WriteString(EN_BASE_PROFILE, Value);
end;

procedure TBOInstConfig.SetCurrentProfileDate(const Value : TDateTime);
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.SetCurrentProfileDate

grava a data de atualização do perfil do BrOffice implantado no computador

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
var
    reg : TRegistryNT;
begin
    reg := TRegistryNT.Create;
    try
        reg.WriteFullDateTime(EN_REG_CURRENT_PROFILE, Value, True);
    finally
        reg.Free;
    end;
end;

procedure TBOInstConfig.SetInstallDestination(const Value : string);
begin
    Self.WriteString(EN_INSTALL_DIR, Value);
end;

procedure TBOInstConfig.SetInstallPackageName(const Value : string);
begin
    Self.WriteString(EN_INSTALL_PACKAGE_NAME, Value);
end;

procedure TBOInstConfig.SetInstallSourcePath(const Value : string);
begin
    Self.WriteString(EN_INSTALL_SOURCE_PATH, Value);
end;

procedure TBOInstConfig.SetMinDiskSpace(const Value : int64);
begin
    Self.WriteInteger(EN_MIN_DISK_SPACE, Value);
end;

procedure TBOInstConfig.SetMinVersion(const Value : string);
begin
    Self.WriteString(EN_THRESHOLD_VERSION, Value);
end;

function TBOInstConfig.GetMinVersion : string;
{{--------------------------------------------------------------------------------------------------------------------------------
TBOInstConfig.GetMinVersion

Leitura da minima versão esperada no computador

Revision: 22/4/2010 - roger
----------------------------------------------------------------------------------------------------------------------------------
}
begin
    Result := Self.ReadStringDefault(EN_THRESHOLD_VERSION, DV_MIN_VERSION);
end;

initialization
    begin
        InitConfig();
    end;

end.
