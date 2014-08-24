{$IFDEF vvConfig}
     {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvConfig;

interface

uses
    Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, WinReg32, vvsConsts;

type
    TVVUpdateStatus = (usUnknow, usOld, usOK);

    TProgItem = class
    private
        FUpdateStatus :   TVVUpdateStatus;
        FVerKey :         string;
        FExpectedVerEx :  string;
        FExpectedVer :    string;
        FHive :           string;
        FDesc :           string;
        FVerKeyEx :       string;
        _CurrentVersion : string;
        _CurrentVersionEX : string;
        FDownloadURL :    string;
        function GetCurrentVersion : string;
        function GetExpectedVerEx : string;
        function GetIsUpdated : boolean;
        function GetCurrentVersionEx : string;
        function ReadVersionEntry(const Entry : string) : string;
        function GetCurrentVersionDisplay : string;
    public
        constructor Create(const ADesc, AHive, AVerKey, AVerKeyEx, AExpectedVer, AExpectedVerEx, ADownloadURL : string);
        property Desc : string read FDesc;
        property Hive : string read FHive;
        property VerKey : string read FVerKey;
        property VerKeyEx : string read FVerKeyEx;
        property ExpectedVer : string read FExpectedVer;
        property ExpectedVerEx : string read GetExpectedVerEx;
        property CurrentVersion : string read GetCurrentVersion;
        property CurrentVersionDisplay : string read GetCurrentVersionDisplay;
        property CurrentVersionEx : string read GetCurrentVersionEx;
        property isUpdated : boolean read GetIsUpdated;
        property UpdateStatus : TVVUpdateStatus read FUpdateStatus;
        property DownloadURL : string read FDownloadURL;
    end;

    TVVProgInfo = class(TBaseStartSettings)
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

    TVVConfig = class(TBaseStartSettings)
    private
        _ProfileInfo : TVVProgInfo;
        FProfileName : string;
        function GetGlobalStatus : string;
        function GetInfoText : string;
        function GetAutoMode : boolean;
        function GetNotificationList : string;
        function GetSenderAddress : string;
        function GetSenderDescription : string;
        function GetEnsureNotification : boolean;
        function GetProfileInfo : TVVProgInfo;
    public
        constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
        destructor Destroy; override;
        property GlobalStatus : string read GetGlobalStatus;
        property InfoText : string read GetInfoText;
        property ProfileInfo : TVVProgInfo read GetProfileInfo;
        property AutoMode : boolean read GetAutoMode;
        property ProfileName : string read FProfileName;
        property NotificationList : string read GetNotificationList;
        property SenderAddress : string read GetSenderAddress;
        property SenderDescription : string read GetSenderDescription;
        property EnsureNotification : boolean read GetEnsureNotification;
    end;

procedure LoadGlobalInfo(const Filename : string);

var
    GlobalInfo : TVVConfig = nil;

implementation

uses
    WinNetHnd, StrHnd, TREUtils, vvMainDataModule, FileInfo, TREConsts, JclSysInfo;

procedure LoadGlobalInfo(const Filename : string);
 ///Monta rotina de carga das configurações iniciais, na ordem:
 /// 1 - Arquivo local de onde serão carregados os dados remotos
 ///
 /// Máquina primária no caminho do repositório
begin
    {TODO -oroger -cdsg : Carga dinamica do arquivo de configurações do serviço}
    GlobalInfo := TVVConfig.Create(filename, 'VVer');
end;

{ TVVInfo }

constructor TVVConfig.Create(const FileName, AKeyPrefix : string);
    ///
    /// Cria e carrega o perfil deste computador de acordo com o nome do mesmo.
    /// Monta o nome prefixando o sistema operacional com o tipo da estação
var
    profileFilename, TargetName : string;
    ct : TTREComputerType;
begin
    {TODO -oroger -cdsg : Pegar o nome do perfil atraves do AD do controlador de domínio, exceto para os casos onde não houve o mesmo }
    {TODO -oroger -cdsg : Opção para o caso acima é contato com o servidor configurado para o serviço }
    inherited;
    //Identifica o perfil baseado no ordinal do nome do computador. Para id > 10 -> PCT, cc máquina zona
    if (System.DebugHook <> 0) then begin //Depurando na IDE
        TargetName := DBG_CLIENT_COMPUTERNAME;
    end else begin //Execução normal
        TargetName := GetComputerName();
    end;
    ct := TTREUtils.GetComputerTypeByName(TargetName);
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

destructor TVVConfig.Destroy;
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

function TVVConfig.GetAutoMode : boolean;
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

function TVVConfig.GetEnsureNotification : boolean;
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

function TVVConfig.GetGlobalStatus : string;
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

function TVVConfig.GetInfoText : string;
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

function TVVConfig.GetNotificationList : string;
begin
    {TODO -oroger -cfuture : manifestas a criar }
    Result := Self.ReadString('NotificationList');
end;

function TVVConfig.GetProfileInfo : TVVProgInfo;
var
    profileURL, SOProfilePrefix, profileFilename : string;
begin
    if (Assigned(Self._ProfileInfo)) then begin
        Result := Self._ProfileInfo;
        Exit;
    end;
    //Sufixa o perfil de acordo com o SO encontrado no cliente
    if (GetWindowsVersion() = wvWin7) then begin
        SOProfilePrefix := 'W7.';
    end else begin
        if (GetWindowsVersion() = wvWinXP) then begin
            SOProfilePrefix := 'XP.';
        end else begin
            //Resolver para caso de SO não identificado
            SOProfilePrefix := 'XP.';
        end;
    end;

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
        profileFilename   := dtmdMain.LoadURL(profileURL);
        //Buscar a entrada correta para a URL do perfil
        Self._ProfileInfo := TVVProgInfo.Create(profileFilename);
    end;
    Result := Self._ProfileInfo;
end;

function TVVConfig.GetSenderAddress : string;
begin
    {TODO -oroger -cfuture : manifestas a criar }
    Result := Self.ReadStringDefault('SenderAddress', 'sesop@tre-pb.gov.br');
end;

function TVVConfig.GetSenderDescription : string;
begin
    {TODO -oroger -cfuture : manifestas a criar }
    Result := Self.ReadStringDefault('SenderDescription', 'SESOP - Seção de Suporte Operacional');
end;

{ TProgItem }

constructor TProgItem.Create(const ADesc, AHive, AVerKey, AVerKeyEx, AExpectedVer, AExpectedVerEx, ADownloadURL : string);
begin
    Self.FUpdateStatus := usUnknow;
    Self.FVerKey   := AVerKey;
    Self.FExpectedVerEx := AExpectedVerEx;
    Self.FExpectedVer := AExpectedVer;
    Self.FHive     := AHive;
    Self.FDesc     := ADesc;
    Self.FVerKeyEx := AVerKeyEx;
    Self.FDownloadURL := ADownloadURL;
end;

function TProgItem.GetCurrentVersion : string;
var
    Entry : string;
begin
    if (Self._CurrentVersion = EmptyStr) then begin
        Entry := TFileHnd.ConcatPath([Self.FHive, Self.FVerKey]);
        Self._CurrentVersion := Self.ReadVersionEntry(Entry);
    end;
    Result := Self._CurrentVersion;
end;

function TProgItem.GetCurrentVersionDisplay : string;
begin
    Result := Self.CurrentVersionEx;
    if Result = EmptyStr then begin
        Result := 'Não identificada';
    end;
end;

function TProgItem.GetCurrentVersionEx : string;
var
    Entry : string;
begin
    if (Self._CurrentVersionEX = EmptyStr) then begin
        Entry := TFileHnd.ConcatPath([Self.FHive, Self.FVerKeyEx]);
        Self._CurrentVersionEX := Self.ReadVersionEntry(Entry);
        if Self._CurrentVersionEX = EmptyStr then begin
            Self._CurrentVersionEX := Self.CurrentVersion;
        end;
    end;
    Result := Self._CurrentVersionEX;
end;

function TProgItem.GetExpectedVerEx : string;
begin
    //Para o caso de não atribuido vai o valor da versão simples
    if Self.FExpectedVerEx <> EmptyStr then begin
        Result := Self.FExpectedVerEx;
    end else begin
        Result := Self.FExpectedVer;
    end;
end;

function TProgItem.GetIsUpdated : boolean;
begin
    //Comparar o valor da versão atual com a esperada
    if Self.FUpdateStatus = usUnknow then begin
        if FileInfo.TVersionInfo.CompareTo(Self.CurrentVersion, Self.ExpectedVerEx) <= 0 then begin
            Self.FUpdateStatus := usOK;
        end else begin
            Self.FUpdateStatus := usOld;
        end;
    end;
    Result := (Self.UpdateStatus = usOK);
end;

function TProgItem.ReadVersionEntry(const Entry : string) : string;
var
    reg : TRegistryNT;
begin
    //Leitura das entradas vinculadas para retorno da versão instalada
    reg := TRegistryNT.Create;
    try
        if not (reg.ReadFullString(Entry, Result)) then begin
            Result := EmptyStr;
        end;
    finally
        Self._CurrentVersion := Result;
        reg.Free;
    end;
end;

{ TVVProgInfo }

constructor TVVProgInfo.Create(const Filename, AKeyPrefix : string);
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

function TVVProgInfo.GetPrograms(index : Integer) : TProgItem;
begin
    Result := TProgItem(Self.FProgList.Items[index]);
end;

destructor TVVProgInfo.Destroy;
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

function TVVProgInfo.GetCount : Integer;
begin
    Result := Self.FProgList.Count;
end;

end.
