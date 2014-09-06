unit vvsmConfig;

interface

{removida}

uses
    Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, WinReg32, vvsConsts, vvConfig, vvProgItem;

const
    STR_DEFAULT_NET_INSTSEG = '<default>';
    VERSION_INFO_FILENAME   = 'VVER.ini';


type
    TVVServiceConfig = class(TVVStartupConfig)
    private
        _FProfileConfig : TVVProfileInfo;
        function GetDebugLevel : Integer;
        function GetCycleInterval : Integer;
        function GetLocalRepositoryPath : string;
        function GetRemoteRepositoryPath : string;
        function GetVersionServer : string;
        function GetIsUpdated : TVVUpdateStatus;
        function GetVersionConfig : TVVProfileInfo;
        function GetProfileName : string;
        function GetLocalUNC : string;
        function GetIsPrimaryPC : boolean;
        function GetPrimaryPC : string;
        function GetRegisterServer : string;
        function GetNetClientPort : Integer;
        function GetRootBaseConfigFilename : string;
    protected
        function GetProfileInfo : TVVProfileInfo; reintroduce;
    public
        //properties
        property DebugLevel : Integer read GetDebugLevel;
        property LocalRepositoryPath : string read GetLocalRepositoryPath;
        property RemoteRepositorPath : string read GetRemoteRepositoryPath;
        property CycleInterval : Integer read GetCycleInterval;
        property VersionServer : string read GetVersionServer;
        property VersionConfig : TVVProfileInfo read GetVersionConfig;
        property UpdateStatus : TVVUpdateStatus read GetIsUpdated;
        property ProfileName : string read GetProfileName;
        property LocalUNC : string read GetLocalUNC;
        property IsPrimaryPC : boolean read GetIsPrimaryPC;
        property PrimaryPC : string read GetPrimaryPC;
        property RegisterServer : string read GetRegisterServer;
        property NetClientPort : Integer read GetNetClientPort;
        property RootBaseConfigFilename : string read GetRootBaseConfigFilename;
        //methods
        procedure InitInfoVersions(const Filename : string);
    end;


var
    VVMConfig : TVVServiceConfig;


implementation

uses
    AppLog, WinNetHnd, TREConsts, TREUtils, JclSysInfo, StrHnd, Str_pas;


const
      {$IFDEF DEBUG}
    VERSION_URL_FILE = 'http://arquivos/setores/sesop/AppData/Tests/VerificadorVersoes/VVer.ini';
     {$ELSE}
	 VERSION_URL_FILE = 'http://arquivos/setores/sesop/AppData/VerificadorVersoes/VVer.ini';
	 {$ENDIF}


    IE_DEBUG_CLIENT_NAME = 'Debug\ClientName'; //nome forçado para depuração deste cliente

    {TODO -oroger -cdsg : remover constantes importadas sem sentido}
    IE_LOCAL_REPOSITORY  = 'InstSegPath';
    DV_LOCAL_REPOSITORY  = 'D:\Comum\InstSeg\VVer';
    IE_REMOTE_REPOSITORY = 'NetInstSeg';
    DV_REMOTE_REPOSITORY = STR_DEFAULT_NET_INSTSEG;
    IE_VERSION_SERVER    = 'VersionServer';
    DV_VERSION_SERVER    = 'vver.tre-pb.gov.br';

    IE_CYCLE_INTERVAL  = 'CycleInterval';
    DV_CYCLE_INTERVAL  = 60000;
    IE_NOTIFICATION_SENDER = 'NotificationSender';
    DV_NOTIFICATION_SENDER = 'sesop@tre-pb.jus.br';
    IE_ROOT_SERVERNAME = 'RootServerName';          //Nome do computador primario
    DV_ROOT_SERVERNAME = 'vver.tre-pb.gov.br';      //CNAME para o PDC de verificação de versões
    IE_DEBUG_LEVEL     = 'DebugLevel';
    DV_DEBUG_LEVEL     = 0;
    IE_PATH_LOCAL_INSTSEG = 'LocalInstSeg';
    DV_PATH_LOCAL_INSTSEG = 'D:\Comum\InstSeg\VVer';
    IE_PATH_LOCAL_TEMP = 'LocalTempDir';

    IE_PATH_LOCAL_PUBLICATION = 'LocalPublication';
    DV_PATH_LOCAL_PUBLICATION = '';

    IE_TRANSFER_BLOCKSIZE = 'BlockSize';
    DV_TRANSFER_BLOCKSIZE = 2048;


    IE_NET_TCP_PORT = 'TCPPort';
    DV_NET_TCP_PORT = 12014;

    IE_PARENT_SERVER = 'ParentServer';
    DV_PARENT_SERVER = '';

    //Configurações do Transbio
    VVER_ROOT_NODE_CONFIG = '';
    IMG_VOLUME_LABEL      = 'IMG';


procedure InitConfig();
var
    filename : string;
begin
    //Instancia de configuração com o mesmo nome do runtime + .ini
    filename  := RemoveFileExtension(ParamStr(0)) + APP_SETTINGS_EXTENSION_FILE_INI;
    VVMConfig := TVVServiceConfig.Create(filename, 'VVer'); //usar o mesmo KeyPrefix anterior para facilitar
	 TLogFile.GetDefaultLogFile.DebugLevel := VVMConfig.DebugLevel;
	 TLogFile.LogDebug( Format( 'Ajustando nível de depuração para = %d' , [ VVMConfig.DebugLevel ]), DBGLEVEL_NONE );
end;



{ TVVMConfig }

function TVVServiceConfig.GetCycleInterval : Integer;
    //periodo de tempo para cada verificação após cumprido o periodo de estabilização}
begin
    Result := ReadIntegerDefault(IE_CYCLE_INTERVAL, DV_CYCLE_INTERVAL);
end;

function TVVServiceConfig.GetDebugLevel : Integer;
    //Nivel de depuração
begin
    Result := Self.ReadIntegerDefault(IE_DEBUG_LEVEL, DV_DEBUG_LEVEL);
end;

function TVVServiceConfig.GetIsPrimaryPC : boolean;
begin
    Result := SameText(Self.ClientName, Self.PrimaryPC);
end;

function TVVServiceConfig.GetIsUpdated : TVVUpdateStatus;
var
    prof : TVVProfileInfo;
    p :    TProgItem;
    I :    Integer;
begin
    {TODO -oroger -cdsg : Varre configurações para indicar atualizações}
    if (Assigned(Self.VersionConfig)) then begin
        prof   := Self.VersionConfig;
        Result := usOK;
        try
            for I := 0 to prof.Count - 1 do begin
                p := prof.Programs[I];
                case p.UpdateStatus of
                    usUnknow : begin
                        Result := usUnknow;
                    end;
                    usOld : begin
                        Result := usOld;
                        Exit;
                    end;
                end;
            end;
        except
            on E : Exception do Result := usUnknow;
        end;
    end else begin
        Result := usUnknow;
    end;
end;

function TVVServiceConfig.GetLocalUNC : string;
begin
    if (System.DebugHook <> 0) then begin
        Result := '\\' + WinNetHnd.GetComputerName() + '\Documentos\suporte\publico\espelho';
    end else begin
        Result := '\\' + Self.PrimaryPC + '\Documentos\suporte\publico\espelho';
    end;
end;

function TVVServiceConfig.GetNetClientPort : Integer;
begin
    Result := Self.ReadIntegerDefault(IE_NET_TCP_PORT, DV_NET_TCP_PORT);
end;

function TVVServiceConfig.GetLocalRepositoryPath : string;
    //local para armazenamento local dos arquivos
begin
    Result := Self.ReadStringDefault(IE_LOCAL_REPOSITORY, DV_LOCAL_REPOSITORY);
end;

function TVVServiceConfig.GetPrimaryPC : string;
begin
    Result := TTREUtils.GetZonePrimaryComputer(Self.ClientName);
end;

function TVVServiceConfig.GetProfileInfo : TVVProfileInfo;
var
    profileURL, SOProfilePrefix, profileFilename : string;
    localFilename, remoteFilename : string;
begin
	 TLogFile.LogDebug( 'Leitura do perfil detalhado', DBGLEVEL_ULTIMATE );
    if (not Assigned(Self._ProfileInfo)) then begin
        //Tenta com o SO explicito
        profileURL := Self.ReadString('Profiles\' + SOProfilePrefix + Self.ProfileName + '\VerInfo');
        if (profileURL = EmptyStr) then begin //Não havendo para o SO explicito, tenta para todos
            SOProfilePrefix := ''; //Vazio -> todos/qualquer
            profileURL      := Self.ReadString('Profiles\' + SOProfilePrefix + Self.ProfileName + '\VerInfo');
            if (profileURL = EmptyStr) then begin //tenta para XP(forçado)
                SOProfilePrefix := 'XP.';
                profileURL      := Self.ReadString('Profiles\' + SOProfilePrefix + Self.ProfileName + '\VerInfo');
            end;
        end;
        if (profileURL <> EmptyStr) then begin
            //profileFilename   := dtmdMain.LoadURL(profileURL);
            //Buscar a entrada correta para a URL do perfil
            Self._ProfileInfo := TVVProfileInfo.Create(profileFilename);
        end;
    end;
    Result := Self._ProfileInfo;
end;

function TVVServiceConfig.GetProfileName : string;
var
    profileFilename : string;
    ct : TTREComputerType;
begin
    {TODO -oroger -cdsg : Pegar o nome do perfil atraves do AD do controlador de domínio, exceto para os casos onde não houve o mesmo }
    {TODO -oroger -cdsg : Opção para o caso acima é contato com o servidor configurado para o serviço }
    inherited;
    //impede salvamento de valores padrao
    Self.AutoCreate := False;

    //Identifica o perfil baseado no ordinal do nome do computador. Para id > 10 -> PCT, cc máquina zona
    ct := TTREUtils.GetComputerTypeByName(Self.ClientName);
    case ct of
        ctUnknow, ctCentralPDC, ctZonePDC, ctTREWKS : begin
            Result := 'Outros';
        end;
        ctCentralWKS, ctZoneWKS, ctZoneSTD : begin
            Result := 'ZE';
        end;
        ctNATT : begin
            Result := 'NATT';
        end;
        ctNATU : begin
            Result := 'NATU';
        end;
        ctDFE : begin
            Result := 'DFE';
        end;
        ctVirtual : begin
            Result := 'VM';
        end;
    end;
    if (GetWindowsVersion() = wvWin7) then begin
        Result := 'W7.' + Result;
    end else begin
        if (GetWindowsVersion() = wvWinXP) then begin
            Result := 'XP.' + Result;
        end else begin
            //Resolver para caso de SO não identificado
            Result := 'Outros.' + Result;
        end;
    end;

end;

function TVVServiceConfig.GetRegisterServer : string;
begin
    Result := Self.ReadStringDefault(IE_VERSION_SERVER, DV_VERSION_SERVER);
end;

function TVVServiceConfig.GetRemoteRepositoryPath : string;
    //local para baixar todos os arquivos
begin
    Result := Self.ReadStringDefault(IE_REMOTE_REPOSITORY, DV_REMOTE_REPOSITORY);
    if (SameText(Result, DV_REMOTE_REPOSITORY)) then begin
        Result := Self.LocalUNC;
    end;
end;

function TVVServiceConfig.GetRootBaseConfigFilename : string;
begin
    if (not Self.IsPrimaryPC) then begin
        raise Exception.Create('Atributo acessível apenas por máquinas primárias');
    end;
    Result := VERSION_URL_FILE;
end;

function TVVServiceConfig.GetVersionConfig : TVVProfileInfo;
var
    url, localFilename, remoteFilename : string;
begin
    if (not Assigned(Self._FProfileConfig)) then begin
        //nomeia arquivo de configuração local
        localFilename  := TFileHnd.ConcatPath([Self.LocalRepositoryPath, Self.ProfileName + '.ini']);
        //Tenta pegar o arquivo remoto(pode ser mais recente)
        remoteFilename := TFileHnd.ConcatPath([Self.RemoteRepositorPath, Self.ProfileName + '.ini']);
        if (Self.isPrimaryPC) then begin //tenta atualizar o remoto antes de atualizar o local
            url := Self.RootBaseConfigFilename;
            url := Str_pas.StrCopyBeforeLast('/', url);
            url := url + '/' + Self.ProfileName + '.ini';
            if (Self.LoadHTTPContent(url, remoteFilename)) then begin //em suceso atualiza arquivo local
                ForceDirectories(TFileHnd.ParentDir(localFilename));
                FileCopy(remoteFilename, localFilename, True);
            end else begin
                if (FileExists(remoteFilename)) then begin   //usa o arquivo remoto mesmo se existir
                    ForceDirectories(TFileHnd.ParentDir(localFilename));
                    FileCopy(remoteFilename, localFilename, True);
                end;
            end;
        end;
        if (not FileExists(localFilename)) then begin
            //raise Exception.Create('Sem arquivo de versões para este perfil');
            Result := nil;
            Exit;
        end;
        Self._FProfileConfig := TVVProfileInfo.Create(localFilename);
    end;
    Result := Self._FProfileConfig;
end;

function TVVServiceConfig.GetVersionServer : string;
    //nome do servidor para obter arquivo de versoes atualizado
begin
    Result := Self.ReadStringDefault(IE_VERSION_SERVER, DV_VERSION_SERVER);
end;

procedure TVVServiceConfig.InitInfoVersions(const Filename : string);
{{
Rotina de inicialização para a carga dos parametros iniciais e perfil associado
}
begin
    LoadGlobalInfo(Filename);
end;

initialization
    begin
        InitConfig();
    end;

end.
