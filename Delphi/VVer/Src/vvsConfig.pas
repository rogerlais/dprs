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

	 TVVSConfig = class(TVVConfig, IFormatter)
    private
        function GetPathServiceLog : string;
        function GetNotificationSender : string;
        function GetPathLocalInstSeg : string;
        function GetPathTempDownload : string;
        function GetNetServicePort : Integer;
        function GetCycleInterval : Integer;
		 function GetParentServer : string;
		 function GetDebugLevel : Integer;
        function GetNetClientPort : Integer;
        function GetPathPublication : string;
        function GetRootServer : string;
        function GetPublicationName : string;
    protected
        function FormatLogMsg(const LogMsg : string; LogMessageType : TLogMessageType = lmtError) : string;
    public
        property PathServiceLog : string read GetPathServiceLog;
        property NotificationSender : string read GetNotificationSender;
        property PathLocalInstSeg : string read GetPathLocalInstSeg;
        property PathTempDownload : string read GetPathTempDownload;
        property PathPublication : string read GetPathPublication;
        property NetServicePort : Integer read GetNetServicePort;
        property NetClientPort : Integer read GetNetClientPort;
        property CycleInterval : Integer read GetCycleInterval;
        property ParentServer : string read GetParentServer;
		 property DebugLevel : Integer read GetDebugLevel;
        property RootServer : string read GetRootServer;
        property PublicationName : string read GetPublicationName;
    end;

var
    VVSvcConfig : TVVSConfig;

implementation

uses
    FileHnd, SysUtils, WinNetHnd, AppSettings, TREUtils, Classes, XPThreads;

const
    IE_CYCLE_INTERVAL  = 'CycleInterval';
    DV_CYCLE_INTERVAL  = 60000;
    IE_NOTIFICATION_SENDER = 'NotificationSender';
    DV_NOTIFICATION_SENDER = 'sesop@tre-pb.jus.br';
    IE_NOTIFICATION_LIST = 'NotificationList';
    DV_NOTIFICATION_LIST = 'sesop.l@tre-pb.jus.br';
    IE_ROOT_SERVERNAME = 'RootServerName';          //Nome do computador primario
    DV_ROOT_SERVERNAME = 'vver.tre-pb.gov.br';      //CNAME para o PDC de verificação de versões
    IE_DEBUG_LEVEL     = 'DebugLevel';
    IE_PATH_LOCAL_INSTSEG = 'LocalInstSeg';
    DV_PATH_LOCAL_INSTSEG = 'D:\Comum\InstSeg\VVer';
    IE_PATH_LOCAL_TEMP = 'LocalTempDir';

    IE_PATH_LOCAL_PUBLICATION = 'LocalPublication';
    DV_PATH_LOCAL_PUBLICATION = '';



    IE_NET_TCP_PORT = 'TCPPort';
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
    SysUtils.DecimalSeparator := '.';
    SysUtils.ThousandSeparator := ',';
    filename    := RemoveFileExtension(ParamStr(0)) + APP_SETTINGS_EXTENSION_FILE_INI;
    VVSvcConfig := TVVSConfig.Create(filename, APP_SERVICE_NAME);
    TLogFile.GetDefaultLogFile.DebugLevel := VVSvcConfig.DebugLevel;
    TLogFile.GetDefaultLogFile.Formatter := VVSvcConfig;
end;


{ TVVSConfig }

function TVVSConfig.FormatLogMsg(const LogMsg : string; LogMessageType : TLogMessageType) : string;
var
    T : TThread;
begin
    Result := AppLog.FormatMessageProc(LogMsg, LogMessageType); //Usa a formatação padrão sempre existente
    T      := TThread.CurrentThread;
    if (Assigned(T)) then begin
        if (T is TXPNamedThread) then begin
            Result := 'Thread Name = ' + TXPNamedThread(T).Name + #13#10 + Result;
        end else begin
            Result := 'Thread Class = ' + T.ClassName + #13#10 + Result;
        end;
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

function TVVSConfig.GetNetClientPort : Integer;
begin
    {TODO -oroger -cdsg : Garantir que tal configuração não pode ser aplicada a mesma porta para o mesmo processo}
    Result := Self.NetServicePort;
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
    {TODO -oroger -cdsg : alterar o valor padrão para o pc-primario, testar se o mesmo está na rede usando o servidor raiz para o caso de tudo falhar}
    //Calcula valor padrão antes de consultar a persistencia da configuração
    Result := TTREUtils.GetZonePrimaryComputer(Self.ClientName);
    if (Result = EmptyStr) then begin
        Result := DV_PARENT_SERVER;
    end else begin
        Result := Self.ReadStringDefault(IE_PARENT_SERVER, Result);
    end;
end;

function TVVSConfig.GetPathLocalInstSeg : string;
begin
    Result := Self.ReadStringDefault(IE_PATH_LOCAL_INSTSEG, DV_PATH_LOCAL_INSTSEG);
end;

function TVVSConfig.GetPathPublication : string;
begin
    Result := Self.ReadStringDefault(IE_PATH_LOCAL_PUBLICATION, DV_PATH_LOCAL_PUBLICATION);
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
    Result := TFileHnd.ConcatPath([Result, 'VVer']); //Trata-se de diretório a ser criado durante o processo de download
    Result := Self.ReadStringDefault(IE_PATH_LOCAL_TEMP, Result);
end;

function TVVSConfig.GetPublicationName : string;
begin
    Result := 'INSTSEG'; //Unica publica de interesse
end;

function TVVSConfig.GetRootServer : string;
begin
    Result := Self.ReadStringDefault(IE_ROOT_SERVERNAME, DV_ROOT_SERVERNAME);
    if (Result = EmptyStr) then begin
        Result := DV_ROOT_SERVERNAME;
    end;
end;

initialization
    begin
        InitConfiguration();
    end;

end.
