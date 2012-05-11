{$IFDEF svclConfig}
    {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclConfig;

interface

uses
    Classes, Windows, SysUtils, AppSettings;

const
    BIOMETRIC_FILE_EXTENSION = '.bio';
    BIOMETRIC_FILE_MASK      = '*' + BIOMETRIC_FILE_EXTENSION;

type
    TBioReplicatorConfig = class(AppSettings.TBaseStartSettings)
    private
        _FLocalBackup :       string;
        _FIsPrimaryComputer : Integer;
        function GetStationSourcePath : string;
        function GetStationRemoteTransPath : string;
        function GetStationLocalTransPath : string;
        function GetStationBackupPath : string;
        function GetServiceAccountPassword : string;
        function GetServiceAccountName : string;
        function GetCycleInterval : Integer;
        function GetIsPrimaryComputer : boolean;
        function GetPrimaryBackupPath : string;
        function GetPrimaryToTransmitPath : string;
        function GetDebugLevel : Integer;
        function GetCypherServiceAccountPwd : string;
    public
        constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
        //Atributos privativos da estação
        property StationSourcePath : string read GetStationSourcePath;
        property StationLocalTransPath : string read GetStationLocalTransPath;
        property StationBackupPath : string read GetStationBackupPath;
        property StationRemoteTransPath : string read GetStationRemoteTransPath;
        //Atributos privativos do computador primario
        property PrimaryBackupPath : string read GetPrimaryBackupPath;
        property PrimaryTransmittedPath : string read GetPrimaryToTransmitPath;
        //Atributos do servico
        property ServiceAccountPassword : string read GetServiceAccountPassword;
        property CypherServiceAccountPwd : string read GetCypherServiceAccountPwd;
        property ServiceAccountName : string read GetServiceAccountName;
        property CycleInterval : Integer read GetCycleInterval;
        //Atributos da sessão
        property isPrimaryComputer : boolean read GetIsPrimaryComputer;
        property DebugLevel : Integer read GetDebugLevel;
    end;


const
    APP_SERVICE_NAME = 'BioFilesService';
    APP_SERVICE_KEY  = 'BioSvc';

    APP_SUPORTE_DEFAULT_PWD = '$!$adm!n';

var
    GlobalConfig : TBioReplicatorConfig;

implementation

uses
    FileHnd, TREUtils, TREConsts, WinDisks, TREUsers, WinNetHnd, CryptIni, WNetExHnd;

const
    IE_SERVICE_PASSWORD = 'EncodedSvcPwd';
    IE_SHARE_USERNAME   = 'ShareAccountName';

    DV_SERVICE_SHARE_USERNAME = 'suporte';

procedure InitConfiguration();
begin
    //Instancia de configuração com o mesmo nome do runtime + .ini
    GlobalConfig := TBioReplicatorConfig.Create(RemoveFileExtension(ParamStr(0)) + '.ini', APP_SERVICE_NAME);
end;

{ TBioReplicatorConfig }

constructor TBioReplicatorConfig.Create(const FileName, AKeyPrefix : string);
begin
    inherited Create(FileName, AKeyPrefix);
    Self._FIsPrimaryComputer := -1;
end;

function TBioReplicatorConfig.GetCycleInterval : Integer;
var
    dv : TDefaultSettingValue;
begin
    dv := TDefaultSettingValue.Create;
    try
        dv.AsInteger := 60000;
        Result := Self.ReadInteger('CycleInterval', dv);
    finally
        dv.Free;
    end;
end;

function TBioReplicatorConfig.GetCypherServiceAccountPwd : string;
var
    Cypher : TCypher;
begin
    Cypher := TCypher.Create(APP_SERVICE_KEY);
    try
        Result := GlobalConfig.ReadStringDefault(IE_SERVICE_PASSWORD, EmptyStr);
        if Result = EmptyStr then begin
            Result := Cypher.Encode(APP_SUPORTE_DEFAULT_PWD);
            GlobalConfig.WriteString(IE_SERVICE_PASSWORD, Result);
        end;
    finally
        Cypher.Free;
    end;
end;

function TBioReplicatorConfig.GetDebugLevel : Integer;
begin
    Result := Self.ReadIntegerDefault('DebugLevel', 0);
end;

function TBioReplicatorConfig.GetIsPrimaryComputer : boolean;
var
    pc : string;
begin
	 if Self._FIsPrimaryComputer < 0 then begin  //Deve ser calculado nesta pessagem
		 {$IFDEF DEBUG}
		 pc := TTREUtils.GetZonePrimaryComputer('CPB080WKS99');
		 //Linha abaixo força este computador como primario
		 pc:=WinNetHnd.GetComputerName();
		 {$ELSE}
		 pc:=Self.ReadStringDefault('ForcedPrimaryComputer');
		 {$ENDIF}
		 if pc = EmptyStr then begin
			 pc := TTREUtils.GetZonePrimaryComputer(WinNetHnd.GetComputerName());
		 end;
		 if SameText(pc, WinNetHnd.GetComputerName()) then begin
            Self._FIsPrimaryComputer := 1;
        end else begin
            Self._FIsPrimaryComputer := 0;
        end;
    end;
    Result := boolean(Self._FIsPrimaryComputer);
end;

function TBioReplicatorConfig.GetStationBackupPath : string;
const
    LOCAL_ENTRY = 'StationBackupPath';
var
    CurrentLabel, ImgVolume : string;
    x : char;
begin
    Self._FLocalBackup := ExpandFileName(Self.ReadStringDefault(LOCAL_ENTRY, EmptyStr));
    if Self._FLocalBackup = EmptyStr then begin
        ImgVolume := EmptyStr;
        for x := 'P' downto 'E' do begin
            CurrentLabel := GetVolumeLabel(x);
            if SameText(CurrentLabel, 'IMG') then begin
                ImgVolume := X;
                Break;
            end;
        end;
        if ImgVolume = EmptyStr then begin
            raise Exception.Create('Impossível determinar o volume de imagens deste computador');
        end;
         {$IFDEF DEBUG}
        Self._FLocalBackup := ExpandFileName('..\Data\StationBackupPath');
         {$ELSE}
        Self._FLocalBackup := ImgVolume + ':\BioFiles\Backup'; //Unidade de imagens adcionada a caminho fixo
         {$ENDIF}
        Self.WriteString(LOCAL_ENTRY, Self._FLocalBackup);
    end;
    Result := Self._FLocalBackup;
end;

function TBioReplicatorConfig.GetStationSourcePath : string;
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\StationSourcePath');
{$ELSE}
    Result := 'D:\Aplic\biometria\bioservice\bio';
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault('StationSourcePath', Result));
end;

function TBioReplicatorConfig.GetStationLocalTransPath : string;
    //Caminho de transferência dos arquivos(a ser realizada localmente)
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\StationLocalTransPath');
{$ELSE}
    Result := 'D:\Aplic\TransBio\Files\Bio';
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault('StationLocalTransPath', Result));
end;

function TBioReplicatorConfig.GetPrimaryBackupPath : string;
begin
{$IFDEF DEBUG}
    Result := '..\Data\PrimaryBackup';
{$ELSE}
    Result := 'I:\BioFiles\Backup';
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault('PrimaryBackupPath', Result));
end;

function TBioReplicatorConfig.GetPrimaryToTransmitPath : string;
    ///
    /// Leitura do local onde a estação primária armazena os arquivos para transmissão
    ///
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\PrimaryTransmitted');
{$ELSE}
    Result := 'D:\Aplic\TransBio\Files\Bio';
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault('PrimaryTransmittedPath', Result));
end;

function TBioReplicatorConfig.GetStationRemoteTransPath : string;
var
    host : string;
begin
{$IFDEF DEBUG}
    host   := TTREUtils.GetZonePrimaryComputer('ZPB080STD99');
    Result := ExpandFileName('..\Data\StationRemoteTransPath');
{$ELSE}
    host   := TTREUtils.GetZonePrimaryComputer(WinNetHnd.GetComputerName());
    Result := '\\' + host + '\Transbio$\Files\Bio'; //Lembrar do compartilhamento oculto
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault('StationRemoteTransPath', Result));
end;

function TBioReplicatorConfig.GetServiceAccountName : string;
    ///
    /// Leitura da conta de acesso ao compartilhamento remoto do computador primário
    ///
var
    domain : string;
begin
    Result := Self.ReadStringDefault(IE_SHARE_USERNAME, Result);
    if (Result = EmptyStr) then begin
        domain := GetDomainFromComputerName(EmptyStr);
        if (domain <> EmptyStr) then begin
            Result := domain + '\' + DV_SERVICE_SHARE_USERNAME;
        end;
        Self.WriteString(IE_SHARE_USERNAME, Result);
    end;
end;

function TBioReplicatorConfig.GetServiceAccountPassword : string;
    /// Retorna a senha para a conta usada para levantar os serviços
    ///
    /// Revision - 20120510 - roger
    /// Para 2012 as senhas de suporte são estáticas e constantes
    /// Assim serão salvas de forma criptografada no arquivo de inicialização
var
    cp : TCypher;
begin
    cp := TCypher.Create(APP_SERVICE_KEY);
    try
		 Result := cp.Decode(Self.CypherServiceAccountPwd);
    finally
        cp.Free;
    end;
end;

initialization
    begin
        InitConfiguration();
    end;

end.
