{$IFDEF vvConfig}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}
{$TYPEINFO OFF}

unit vvConfig;

interface

uses
    Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, WinReg32, vvsConsts, vvProgItem, IdBaseComponent, IdComponent,
    IdTCPConnection, IdTCPClient, IdHTTP;


const
    STR_DEFAULT_NET_INSTSEG = '<default>';
    VERSION_INFO_FILENAME   = 'VVER.ini';


type

    TVVProfileInfo = class(TBaseStartSettings)
    private
        FProgList : TObjectList;
        function GetPrograms(index : Integer) : TProgItem;
        function GetCount : Integer;
    public
        constructor Create(const Filename : string; const AKeyPrefix : string = ''); override;
        destructor Destroy; override;
        property Programs[index : Integer] : TProgItem read GetPrograms;
        property Count : Integer read GetCount;
    end;

    TVVStartupConfig = class(TBaseStartSettings)
    private
        FHTTPLoader :  TIdHTTP;
        FProfileName : string;
        function GetGlobalStatus : string;
        function GetClientName : string;
        function GetInfoText : string;
        function GetAutoMode : boolean;
        function GetNotificationList : string;
        function GetSenderAddress : string;
        function GetSenderDescription : string;
        function GetEnsureNotification : boolean;
        procedure InitDownloader();
        function GetCycleInterval : Integer;
        function GetIsUpdated : TVVUpdateStatus;
        function GetLocalRepositoryPath : string;
        function GetIsPrimaryPC : boolean;
        function GetPrimaryPC : string;
        function GetRootBaseConfigFilename : string;
        function GetRemoteRepositoryPath : string;
        function GetLocalUNC : string;
        function GetRegisterServer : string;
    function GetNetClientPort: integer;
    protected
        _ProfileInfo : TVVProfileInfo;
        function GetProfileInfo : TVVProfileInfo; virtual;
    public
        constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
        destructor Destroy; override;
        function ToString() : string;
        function LoadHTTPContent(const URL, DestFilename : string) : boolean;
        procedure InitInfoVersions(const filename : string);

        property GlobalStatus : string read GetGlobalStatus;
        property InfoText : string read GetInfoText;
        property ProfileInfo : TVVProfileInfo read GetProfileInfo;
        property AutoMode : boolean read GetAutoMode;
        property ProfileName : string read FProfileName;
        property NotificationList : string read GetNotificationList;
        property SenderAddress : string read GetSenderAddress;
        property SenderDescription : string read GetSenderDescription;
        property EnsureNotification : boolean read GetEnsureNotification;
        property ClientName : string read GetClientName;
        property CycleInterval : Integer read GetCycleInterval;
		 property UpdateStatus : TVVUpdateStatus read GetIsUpdated;
        property LocalRepositoryPath : string read GetLocalRepositoryPath;
        property IsPrimaryPC : boolean read GetIsPrimaryPC;
        property PrimaryPC : string read GetPrimaryPC;
        property RootBaseConfigFilename : string read GetRootBaseConfigFilename;
        property RemoteRepositoryPath : string read GetRemoteRepositoryPath;
        property LocalUNC : string read GetLocalUNC;
		 property RegisterServer : string read GetRegisterServer;
		 property NetClientPort : integer read GetNetClientPort;
    end;

procedure LoadGlobalInfo(const Filename : string);

var
    GlobalInfo : TVVStartupConfig = nil;


implementation

uses
    WinNetHnd, StrHnd, vvMainDataModule, FileInfo, TREConsts, JclSysInfo, TREUtils;

const
    IE_DEBUG_CLIENT_NAME = 'Debug\ClientName'; //nome forçado para depuração deste cliente

    IE_NOTIFICATION_LIST = 'NotificationList';
    DV_NOTIFICATION_LIST = 'sesop.l@tre-pb.jus.br';

    IE_CYCLE_INTERVAL = 'CycleInterval';
    DV_CYCLE_INTERVAL = 60000;

    IE_LOCAL_REPOSITORY = 'InstSegPath';
    DV_LOCAL_REPOSITORY = 'D:\Comum\InstSeg\VVer';

    IE_REMOTE_REPOSITORY = 'NetInstSeg';
    DV_REMOTE_REPOSITORY = STR_DEFAULT_NET_INSTSEG;

    IE_VERSION_SERVER = 'VersionServer';
    DV_VERSION_SERVER = 'vver.tre-pb.gov.br';

	     IE_NET_TCP_PORT = 'TCPPort';
    DV_NET_TCP_PORT = 12014;



procedure LoadGlobalInfo(const Filename : string);
 ///Monta rotina de carga das configurações iniciais, na ordem:
 /// 1 - Arquivo local de onde serão carregados os dados remotos
 ///
 /// Máquina primária no caminho do repositório
begin
    {TODO -oroger -cdsg : Carga dinamica do arquivo de configurações do serviço}
    GlobalInfo := TVVStartupConfig.Create(filename, 'VVer');
end;

{ TVVInfo }

constructor TVVStartupConfig.Create(const FileName, AKeyPrefix : string);
    ///
    /// Cria e carrega o perfil deste computador de acordo com o nome do mesmo.
    /// Monta o nome prefixando o sistema operacional com o tipo da estação
var
    localStartupConfFile, profileFilename : string;
    ct : TTREComputerType;
begin
    {TODO -oroger -cdsg : Pegar o nome do perfil atraves do AD do controlador de domínio, exceto para os casos onde não houve o mesmo }
    {TODO -oroger -cdsg : Opção para o caso acima é contato com o servidor configurado para o serviço }
    inherited;

    Self.InitDownloader();


    //impede salvamento de valores padrao
     {$IFDEF DEBUG}
    Self.AutoCreate := True;
     {$ELSE}
	 Self.AutoCreate := False;
	 {$ENDIF}

    //Identifica o perfil baseado no ordinal do nome do computador. Para id > 10 -> PCT, cc máquina zona
    ct := TTREUtils.GetComputerTypeByName(Self.ClientName);
    case ct of
        ctUnknow, ctCentralPDC, ctZonePDC, ctTREWKS : begin
            Self.FProfileName := 'Outros';
        end;
        ctCentralWKS, ctZoneWKS, ctZoneSTD : begin
            Self.FProfileName := 'ZE';
        end;
        ctNATT : begin
            Self.FProfileName := 'NATT';
        end;
        ctNATU : begin
            Self.FProfileName := 'NATU';
        end;
        ctDFE : begin
            Self.FProfileName := 'DFE';
        end;
        ctVirtual : begin
            Self.FProfileName := 'VM';
        end;
    end;
end;

destructor TVVStartupConfig.Destroy;
var
    tmpDir : string;
begin
    //Testa se arquivo foi gerado em temporario
    Self.FHTTPLoader.Free;
    tmpDir := FileHnd.GetTempDir;
    if TStrHnd.startsWith(Self.FIni.FileName, tmpDir) then begin
        DeleteFile(PWideChar(Self.FIni.FileName));
    end;
    inherited;
end;

function TVVStartupConfig.GetClientName : string;
begin
    Result := Self.ReadString(IE_DEBUG_CLIENT_NAME);
    if (Result = EmptyStr) then begin
        if (System.DebugHook <> 0) then begin
            Result := DBG_CLIENT_NAME;
        end else begin
            Result := WinNetHnd.GetComputerName();
        end;
    end;
end;

function TVVStartupConfig.GetCycleInterval : Integer;
begin
    Result := ReadIntegerDefault(IE_CYCLE_INTERVAL, DV_CYCLE_INTERVAL);
end;

function TVVStartupConfig.GetAutoMode : boolean;
var
    x : Integer;
begin
    //Identifica o modo de operação
    Result := False;
    for x := 0 to ParamCount do begin
        if SameText(ParamStr(x), '/auto') then begin
            Result := True;
            Exit;
        end;
    end;
end;

function TVVStartupConfig.GetEnsureNotification : boolean;
var
    enDefault : TDefaultSettingValue;
begin
    enDefault := TDefaultSettingValue.Create();
    try
        enDefault.AsBoolean := False;
        Result := Self.ReadBoolean('EnsureNotification', enDefault);
    finally
        enDefault.Free;
    end;
end;

function TVVStartupConfig.GetGlobalStatus : string;
var
    x : Integer;
begin
    if (Assigned(Self.ProfileInfo)) then begin
        Result := 'OK';
        for x := 0 to Self.ProfileInfo.Count - 1 do begin
            if not Self._ProfileInfo.Programs[x].isUpdated then begin
                Result := 'Pendente';
                Exit;
            end;
        end;
    end else begin
        Result := 'Erro!';
    end;
end;

function TVVStartupConfig.GetInfoText : string;
var
    x : Integer;
    p : TProgItem;
begin
    if (Assigned(Self.ProfileInfo)) then begin
        Result := 'Resumo da verficação das versões'#13#10;
        Result := Result + 'Computador: ' + WinNetHnd.GetComputerName();
        for x := 0 to Self.ProfileInfo.Count - 1 do begin
            Result := Result + #13#10;
            p      := Self._ProfileInfo.Programs[x];
            Result := Result + 'Sistema: ' + p.Desc + #13#10;
            Result := Result + 'Versão instalada: ' + p.CurrentVersion + #13#10;
            Result := Result + 'Versão esperada: ' + p.ExpectedVerEx + #13#10;
            if p.isUpdated then begin
                Result := Result + 'Situação: Atualizado'#13#10;
            end else begin
                Result := Result + 'Situação: Pendente'#13#10;
            end;
        end;
    end else begin
        Result := 'Sem perfil identificado para este computador';
    end;
end;

function TVVStartupConfig.GetIsPrimaryPC : boolean;
begin
    Result := SameText(Self.ClientName, Self.PrimaryPC);
end;

function TVVStartupConfig.GetIsUpdated : TVVUpdateStatus;
var
    prof : TVVProfileInfo;
    p :    TProgItem;
    I :    Integer;
begin
    {TODO -oroger -cdsg : Varre configurações para indicar atualizações}
    if (Assigned(Self.ProfileInfo)) then begin
        prof   := Self.ProfileInfo;
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

function TVVStartupConfig.GetLocalRepositoryPath : string;
    //local para armazenamento local dos arquivos
begin
    Result := Self.ReadStringDefault(IE_LOCAL_REPOSITORY, DV_LOCAL_REPOSITORY);
end;

function TVVStartupConfig.GetLocalUNC : string;
begin
    if (System.DebugHook <> 0) then begin
        Result := '\\' + WinNetHnd.GetComputerName() + '\Documentos\suporte\publico\espelho';
    end else begin
        Result := '\\' + Self.PrimaryPC + '\Documentos\suporte\publico\espelho';
    end;
end;

function TVVStartupConfig.GetNetClientPort: integer;
begin
    Result := Self.ReadIntegerDefault(IE_NET_TCP_PORT, DV_NET_TCP_PORT);
end;

function TVVStartupConfig.GetNotificationList : string;
begin
    Result := Self.ReadStringDefault(IE_NOTIFICATION_LIST, DV_NOTIFICATION_LIST);
end;

function TVVStartupConfig.GetPrimaryPC : string;
begin
    Result := TTREUtils.GetZonePrimaryComputer(Self.ClientName);
end;

function TVVStartupConfig.GetProfileInfo : TVVProfileInfo;
var
    profileURL, SOProfilePrefix, profileFilename : string;
begin
    if (Assigned(Self._ProfileInfo)) then begin
        Result := Self._ProfileInfo;
        Exit;
    end;
    //Tenta com o SO explicito
    profileURL := Self.ReadString('Profiles\' + Self.ProfileName + '\VerInfo');
    if (profileURL <> EmptyStr) then begin
        profileFilename   := dtmdMain.LoadURL(profileURL);
        //Buscar a entrada correta para a URL do perfil
        Self._ProfileInfo := TVVProfileInfo.Create(profileFilename);
    end;
    Result := Self._ProfileInfo;
end;

function TVVStartupConfig.GetRegisterServer : string;
begin
    Result := Self.ReadStringDefault(IE_VERSION_SERVER, DV_VERSION_SERVER);
end;

function TVVStartupConfig.GetRemoteRepositoryPath : string;
    //local para baixar todos os arquivos
begin
    Result := Self.ReadStringDefault(IE_REMOTE_REPOSITORY, DV_REMOTE_REPOSITORY);
    if (SameText(Result, DV_REMOTE_REPOSITORY)) then begin
        Result := Self.LocalUNC;
    end;
end;

function TVVStartupConfig.GetRootBaseConfigFilename : string;
begin
    if (not Self.IsPrimaryPC) then begin
        raise Exception.Create('Atributo acessível apenas por máquinas primárias');
    end;
    Result := VERSION_URL_FILE;
end;

function TVVStartupConfig.GetSenderAddress : string;
begin
    {TODO -oroger -cfuture : manifestas a criar }
    Result := Self.ReadStringDefault('SenderAddress', 'sesop@tre-pb.gov.br');
end;

function TVVStartupConfig.GetSenderDescription : string;
begin
    {TODO -oroger -cfuture : manifestas a criar }
    Result := Self.ReadStringDefault('SenderDescription', 'SESOP - Seção de Suporte Operacional');
end;

procedure TVVStartupConfig.InitDownloader;
begin
    Self.FHTTPLoader := TIdHTTP.Create(nil);
    Self.FHTTPLoader.AllowCookies := True;
    Self.FHTTPLoader.ProxyParams.BasicAuthentication := False;
    Self.FHTTPLoader.ProxyParams.ProxyPort := 0;
    Self.FHTTPLoader.Request.ContentLength := -1;
    Self.FHTTPLoader.Request.Accept := 'text/html, */*';
    Self.FHTTPLoader.Request.BasicAuthentication := False;
    Self.FHTTPLoader.Request.UserAgent := 'Mozilla/3.0 (compatible; Indy Library)';
    Self.FHTTPLoader.HTTPOptions := [hoForceEncodeParams];
end;

procedure TVVStartupConfig.InitInfoVersions(const filename : string);
{{
Rotina de inicialização para a carga dos parametros iniciais e perfil associado
}
begin
    LoadGlobalInfo(Filename);
end;

function TVVStartupConfig.LoadHTTPContent(const URL, DestFilename : string) : boolean;
var
    MemStream :  TMemoryStream;
    FileStream : TFileStream;
begin
    Result := False;
    try
        MemStream := TMemoryStream.Create;
        try
            try
                Self.FHTTPLoader.Get(url, MemStream);
            except
                on E : Exception do begin //Verifica possibilidade de uso do arquivo localmente disposto
                    Exit;
                end;
            end;
            //Verifica a escrita para atualizar informações de versões
            MemStream.Position := 0;
            if not TFileHnd.IsWritable(DestFilename) then begin
                ForceDirectories(TFileHnd.ParentDir(DestFilename));
                if (not TFileHnd.IsWritable(DestFilename)) then begin
                    Exit;
                end;
            end;
            if FileExists(DestFilename) then begin
                FileStream := TFileStream.Create(DestFilename, fmOpenWrite);
            end else begin
                FileStream := TFileStream.Create(DestFilename, fmCreate);
            end;
            try
                MemStream.SaveToStream(FileStream);
            finally
                FileStream.Free;
            end;
        finally
            MemStream.Free;
        end;
    except
        on E : Exception do begin
            raise Exception.CreateFmt('Erro lendo recurso externo(%s) para %s'#13#10'%s', [url, DestFilename, E.Message]);
        end;
    end;
end;

function TVVStartupConfig.ToString : string;
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

{ TVVProgInfo }

constructor TVVProfileInfo.Create(const Filename, AKeyPrefix : string);
var
    progs : TStringList;
    x :     Integer;
    Desc, Hive, VerKey, VerKeyEx, ExpectedVer, ExpectedVerEx, DURL : string;
    prg :   TProgItem;
begin
    inherited;
    Self.FProgList := TObjectList.Create;
    Self.FProgList.OwnsObjects := True;
    progs := TStringList.Create;
    try
        Self.FIni.ReadSections(progs);
        for x := 0 to progs.Count - 1 do begin
            //Descrição e nome da seção(não pode começar com "@" )
            Desc     := progs.Strings[x];
            //nome da chave para acesso aos atributos
            Hive     := Self.FIni.ReadString(Desc, 'hive', '');
            //Entrada da versão simples
            VerKey   := Self.FIni.ReadString(Desc, 'Entry1', '');
            //Entrada da versão detalhada
            VerKeyEx := Self.FIni.ReadString(Desc, 'Entry2', '');
            //Entrada do valor esperado para a versão simples
            ExpectedVer := Self.FIni.ReadString(Desc, 'Expected1', '');
            //Entrada do valor esperado para a versão detalhada
            ExpectedVerEx := Self.FIni.ReadString(Desc, 'Expected2', '');
            //Caminho do download para atualizar/instalar
            DURL     := Self.FIni.ReadString(Desc, 'URL', '');
            prg      := TProgItem.Create(Desc, Hive, VerKey, VerKeyEx, ExpectedVer, ExpectedVerEx, DURL);
            Self.FProgList.Add(prg);
        end;
    finally
        progs.Free;
    end;
end;

function TVVProfileInfo.GetPrograms(index : Integer) : TProgItem;
begin
    Result := TProgItem(Self.FProgList.Items[index]);
end;

destructor TVVProfileInfo.Destroy;
var
    tmpDir : string;
begin
    //Testa se arquivo foi gerado em temporario
    tmpDir := FileHnd.GetTempDir;
    if TStrHnd.startsWith(Self.FIni.FileName, tmpDir) then begin
        DeleteFile(PWideChar(Self.FIni.FileName));
    end;
    inherited;
end;

function TVVProfileInfo.GetCount : Integer;
begin
    Result := Self.FProgList.Count;
end;

end.
