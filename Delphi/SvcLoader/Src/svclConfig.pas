{$IFDEF svclConfig}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclConfig;

interface

uses
    Classes, Windows, SysUtils, AppSettings;

const
    BIOMETRIC_FILE_EXTENSION   = '.bio';
    BIOMETRIC_FILE_MASK        = '*' + BIOMETRIC_FILE_EXTENSION;
    TRANSBIO_PATH_CONFIG       = 'D:\Aplic\TransBio\Bin\TransBioELO.ini';
    TRANSBIO_ROOT_NODE_CONFIG  = '';
    ELO_TRANSFER_TRANSBIO_PATH = 'HKEY_LOCAL_MACHINE\SOFTWARE\ELO\Config\DirTransfBio';


type
    TELOTransbioConfig = class(AppSettings.TBaseStartSettings)
    private
        _Elo2TransBio : string;
        function GetPathBio : string;
        function GetPathError : string;
        function GetPathRetrans : string;
        function GetPathTransmitted : string;
        procedure SetPathBio(const Value : string);
        procedure SetPathError(const Value : string);
        procedure SetPathRetrans(const Value : string);
        procedure SetPathTransmitted(const Value : string);
        function GetElo2TransBio : string;
        procedure SetElo2TransBio(const Value : string);
        function GetPathBioServiceRepository : string;
        procedure SetPathBioServiceRepository(const Value : string);
    public
        property PathBioServiceRepository : string read GetPathBioServiceRepository write SetPathBioServiceRepository;
        property PathBio : string read GetPathBio write SetPathBio;
        property PathTransmitted : string read GetPathTransmitted write SetPathTransmitted;
        property PathError : string read GetPathError write SetPathError;
        property PathRetrans : string read GetPathRetrans write SetPathRetrans;
        property Elo2TransBio : string read GetElo2TransBio write SetElo2TransBio;
    end;


    TBioReplicatorConfig = class(AppSettings.TBaseStartSettings)
    private
        _FLocalBackup :   string;
        FTransbioConfig : TELOTransbioConfig;
        function GetBioServiceGeneratorPath : string;
        function GetCycleInterval : Integer;
        function GetDebugLevel : Integer;
        function GetEncryptNetAccessPassword : string;
        function GetEncryptServicePassword : string;
        function GetisPrimaryComputer : boolean;
        function GetNetServicePort : Integer;
        function GetPathLocalBackup : string;
        function GetPathClientBackup : string;
        function GetPathServerBackup : string;
        function GetPathServiceCapture : string;
        function GetPrimaryComputerName : string;
        function GetServicePassword : string;
        function GetServiceUsername : string;
		 function GetPathELOTransbioConfigFile : string;
        function GetNotificationSender : string;
        procedure SetNotificationSender(const Value : string);
        function GetNotificationList : string;
        procedure SetNotificationList(const Value : string);
        function GetPathServiceLog : string;
    public
        constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
        destructor Destroy; override;
        property CycleInterval : Integer read GetCycleInterval;
        property DebugLevel : Integer read GetDebugLevel;
        property EncryptNetAccessPassword : string read GetEncryptNetAccessPassword;
        property EncryptServicePassword : string read GetEncryptServicePassword;
        property RunAsServer : boolean read GetisPrimaryComputer;
        property NetServicePort : Integer read GetNetServicePort;
        property PathELOBioService : string read GetBioServiceGeneratorPath;
        property PathELOTransbioConfigFile : string read GetPathELOTransbioConfigFile;
        property PathLocalBackup : string read GetPathLocalBackup;
        property PathClientBackup : string read GetPathClientBackup;
        property PathServerBackup : string read GetPathServerBackup;
        property PathServiceCapture : string read GetPathServiceCapture;
        property PathServiceLog : string read GetPathServiceLog;
        property PrimaryComputerName : string read GetPrimaryComputerName;
        property ServicePassword : string read GetServicePassword;
        property ServiceUsername : string read GetServiceUsername;
        property TransbioConfig : TELOTransbioConfig read FTransbioConfig;
        property NotificationSender : string read GetNotificationSender write SetNotificationSender;
        property NotificationList : string read GetNotificationList write SetNotificationList;
    end;


const
    APP_SERVICE_NAME        = 'BioFilesService';
    APP_SERVICE_KEY         = 'BioSvc';
    APP_SERVICE_DISPLAYNAME = 'SESOP TransBio Replicator';
    APP_SERVICE_GROUP       = 'SESOPSvcGroup';
    APP_NOTIFICATION_DESCRIPTION = 'SESOP-Serviço de replicação de arquivos biométricos';

    APP_SUPORTE_DEFAULT_PWD = '$!$adm!n';

var
    GlobalConfig : TBioReplicatorConfig;

implementation

uses
    FileHnd, TREUtils, TREConsts, WinDisks, TREUsers, WinNetHnd, CryptIni, WNetExHnd, svclUtils, StrHnd, WinReg32;

const
    IE_NET_ACCESS_PASSWORD = 'NetAccessPwd';
    IE_NET_USERNAME      = 'NetAccessUsername';
    IE_LOCAL_USERNAME    = 'LocalServiceUsername';
    IE_ENCRYPT_LOCAL_PASSWORD = 'LocalEncodedSvcPwd';
    IE_CYCLE_INTERVAL    = 'CycleInterval';
    IE_NOTIFICATION_SENDER = 'NotificationSender';
    DV_NOTIFICATION_SENDER = 'bioreplic@tre-pb.jus.br';
    IE_NOTIFICATION_LIST = 'NotificationList';
    DV_NOTIFICATION_LIST = 'bioreplic@tre-pb.jus.br;null@tre-pb.jus.br';
    {TODO -oroger -creq : Definir valor padrao para a lista de notificação}
    IE_PRIMARY_COMPUTER  = 'PrimaryComputer';  //Nome do computador primario
	 IE_STATION_BIOSERVICE_BIO = 'BioService.Bio';
    IE_STATION_BACKUP_PATH = 'PrimaryBackupPath';
    IE_SERVER_PATH_BACKUP = 'ServerBackupPath';
    DV_SERVER_PATH_BACKUP = 'I:\TransBio\Files\Trans';

    IE_DEBUG_LEVEL = 'DebugLevel';
    IE_RUN_AS_SERVER_FLAG = 'RunAsServer'; //Forca este computador ser servidor

    DV_SERVICE_NET_USERNAME = 'suporte';
    IE_NET_TCP_PORT  = 'ServerPort';
    DV_NET_TCP_PORT  = 12013;
    DV_CYCLEINTERVAL = 60000;

    IMG_VOLUME_LABEL = 'IMG';

    IE_TRANSBIO_PATH_CAPTURE = 'Arquivo\caminho';
    DV_TRANSBIO_PATH_CAPTURE = 'D:\aplic\transbio\files\bio\';
    IE_TRANSBIO_PATH_TRANSMITTED = 'Arquivo\caminhoTrans';
    DV_TRANSBIO_PATH_TRANSMITTED = 'D:\aplic\transbio\files\trans\';
    IE_TRANSBIO_PATH_ERROR = 'Arquivo\caminhoErro';
    DV_TRANSBIO_PATH_ERROR = 'D:\aplic\transbio\files\erro\';
    IE_TRANSBIO_PATH_RETRANS = 'Arquivo\caminhoRetry';
    DV_TRANSBIO_PATH_RETRANS = 'D:\aplic\transbio\files\Retrans\';
    DV_TRANSBIO_PATH_BIOSERVICE = 'D:\Aplic\biometria\bioservice\bio';
    DV_CLIENT_PATH_BACKUP = 'I:\BioFiles\Backup';


procedure InitConfiguration();
begin
    //Instancia de configuração com o mesmo nome do runtime + .ini
    GlobalConfig := TBioReplicatorConfig.Create(RemoveFileExtension(ParamStr(0)) + APP_SETTINGS_EXTENSION_FILE_INI,
        APP_SERVICE_NAME);
end;

{ TBioReplicatorConfig }

{
******************************************************* TBioReplicatorConfig *******************************************************
}
constructor TBioReplicatorConfig.Create(const FileName : string; const AKeyPrefix : string = '');
var
    TBConfigFilename : string;
begin
    inherited Create(FileName, AKeyPrefix);
     {$IFDEF  DEBUG}
    TBConfigFilename := ExpandFileName('..\Data\TransBioELO.ini');
     {$ELSE}
	 TBConfigFilename:=TRANSBIO_PATH_CONFIG;
	 {$ENDIF}
    if (FileExists(TBConfigFilename)) then begin
        Self.FTransbioConfig := TELOTransbioConfig.Create(TBConfigFilename, TRANSBIO_ROOT_NODE_CONFIG);
    end else begin
        {TODO -oroger -cdsg : gerar notificação}
        Self.FTransbioConfig := TELOTransbioConfig.Create(ExtractFilePath(ParamStr(0) + ExtractFileName(TRANSBIO_PATH_CONFIG)),
            TRANSBIO_ROOT_NODE_CONFIG); //arquivo nulo localizado na pasta do aplicativo, servindo apenas para facilitar operação
    end;
end;

destructor TBioReplicatorConfig.Destroy;
begin
    Self.FTransbioConfig.Free;
    inherited;
end;

function TBioReplicatorConfig.GetBioServiceGeneratorPath : string;
    ///<summary>
    ///Leitura do valor do repositorio do BioService
    ///</summary>
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\BioService.Bio');
{$ELSE}
	 Result := DV_TRANSBIO_PATH_BIOSERVICE;
{$ENDIF}
	 Result := ExpandFileName(Self.ReadStringDefault(IE_STATION_BIOSERVICE_BIO, Result));
end;

function TBioReplicatorConfig.GetCycleInterval : Integer;
var
    dv : TDefaultSettingValue;
begin
    dv := TDefaultSettingValue.Create;
    try
        dv.AsInteger := DV_CYCLEINTERVAL;
        Result := Self.ReadInteger(IE_CYCLE_INTERVAL, dv);
    finally
        dv.Free;
    end;
end;

function TBioReplicatorConfig.GetDebugLevel : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_DEBUG_LEVEL, 0);
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

function TBioReplicatorConfig.GetisPrimaryComputer : boolean;
begin
    Result := Self.ReadBooleanDefault(IE_RUN_AS_SERVER_FLAG, False);
end;

function TBioReplicatorConfig.GetNetServicePort : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_NET_TCP_PORT, DV_NET_TCP_PORT);
end;

function TBioReplicatorConfig.GetNotificationList : string;
begin
    Result := Self.ReadStringDefault(IE_NOTIFICATION_LIST, DV_NOTIFICATION_LIST);
end;

function TBioReplicatorConfig.GetNotificationSender : string;
begin
    Result := Self.ReadStringDefault(IE_NOTIFICATION_SENDER, DV_NOTIFICATION_SENDER);
end;

function TBioReplicatorConfig.GetPathELOTransbioConfigFile : string;
begin
    {TODO -oroger -cdsg : Leirutra do caminho do arquivo configuração Transbio}
end;

function TBioReplicatorConfig.GetPathLocalBackup : string;
const
    LOCAL_ENTRY = IE_STATION_BACKUP_PATH;
var
    CurrentLabel, ImgVolume : string;
    x : char;
begin
    Self._FLocalBackup := ExpandFileName(Self.ReadStringDefault(LOCAL_ENTRY, EmptyStr));
    if Self._FLocalBackup = EmptyStr then begin
        ImgVolume := EmptyStr;
        for x := 'P' downto 'E' do begin
            CurrentLabel := GetVolumeLabel(x);
            if (SameText(CurrentLabel, IMG_VOLUME_LABEL)) then begin
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

function TBioReplicatorConfig.GetPathClientBackup : string;
begin
{$IFDEF DEBUG}
    Result := '..\Data\PrimaryBackup';
{$ELSE}
	 Result := DV_CLIENT_PATH_BACKUP;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_STATION_BACKUP_PATH, Result));
end;

function TBioReplicatorConfig.GetPathServerBackup : string;
    ///
    /// Leitura do local onde a estação primária armazena os arquivos para transmissão
    ///
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\ServerTransmitted');
{$ELSE}
	 Result := DV_SERVER_PATH_BACKUP;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_SERVER_PATH_BACKUP, Result));
end;

function TBioReplicatorConfig.GetPathServiceCapture : string;
    ///<summary>
    ///Caminho de captura dos arquivos(a ser realizada localmente), depende de como o serviço Transbio seja configurado neste computador
    /// Possíveis locais:
    /// 1 - Local onde o ELO salva os arquivos
    /// 2 - Local onde o Transbio Salva os arquivos transmitidos
    /// 3 - Pasta do Bioservice(Local onde existe uma cópia para o caso do ELO não salver em outro local)
    ///</summary>
    ///<remarks>
    ///
    ///</remarks>
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\StationLocalCapturePath');
{$ELSE}
	 Result := DV_TRANSBIO_PATH_CAPTURE;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_STATION_BIOSERVICE_BIO, Result));
end;

function TBioReplicatorConfig.GetPathServiceLog : string;
begin
    Result := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'Logs']);
end;

function TBioReplicatorConfig.GetPrimaryComputerName : string;
var
    defName : string;
begin
  {$IFDEF DEBUG}
    defName := WinNetHnd.GetComputerName();
  {$ELSE}
    defName := TTREUtils.GetZonePrimaryComputer(WinNetHnd.GetComputerName());
  {$ENDIF}
    Result  := Self.ReadStringDefault(IE_PRIMARY_COMPUTER, defName);
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

procedure TBioReplicatorConfig.SetNotificationList(const Value : string);
begin
    Self.WriteString(IE_NOTIFICATION_LIST, Value);
end;

procedure TBioReplicatorConfig.SetNotificationSender(const Value : string);
begin
    Self.WriteString(IE_NOTIFICATION_SENDER, Value);
end;

{ TTransbioConfig }

function TELOTransbioConfig.GetElo2TransBio : string;
    ///<summary>
    ///Leitura do valor usado pelo ELO para copiar os arquivos gerado pelo Bioservice. Este valor deve ser sempre o mesmo usado pelo serviço Transbio
    ///</summary>
var
    reg : TRegistryNT;
begin
    if (Self._Elo2TransBio = EmptyStr) then begin
        reg := TRegistryNT.Create;
        try
            if (not reg.ReadFullString(ELO_TRANSFER_TRANSBIO_PATH, Self._Elo2TransBio)) then begin
                Self._Elo2TransBio := EmptyStr;
            end else begin
                Self._Elo2TransBio := ExpandFileName(Self._Elo2TransBio);
            end;
        finally
            reg.Free;
        end;
    end;
    Result := Self._Elo2TransBio;
end;

function TELOTransbioConfig.GetPathBio : string;
    ///<summary>
    ///Leitura do caminho usado pelo transbio para servir como local de leitura padrão dos arquivos
    ///</summary>
begin
{$IFDEF DEBUG}
    Result := '..\Data\TransBio.Bio';
{$ELSE}
	Result:=DV_TRANSBIO_PATH_CAPTURE;
{$ENDIF}
    Result := Self.ReadStringDefault(IE_TRANSBIO_PATH_CAPTURE, Result);
    Result := ExpandFileName(Result);
end;

function TELOTransbioConfig.GetPathBioServiceRepository : string;
    ///<summary>
    ///Local de saida para os arquivos do Bioservice
    ///</summary>
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\StationLocalCapturePath');
{$ELSE}
	 Result := DV_TRANSBIO_PATH_CAPTURE;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_STATION_BIOSERVICE_BIO, Result));
end;

function TELOTransbioConfig.GetPathError : string;
begin
    {TODO -oroger -cdsg : Leitura atributo}
    Result := ExpandFilename( Self.ReadStringDefault(IE_TRANSBIO_PATH_ERROR, DV_TRANSBIO_PATH_ERROR) );
end;

function TELOTransbioConfig.GetPathRetrans : string;
begin
	 {TODO -oroger -cdsg : Leitura atributo}
	 Result := ExpandFilename( Self.ReadStringDefault(IE_TRANSBIO_PATH_RETRANS,DV_TRANSBIO_PATH_RETRANS ) );
end;

function TELOTransbioConfig.GetPathTransmitted : string;
begin
	 {TODO -oroger -cdsg : Leitura atributo}
	 Result := ExpandFilename( Self.ReadStringDefault(IE_TRANSBIO_PATH_TRANSMITTED , DV_TRANSBIO_PATH_TRANSMITTED ) );
end;

procedure TELOTransbioConfig.SetElo2TransBio(const Value : string);
var
    reg : TRegistryNT;
begin
    {TODO -oroger -cdsg : escrita atributo}
    reg := TRegistryNT.Create;
    try
        reg.WriteFullString(ELO_TRANSFER_TRANSBIO_PATH, Value, True);
    finally
        reg.Free;
    end;
end;

procedure TELOTransbioConfig.SetPathBio(const Value : string);
 ///<summary>
 ///Escrita do caminho usado pelo transbio para servir como local de leitura padrão dos arquivos
 ///</summary>
 ///<remarks>
 ///
 ///</remarks>
begin
    Self.WriteString(IE_TRANSBIO_PATH_CAPTURE, Value);
end;

procedure TELOTransbioConfig.SetPathBioServiceRepository(const Value : string);
begin

end;

procedure TELOTransbioConfig.SetPathError(const Value : string);
begin
    {TODO -oroger -cdsg : Leitura atributo}
    Self.WriteString(IE_TRANSBIO_PATH_ERROR, Value);
end;

procedure TELOTransbioConfig.SetPathRetrans(const Value : string);
begin
    {TODO -oroger -cdsg : Leitura atributo}
    Self.WriteString(IE_TRANSBIO_PATH_RETRANS, Value);
end;

procedure TELOTransbioConfig.SetPathTransmitted(const Value : string);
begin
    {TODO -oroger -cdsg : Leitura atributo}
    Self.WriteString(IE_TRANSBIO_PATH_TRANSMITTED, Value);
end;

initialization
    begin
        InitConfiguration();
    end;

end.
