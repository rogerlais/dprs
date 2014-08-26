unit vvsConfig;

interface

uses
    vvConfig, AppLog, vvsConsts;

const
    APP_SERVICE_NAME        = 'VVerService';
    APP_SERVICE_KEY         = 'VVerSvc';
    APP_SERVICE_DISPLAYNAME = 'SESOP Verificador de versões';
    APP_SERVICE_GROUP       = 'SESOPSvcGroup';
    APP_NOTIFICATION_DESCRIPTION = 'SESOP-Serviço de verificação de versões';

type
    ESVCLException = class(ELoggedException);

    TVVSConfig = class(TVVConfig)
    private
        function GetPathServiceLog : string;
        function GetNotificationSender : string;
        function GetPathLocalInstSeg : string;
        function GetPathTempDownload : string;
        function GetNetServicePort : Integer;
        function GetCycleInterval : Integer;
        function GetParentServer : string;
        function GetDebugLevel : Integer;
        function GetClientName : string;
    protected

    public
        property PathServiceLog : string read GetPathServiceLog;
        property NotificationSender : string read GetNotificationSender;
        property PathLocalInstSeg : string read GetPathLocalInstSeg;
        property PathTempDownload : string read GetPathTempDownload;
        property NetServicePort : Integer read GetNetServicePort;
        property CycleInterval : Integer read GetCycleInterval;
        property ParentServer : string read GetParentServer;
        property DebugLevel : Integer read GetDebugLevel;
        property ClientName : string read GetClientName;
    end;

var
    VVSvcConfig : TVVSConfig;

implementation

uses
    FileHnd, SysUtils, WinNetHnd, AppSettings, TREUtils;

const
    IE_CYCLE_INTERVAL  = 'CycleInterval';
    DV_CYCLE_INTERVAL  = 60000;
    IE_NOTIFICATION_SENDER = 'NotificationSender';
    DV_NOTIFICATION_SENDER = 'sesop.l@tre-pb.jus.br';
    IE_NOTIFICATION_LIST = 'NotificationList';
    DV_NOTIFICATION_LIST = 'sesop@tre-pb.jus.br';
    IE_ROOT_SERVERNAME = 'RootServerName';          //Nome do computador primario
    DV_ROOT_SERVERNAME = 'vver.tre-pb.gov.br';      //CNAME para o PDC de verificação de versões
    IE_DEBUG_LEVEL     = 'DebugLevel';
    IE_PATH_LOCAL_INSTSEG = 'LocalInstSeg';
    DV_PATH_LOCAL_INSTSEG = 'D:\Comum\InstSeg\VVer';
    IE_PATH_LOCAL_TEMP = 'LocalTempDir';

    IE_NET_TCP_PORT = 'Common\TCPPort';
    DV_NET_TCP_PORT = 12014;

    IE_PARENT_SERVER = 'ParentServer';
    DV_PARENT_SERVER = '';

    //Configurações do Transbio
    VVER_ROOT_NODE_CONFIG = '';
    IMG_VOLUME_LABEL      = 'IMG';

procedure InitConfiguration();
var
    filename : string;
begin
    //Instancia de configuração com o mesmo nome do runtime + .ini
    filename    := RemoveFileExtension(ParamStr(0)) + APP_SETTINGS_EXTENSION_FILE_INI;
    VVSvcConfig := TVVSConfig.Create(filename, APP_SERVICE_NAME);
    TLogFile.GetDefaultLogFile.DebugLevel := VVSvcConfig.DebugLevel;
end;


{ TVVSConfig }

function TVVSConfig.GetClientName : string;
begin
    if (System.DebugHook <> 0) then begin //Depurando na IDE
        Result := 'Cliente_Debug';
    end else begin //Execução normal
        Result := WinNetHnd.GetComputerName();
    end;
end;

function TVVSConfig.GetCycleInterval : Integer;
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

function TVVSConfig.GetDebugLevel : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_DEBUG_LEVEL, 0);
end;

function TVVSConfig.GetNetServicePort : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_NET_TCP_PORT, DV_NET_TCP_PORT);
end;

function TVVSConfig.GetNotificationSender : string;
begin
    Result := Self.ReadStringDefault(IE_NOTIFICATION_SENDER, DV_NOTIFICATION_SENDER);
end;

function TVVSConfig.GetParentServer : string;
    /// <summary>
    /// Nome do servidor pai desta instância. Caso forçado, usará apenas este. Caso vazio busca pelo PC primário, e na falta deste pela URL global de configuração
    /// </summary>
begin
    Result := Self.ReadStringDefault(IE_PARENT_SERVER, DV_PARENT_SERVER);
    if (Result = EmptyStr) then begin
		 //Ajusta para o pc primario deste
		 {$IFDEF DEBUG}
		 Result := TTREUtils.GetZonePrimaryComputer(DBG_CLIENT_COMPUTERNAME);
		 {$ELSE}
		 Result := TTREUtils.GetZonePrimaryComputer(WinNetHnd.GetComputerName());
		 {$ENDIF}
    end;
end;

function TVVSConfig.GetPathLocalInstSeg : string;
begin
    Result := Self.ReadStringDefault(IE_PATH_LOCAL_INSTSEG, DV_PATH_LOCAL_INSTSEG);
end;

function TVVSConfig.GetPathServiceLog : string;
begin
    Result := TFileHnd.ConcatPath([ExtractFilePath(ParamStr(0)), 'Logs']);
end;

function TVVSConfig.GetPathTempDownload : string;
    /// <summary>
    ///   Local para baixar todos os arquivos temporariamente para depois mover para a pasta final
    /// </summary>
begin
    Result := FileHnd.GetTempDir();
    Result := Result + '\VVer'; //Trata-se de diretório a ser criado durante o processo de download
    Result := Self.ReadStringDefault(IE_PATH_LOCAL_TEMP, Result);
end;

initialization
    begin
        InitConfiguration();
    end;

end.
