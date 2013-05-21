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
        function GetNetAccountPassword : string;
        function GetNetAccessUsername : string;
        function GetCycleInterval : Integer;
        function GetIsPrimaryComputer : boolean;
        function GetPrimaryBackupPath : string;
        function GetPrimaryTransmittedPath : string;
        function GetDebugLevel : Integer;
        function GetEncryptNetAccessPassword : string;
        function GetEncryptServicePassword : string;
        function GetServicePassword : string;
        function GetServiceUsername : string;
		 function GetNetServicePort : Integer;
    	 function GetPrimaryComputerName: string;
    public
        constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
        //Atributos privativos da estação
        property StationSourcePath : string read GetStationSourcePath;
        property StationLocalTransPath : string read GetStationLocalTransPath;
        property StationBackupPath : string read GetStationBackupPath;
        property StationRemoteTransPath : string read GetStationRemoteTransPath;
        //Atributos privativos do computador primario
        property PrimaryBackupPath : string read GetPrimaryBackupPath;
        property PrimaryTransmittedPath : string read GetPrimaryTransmittedPath;
        //Atributos do servico
        property NetAccesstPassword : string read GetNetAccountPassword;
        property EncryptNetAccessPassword : string read GetEncryptNetAccessPassword;
        property NetAccessUserName : string read GetNetAccessUsername;
        property CycleInterval : Integer read GetCycleInterval;
        property ServiceUsername : string read GetServiceUsername;
        property ServicePassword : string read GetServicePassword;
        property EncryptServicePassword : string read GetEncryptServicePassword;
        property NetServicePort : Integer read GetNetServicePort;
		 //Atributos da sessão
        property isPrimaryComputer : boolean read GetIsPrimaryComputer;
		 property DebugLevel : Integer read GetDebugLevel;
		 property PrimaryComputerName : string read GetPrimaryComputerName;
    end;


const
    APP_SERVICE_NAME = 'BioFilesService';
    APP_SERVICE_KEY  = 'BioSvc';

    APP_SUPORTE_DEFAULT_PWD = '$!$adm!n';
//APP_SUPORTE_DEFAULT_PWD = '12345678';

var
	 GlobalConfig : TBioReplicatorConfig;

implementation

uses
	 FileHnd, TREUtils, TREConsts, WinDisks, TREUsers, WinNetHnd, CryptIni, WNetExHnd, svclUtils, StrHnd;

const
	 IE_NET_ACCESS_PASSWORD = 'NetAccessPwd';
	 IE_NET_USERNAME   = 'NetAccessUsername';
	 IE_LOCAL_USERNAME = 'LocalServiceUsername';
	 IE_ENCRYPT_LOCAL_PASSWORD = 'LocalEncodedSvcPwd';
	 IE_CYCLE_INTERVAL = 'CycleInterval';
	 IE_PRIMARY_COMPUTER = 'PrimaryComputer';  //Nome do computador primario

	 DV_SERVICE_NET_USERNAME = 'suporte';
	 DV_NET_TCP_PORT = 12013;

	 {TODO -oroger -cdsg : Checar na inicialização do serviço as configurações locais para o ELO e Transbio de modo
	 a garantir o funcionamento correto/esperado}

procedure InitConfiguration();
begin
	 //Instancia de configuração com o mesmo nome do runtime + .ini
	 GlobalConfig := TBioReplicatorConfig.Create(RemoveFileExtension(ParamStr(0)) + '.ini', APP_SERVICE_NAME);
end;

{ TBioReplicatorConfig }

constructor TBioReplicatorConfig.Create(const FileName, AKeyPrefix : string);
begin
    inherited Create(FileName, AKeyPrefix);
    Self._FIsPrimaryComputer := -1; //Indica que ainda não se sabe
end;

function TBioReplicatorConfig.GetCycleInterval : Integer;
var
    dv : TDefaultSettingValue;
begin
    dv := TDefaultSettingValue.Create;
    try
        dv.AsInteger := 60000;
		 Result := Self.ReadInteger(IE_CYCLE_INTERVAL, dv);
	 finally
		 dv.Free;
	 end;
end;

function TBioReplicatorConfig.GetEncryptNetAccessPassword : string;
var
	 Cypher : TCypher;
begin
	 Cypher := TCypher.Create(APP_SERVICE_KEY);
	 try
		 Result := GlobalConfig.ReadStringDefault(IE_NET_ACCESS_PASSWORD, EmptyStr);
		 if Result = EmptyStr then begin
			 Result := Cypher.Encode(APP_SUPORTE_DEFAULT_PWD);
			 GlobalConfig.WriteString(IE_NET_ACCESS_PASSWORD, Result);
		 end;
	 finally
		 Cypher.Free;
	 end;
end;

function TBioReplicatorConfig.GetEncryptServicePassword : string;
var
	 cp : TCypher;
begin
	 //Gera o valor criptografado padrão
	 cp := TCypher.Create(APP_SERVICE_KEY);
	 try
		 Result := cp.Encode(APP_SUPORTE_DEFAULT_PWD);
	 finally
		 cp.Free;
	 end;
	 //Recupera valor, usndo o ecriptografado em falha
	 Result := Self.ReadStringDefault(IE_ENCRYPT_LOCAL_PASSWORD, Result);
end;

function TBioReplicatorConfig.GetDebugLevel : Integer;
begin
	 Result := Self.ReadIntegerDefault('DebugLevel', 0);
end;

function TBioReplicatorConfig.GetIsPrimaryComputer : boolean;
var
	 ret : boolean;
begin
	 if Self._FIsPrimaryComputer < 0 then begin  //Deve ser calculado nesta pessagem
		 //Verificas PDC(assumidos como primarios e unicos sempre)
		 ret := Pos('PDC01', UpperCase(GetComputerName())) > 0;
		 if (not ret) then begin //Checa STD01 assumida como sempre primaria em STDs
			 ret := TStrHnd.endsWith(UpperCase(GetComputerName), 'STD01');
        end;
        ret := Self.ReadBooleanDefault('IsPrimaryComputer', ret);
        if (ret) then begin
            Self._FIsPrimaryComputer := 1;  //É computador primário
		 end else begin
			 Self._FIsPrimaryComputer := 0; //não é computador primario
        end;
    end;
    Result := boolean(Self._FIsPrimaryComputer);
end;

function TBioReplicatorConfig.GetServicePassword : string;
var
    cr : TCypher;
begin
    cr := TCypher.Create(APP_SERVICE_KEY);
    try
        Result := cr.Decode(Self.EncryptServicePassword);
    finally
        cr.Free;
    end;
end;

function TBioReplicatorConfig.GetServiceUsername : string;
begin
    Result := Self.ReadStringDefault(IE_NET_USERNAME);
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
            if (SameText(CurrentLabel, 'IMG')) then begin
                ImgVolume := X;
                Break;
            end;
        end;
        if ImgVolume = EmptyStr then begin
            raise ESVCLException.Create('Impossível determinar o volume de imagens deste computador');
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

function TBioReplicatorConfig.GetPrimaryComputerName: string;
var
	defName : string;
begin
	{$IFDEF DEBUG}
	defName:=WinNetHnd.GetComputerName();
	{$ELSE}
	defName:=TTREUtils.GetZonePrimaryComputer( WinNetHnd.GetComputerName() );
	{$ENDIF}
	Result:=Self.ReadStringDefault( IE_PRIMARY_COMPUTER, defName );
end;

function TBioReplicatorConfig.GetPrimaryTransmittedPath : string;
    ///
    /// Leitura do local onde a estação primária armazena os arquivos para transmissão
    ///
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\PrimaryTransmitted');
{$ELSE}
    Result := 'I:\TransBio\Files\Trans';
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

function TBioReplicatorConfig.GetNetAccessUsername : string;
    ///
    /// Leitura da conta de acesso ao compartilhamento remoto do computador primário
    ///
var
    domain : string;
begin
    Result := Self.ReadStringDefault(IE_NET_USERNAME, Result);
    if (Result = EmptyStr) then begin
        domain := GetDomainFromComputerName(EmptyStr);
        if (domain <> EmptyStr) then begin
            Result := DV_SERVICE_NET_USERNAME + '@' + domain;
        end;
        Self.WriteString(IE_NET_USERNAME, Result);
    end;
end;

function TBioReplicatorConfig.GetNetAccountPassword : string;
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
        Result := cp.Decode(Self.EncryptNetAccessPassword);
    finally
        cp.Free;
    end;
end;

function TBioReplicatorConfig.GetNetServicePort : Integer;
begin
	 Result := Self.ReadIntegerDefault('ServerPort', DV_NET_TCP_PORT );
end;

initialization
    begin
        InitConfiguration();
    end;

end.
