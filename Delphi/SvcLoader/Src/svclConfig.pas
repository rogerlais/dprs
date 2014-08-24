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
    ELO_TRANSFER_TRANSBIO_PATH = 'HKEY_LOCAL_MACHINE\SOFTWARE\ELO\Config\DirTransfBio';

const
    APP_SERVICE_NAME        = 'BioFilesService';
    APP_SERVICE_KEY         = 'BioSvc';
	 APP_SERVICE_DISPLAYNAME = 'SESOP TransBio Replicator';
	 APP_SERVICE_GROUP       = 'SESOPSvcGroup';
	 APP_NOTIFICATION_DESCRIPTION = 'SESOP-Serviço de replicação de arquivos biométricos';
	 APP_SERVICE_FIRST_DEPENDENCY = 'DnsCache'; {TODO -oroger -cfuture : Parametrizar nome das dependencias }


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
	 public
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
		 function GetPathBioService : string;
		 function GetCycleInterval : Integer;
		 function GetDebugLevel : Integer;
		 function GetRunAsServer : boolean;
		 function GetNetServicePort : Integer;
		 function GetPathClientFullyBackup : string;
		 function GetPathClientOrderlyBackup : string;
		 function GetPathServerOrderedBackup : string;
		 function GetPathServerTransBio : string;
		 function GetServerName : string;
		 function GetPathTransbioConfigFile : string;
		 function GetNotificationSender : string;
		 procedure SetNotificationSender(const Value : string);
		 function GetNotificationList : string;
		 procedure SetNotificationList(const Value : string);
		 function GetPathServiceLog : string;
		 procedure SetRunAsServer(const Value : boolean);
		 procedure SetPathClientBioService(const Value : string);
		 procedure SetCycleInterval(const Value : Integer);
		 procedure SetServerName(const Value : string);
		 procedure SetPathServerTransBio(const Value : string);
		 procedure SetPathServerOrderedBackup(const Value : string);
		 procedure SetNetServicePort(const Value : Integer);
		 procedure SetPathTransbioConfigFile(const Value : string);
		 procedure SetPathClientFullyBackup(const Value : string);
		 procedure SetPathClientOrderlyBackup(const Value : string);
		 function GetPathServerFullyBackup : string;
		 procedure SetPathServerFullyBackup(const Value : string);
		 procedure SetDebugLevel(const Value : Integer);
	 public
		 constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
		 destructor Destroy; override;
		 property CycleInterval : Integer read GetCycleInterval write SetCycleInterval;
		 property DebugLevel : Integer read GetDebugLevel write SetDebugLevel;
		 property RunAsServer : boolean read GetRunAsServer write SetRunAsServer;
		 property NetServicePort : Integer read GetNetServicePort write SetNetServicePort;
		 property PathTransbioConfigFile : string read GetPathTransbioConfigFile write SetPathTransbioConfigFile;
		 property PathClientBioService : string read GetPathBioService write SetPathClientBioService;
		 property PathClientFullyBackup : string read GetPathClientFullyBackup write SetPathClientFullyBackup;
		 property PathClientOrderlyBackup : string read GetPathClientOrderlyBackup write SetPathClientOrderlyBackup;
		 property PathServerOrderedBackup : string read GetPathServerOrderedBackup write SetPathServerOrderedBackup;
		 property PathServerFullyBackup : string read GetPathServerFullyBackup write SetPathServerFullyBackup;
		 property PathServerTransBio : string read GetPathServerTransBio write SetPathServerTransBio;
		 property PathServiceLog : string read GetPathServiceLog;
		 property ServerName : string read GetServerName write SetServerName;
		 property TransbioConfig : TELOTransbioConfig read FTransbioConfig;
		 property NotificationSender : string read GetNotificationSender write SetNotificationSender;
		 property NotificationList : string read GetNotificationList write SetNotificationList;
		 function isHotKeyPressed() : boolean;
		 function ToString() : string; override;
    end;

var
    GlobalConfig : TBioReplicatorConfig;

implementation

uses
    FileHnd, TREUtils, TREConsts, WinDisks, TREUsers, WinNetHnd, CryptIni, WNetExHnd, svclUtils, StrHnd, WinReg32, AppLog;

const
    IE_CYCLE_INTERVAL      = 'Common\CycleInterval';
    DV_CYCLE_INTERVAL      = 60000;
    IE_NOTIFICATION_SENDER = 'Common\NotificationSender';
    DV_NOTIFICATION_SENDER = 'bioreplic@tre-pb.jus.br';
    IE_NOTIFICATION_LIST   = 'Common\NotificationList';
    DV_NOTIFICATION_LIST   = 'sesop@tre-pb.jus.br';
    IE_STATION_SERVERNAME  = 'Client\ServerName';       //Nome do computador primario
    DV_STATION_SERVERNAME  = 'bioreplic.tre-pb.gov.br'; //CNAME para o PDC da biometria externa neste momento
    IE_CLIENT_PATH_BIOSERVICE_BIO = 'Client\PathClientBioService.Bio';
    IE_STATION_PATH_ORDERLY_BACKUP = 'Client\PathClientOrderlyBackup';
    IE_STATION_PATH_FULLY_BACKUP = 'Client\PathClientFullyBackup';

    IE_SERVER_PATH_ORDERED_BACKUP = 'Server\PathServerOrderedPath';
    DV_SERVER_PATH_ORDERED_BACKUP = 'I:\ReplicBio\Server\OrderlyBak';

    IE_SERVER_PATH_FULLY_BACKUP = 'Server\PathServerFullyPath';
    DV_SERVER_PATH_FULLY_BACKUP = 'I:\ReplicBio\Server\FullyBak';

    IE_SERVER_PATH_TRANSBIO_BIO = 'Server\PathServerTransBio.Bio';
    DV_SERVER_PATH_TRANSBIO_BIO = 'D:\Aplic\TransBio\Files\Bio';

    IE_DEBUG_LEVEL = 'Common\DebugLevel';
    IE_RUN_AS_SERVER_FLAG = 'Common\RunAsServer'; //Forca este computador ser servidor

    IE_NET_TCP_PORT = 'Common\TCPPort';
    DV_NET_TCP_PORT = 12013;

    //Configurações do Transbio
    TRANSBIO_ROOT_NODE_CONFIG = '';

    DV_TRANSBIO_PATH_BIOSERVICE = 'D:\Aplic\biometria\bioservice\bio';
    IMG_VOLUME_LABEL = 'IMG';

    IE_TRANSBIO_PATH_CONFIG = 'Common\TransbioConfigFile';
    DV_TRANSBIO_PATH_CONFIG = 'D:\Aplic\TransBio\Bin\TransBioELO.ini';

    IE_TRANSBIO_PATH_CAPTURE = 'Arquivo\caminho';
    DV_TRANSBIO_PATH_CAPTURE = 'D:\aplic\transbio\files\bio\';
    IE_TRANSBIO_PATH_TRANSMITTED = 'Arquivo\caminhoTrans';
    DV_TRANSBIO_PATH_TRANSMITTED = 'D:\aplic\transbio\files\trans\';
    IE_TRANSBIO_PATH_ERROR   = 'Arquivo\caminhoErro';
    DV_TRANSBIO_PATH_ERROR   = 'D:\aplic\transbio\files\erro\';
    IE_TRANSBIO_PATH_RETRANS = 'Arquivo\caminhoRetry';
    DV_TRANSBIO_PATH_RETRANS = 'D:\aplic\transbio\files\Retrans\';


    //Valores padrão para depuração
    DV_DBG_STATION_PATH_ORDERLY_BACKUP = '..\Data\Client\Orderly.Backup';
    DV_DBG_STATION_PATH_FULLY_BACKUP   = '..\Data\Client\Fully.Backup';

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
begin
    inherited Create(FileName, AKeyPrefix);
    Self.FTransbioConfig := TELOTransbioConfig.Create(Self.PathTransbioConfigFile, TRANSBIO_ROOT_NODE_CONFIG);
end;

destructor TBioReplicatorConfig.Destroy;
begin
    Self.FTransbioConfig.Free;
    inherited;
end;

function TBioReplicatorConfig.GetPathBioService : string;
    ///<summary>
    ///Leitura do valor do repositorio do BioService
    ///</summary>
begin
{$IFDEF DEBUG}
    Result := '..\Data\Client\BioService.Bio';
{$ELSE}
	 Result := DV_TRANSBIO_PATH_BIOSERVICE;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_CLIENT_PATH_BIOSERVICE_BIO, Result));
end;

function TBioReplicatorConfig.GetCycleInterval : Integer;
var
    dv : TDefaultSettingValue;
begin
    dv := TDefaultSettingValue.Create;
    try
        dv.AsInteger := DV_CYCLE_INTERVAL;
        Result := Self.ReadInteger(IE_CYCLE_INTERVAL, dv);
    finally
        dv.Free;
    end;
end;

function TBioReplicatorConfig.GetDebugLevel : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_DEBUG_LEVEL, 0);
end;

function TBioReplicatorConfig.GetRunAsServer : boolean;
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

function TBioReplicatorConfig.GetPathTransbioConfigFile : string;
    ///<summary>
    ///Leitura do caminho do arquivo configuração do Transbio
    ///</summary>
    ///<remarks>
    ///Não existindo cria um para uso imediato no local do aplicativo, mas sempre tentará usar o configurado
    ///</remarks>
var
    dv : string;
begin
     {$IFDEF  DEBUG}
    dv     := ExpandFileName('..\Data\Common\TransBioELO.ini');
     {$ELSE}
	 dv := DV_TRANSBIO_PATH_CONFIG;
	 {$ENDIF}
    Result := Self.ReadStringDefault(IE_TRANSBIO_PATH_CONFIG, dv);
    Result := ExpandFileName(Result);
    if (not FileExists(Result)) then begin
        //Fornece arquivo para esta oportunidade de forma forcada, mas em sessões futuras usará o correto
        TLogFile.Log('Transbio não localizado. Usando aquivo de configuração local para este serviço', lmtWarning);
        Result := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'TransBioELO.ini']);
    end;
end;

function TBioReplicatorConfig.GetPathClientFullyBackup : string;
    ///<summary>
    /// <returns>Caminho do local onde será realizado o backup local</returns>
    ///</summary>
    ///<remarks>
    ///Valor padrão do backup local será a unidade IMG ficando o caminho unidade:\BioFiles\Backup
    /// Erro será gerado se o computador não possuir este volume
    ///</remarks>
var
    msg, CurrentLabel, ImgVolume : string;
    x : char;
begin
    Self._FLocalBackup := ExpandFileName(Self.ReadStringDefault(IE_STATION_PATH_FULLY_BACKUP, EmptyStr));
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
            msg := 'Impossível determinar o volume de imagens deste computador'#13 +
                'Valor deve ser preinformado na configuração inicial!';
            TLogFile.Log(msg, lmtAlarm);
		 end;
		 {$IFDEF DEBUG}
		 Self._FLocalBackup := DV_DBG_STATION_PATH_FULLY_BACKUP;
		 {$ELSE}
		 if ( ImgVolume <> EmptyStr ) then begin
			Self._FLocalBackup := ImgVolume + ':\BioFiles\Backup.Full'; //Unidade de imagens adcionada a caminho fixo
		 end else begin
			Self._FLocalBackup := 'D:\AplicTRE\Suporte\BioFiles\Backup.Full'; //Unidade de imagens adcionada a caminho fixo
		 end;
		 {$ENDIF}
        Self.WriteString(IE_STATION_PATH_FULLY_BACKUP, Self._FLocalBackup);
    end;
    Result := ExpandFileName(Self._FLocalBackup);
end;

function TBioReplicatorConfig.GetPathClientOrderlyBackup : string;
    ///<summary>
    ///Caminho onde os arquivos de backup serão alocados de forma ordenada
    ///</summary>
    ///<remarks>
    ///Valor padrão subpasta do aplicativo \orderly
    ///</remarks>
begin
{$IFDEF DEBUG}
    Result := DV_DBG_STATION_PATH_ORDERLY_BACKUP;
{$ELSE}
	 Result := TFileHnd.ConcatPath( [ ExtractFilePath( ParamStr(0)), 'Backup.Orderly' ] );
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_STATION_PATH_ORDERLY_BACKUP, Result));
end;

function TBioReplicatorConfig.GetPathServerFullyBackup : string;
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\Server\Backup.Fully');
{$ELSE}
	 Result := DV_SERVER_PATH_FULLY_BACKUP;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_SERVER_PATH_FULLY_BACKUP, Result));
end;

function TBioReplicatorConfig.GetPathServerOrderedBackup : string;
    ///
    /// Leitura do local onde a estação primária armazena os arquivos para transmissão
    ///
begin
{$IFDEF DEBUG}
    Result := ExpandFileName('..\Data\Server\Orderly.Backup');
{$ELSE}
	 Result := DV_SERVER_PATH_ORDERED_BACKUP;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_SERVER_PATH_ORDERED_BACKUP, Result));
end;

function TBioReplicatorConfig.GetPathServerTransBio : string;
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
    Result := ExpandFileName('..\Data\Server\Transbio.Bio');
{$ELSE}
	 Result := DV_TRANSBIO_PATH_CAPTURE;
{$ENDIF}
    Result := ExpandFileName(Self.ReadStringDefault(IE_SERVER_PATH_TRANSBIO_BIO, Result));
end;

function TBioReplicatorConfig.GetPathServiceLog : string;
begin
    Result := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'Logs']);
end;

function TBioReplicatorConfig.GetServerName : string;
var
    defName : string;
begin
  {$IFDEF DEBUG}
    defName := WinNetHnd.GetComputerName();
  {$ELSE}
	 defName := DV_STATION_SERVERNAME;
  {$ENDIF}
    Result  := Self.ReadStringDefault(IE_STATION_SERVERNAME, defName);
end;

function TBioReplicatorConfig.isHotKeyPressed : boolean;
var
    State : TKeyboardState;
begin
    GetKeyboardState(State);
    Result := ((State[vk_Shift] and 128) <> 0);
end;

procedure TBioReplicatorConfig.SetPathClientFullyBackup(const Value : string);
begin
    Self.WriteString(IE_STATION_PATH_FULLY_BACKUP, Value);
end;

procedure TBioReplicatorConfig.SetCycleInterval(const Value : Integer);
begin
    Self.WriteInteger(IE_CYCLE_INTERVAL, Value);
end;

procedure TBioReplicatorConfig.SetDebugLevel(const Value : Integer);
begin
    Self.WriteInteger(IE_DEBUG_LEVEL, Value);
end;

procedure TBioReplicatorConfig.SetNetServicePort(const Value : Integer);
begin
    Self.WriteInteger(IE_NET_TCP_PORT, Value);
end;

procedure TBioReplicatorConfig.SetNotificationList(const Value : string);
begin
    Self.WriteString(IE_NOTIFICATION_LIST, Value);
end;

procedure TBioReplicatorConfig.SetNotificationSender(const Value : string);
begin
    Self.WriteString(IE_NOTIFICATION_SENDER, Value);
end;

procedure TBioReplicatorConfig.SetPathClientBioService(const Value : string);
begin
    Self.WriteString(IE_CLIENT_PATH_BIOSERVICE_BIO, Value);
end;

procedure TBioReplicatorConfig.SetPathClientOrderlyBackup(const Value : string);
begin
    Self.WriteString(IE_STATION_PATH_ORDERLY_BACKUP, Value);
end;

procedure TBioReplicatorConfig.SetPathTransbioConfigFile(const Value : string);
begin
    Self.WriteString(IE_TRANSBIO_PATH_CONFIG, Value);
end;

procedure TBioReplicatorConfig.SetPathServerFullyBackup(const Value : string);
begin
    Self.WriteString(IE_SERVER_PATH_FULLY_BACKUP, Value);
end;

procedure TBioReplicatorConfig.SetPathServerOrderedBackup(const Value : string);
begin
    Self.WriteString(IE_SERVER_PATH_ORDERED_BACKUP, Value);
end;

procedure TBioReplicatorConfig.SetPathServerTransBio(const Value : string);
begin
    Self.WriteString(IE_SERVER_PATH_TRANSBIO_BIO, Value);
end;

procedure TBioReplicatorConfig.SetRunAsServer(const Value : boolean);
begin
    Self.WriteBoolean(IE_RUN_AS_SERVER_FLAG, Value);
end;

procedure TBioReplicatorConfig.SetServerName(const Value : string);
begin
    Self.WriteString(IE_STATION_SERVERNAME, Value);
end;

function TBioReplicatorConfig.ToString : string;
var
    Lines : TStringList;
begin
    Lines := TStringList.Create;
    try
        Lines.LoadFromFile(Self.FIni.FileName);
        Result := Lines.Text;
	 finally
		 Lines.Free;
	 end;
end;

{ TTransbioConfig }

function TELOTransbioConfig.GetElo2TransBio : string;
    ///<summary>
    ///Leitura do valor usado pelo ELO para copiar os arquivos gerado pelo Bioservice. Este valor deve ser sempre o mesmo usado pelo serviço Transbio
    ///</summary>
var
    Reg : TRegistryNT;
begin
    if (Self._Elo2TransBio = EmptyStr) then begin
        Reg := TRegistryNT.Create;
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
    Result := '..\Data\Client\TransBio.Bio';
{$ELSE}
	Result:=DV_TRANSBIO_PATH_CAPTURE;
{$ENDIF}
    Result := Self.ReadStringDefault(IE_TRANSBIO_PATH_CAPTURE, Result);
    Result := ExpandFileName(Result);
end;

function TELOTransbioConfig.GetPathError : string;
begin
    Result := ExpandFilename(Self.ReadStringDefault(IE_TRANSBIO_PATH_ERROR, DV_TRANSBIO_PATH_ERROR));
end;

function TELOTransbioConfig.GetPathRetrans : string;
begin
    Result := ExpandFilename(Self.ReadStringDefault(IE_TRANSBIO_PATH_RETRANS, DV_TRANSBIO_PATH_RETRANS));
end;

function TELOTransbioConfig.GetPathTransmitted : string;
begin
    Result := ExpandFilename(Self.ReadStringDefault(IE_TRANSBIO_PATH_TRANSMITTED, DV_TRANSBIO_PATH_TRANSMITTED));
end;

procedure TELOTransbioConfig.SetElo2TransBio(const Value : string);
var
    Reg : TRegistryNT;
begin
    Reg := TRegistryNT.Create;
    try
        Reg.WriteFullString(ELO_TRANSFER_TRANSBIO_PATH, Value, True);
    finally
        Reg.Free;
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

procedure TELOTransbioConfig.SetPathError(const Value : string);
begin
    Self.WriteString(IE_TRANSBIO_PATH_ERROR, Value);
end;

procedure TELOTransbioConfig.SetPathRetrans(const Value : string);
begin
    Self.WriteString(IE_TRANSBIO_PATH_RETRANS, Value);
end;

procedure TELOTransbioConfig.SetPathTransmitted(const Value : string);
begin
    Self.WriteString(IE_TRANSBIO_PATH_TRANSMITTED, Value);
end;

initialization
    begin
        InitConfiguration();
    end;

end.
