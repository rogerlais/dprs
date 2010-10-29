{$IFDEF vvConfig}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvConfig;

interface

uses
    Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, WinReg32;

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
        function GetCurrentVersion : string;
        function GetExpectedVerEx : string;
        function GetIsUpdated : boolean;
        function GetCurrentVersionEx : string;
        function ReadVersionEntry(const Entry : string) : string;
        function GetCurrentVersionDisplay : string;
    public
        constructor Create(const ADesc, AHive, AVerKey, AVerKeyEx, AExpectedVer, AExpectedVerEx : string);
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
        FProfileInfo : TVVProgInfo;
        FProfileName : string;
        function GetGlobalStatus : string;
        function GetInfoText : string;
        function GetAutoMode : boolean;
        function GetNotificationList : string;
		 function GetSenderAddress: string;
		 function GetSenderDescription: string;
    function GetEnsureNotification: boolean;
	 public
		 constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
		 destructor Destroy; override;
		 property GlobalStatus : string read GetGlobalStatus;
		 property InfoText : string read GetInfoText;
		 property ProfileInfo : TVVProgInfo read FProfileInfo;
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
    WinNetHnd, StrHnd, TREUtils, vvMainDataModule, FileInfo;

procedure LoadGlobalInfo(const Filename : string);
begin
    GlobalInfo := TVVConfig.Create(filename, 'VVer');
end;

{ TVVInfo }

constructor TVVConfig.Create(const FileName, AKeyPrefix : string);
var
    profileFilename, profileURL : string;
    compId : Integer;
begin
    inherited;
    //Identifica o perfil baseado no ordinal do nome do computador. Para id > 10 -> PCT, cc máquina zona
	 {$IFDEF DEBUG}
	 compId:=TTREUtils.GetComputerId( 'ZPB999PDC201' );
	 {$ELSE}
	 try
	 compId := TTREUtils.GetComputerId(GetComputerName());
	 except
		on E: Exception do begin
			compId:=-1;
		end;
	 end;
	 {$ENDIF}

	 if compId >= 10 then begin //Assume-se PCT
		 Self.FProfileName := 'PCT';
	 end else begin //Assume-se Maquina zona ou fora do padra
		 if compId < 0 then begin
			Self.FProfileName:='Outros';
		 end else begin
			Self.FProfileName := 'ZE';
		 end;
    end;
    profileURL      := Self.ReadString('Profiles\' + Self.ProfileName + '\VerInfo');
    profileFilename := dtmdMain.LoadURL(profileURL);
    //Buscar a entrada correta para a URL do perfil
    Self.FProfileInfo := TVVProgInfo.Create(profileFilename);
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

function TVVConfig.GetEnsureNotification: boolean;
var
  enDefault: TDefaultSettingValue;
begin
	enDefault := TDefaultSettingValue.Create();
	try
		enDefault.AsBoolean:=False;
		Result:=Self.ReadBoolean('EnsureNotification', enDefault );
	finally
		enDefault.Free;
	end;
end;

function TVVConfig.GetGlobalStatus : string;
var
    x : Integer;
begin
    Result := 'OK';
    for x := 0 to Self.FProfileInfo.Count - 1 do begin
        if not Self.FProfileInfo.Programs[x].isUpdated then begin
            Result := 'Pendente';
            Exit;
        end;
    end;
end;

function TVVConfig.GetInfoText : string;
var
    x : Integer;
    p : TProgItem;
begin
    Result := 'Resumo da verficação das versões'#13#10;
    Result := Result + 'Computador: ' + WinNetHnd.GetComputerName();
    for x := 0 to Self.FProfileInfo.Count - 1 do begin
        Result := Result + #13#10;
        p      := Self.FProfileInfo.Programs[x];
        Result := Result + 'Sistema: ' + p.Desc + #13#10;
        Result := Result + 'Versão instalada: ' + p.CurrentVersion + #13#10;
        Result := Result + 'Versão esperada: ' + p.ExpectedVerEx + #13#10;
        if p.isUpdated then begin
            Result := Result + 'Situação: Atualizado'#13#10;
        end else begin
            Result := Result + 'Situação: Pendente'#13#10;
        end;
    end;
end;

function TVVConfig.GetNotificationList : string;
begin
	{TODO -oroger -cfuture : manifestas a criar }
	 Result := Self.ReadString('NotificationList');
end;

function TVVConfig.GetSenderAddress: string;
begin
	{TODO -oroger -cfuture : manifestas a criar }
	Result:=Self.ReadStringDefault('SenderAddress', 'sesop@tre-pb.gov.br' );
end;

function TVVConfig.GetSenderDescription: string;
begin
	{TODO -oroger -cfuture : manifestas a criar }
	Result:=Self.ReadStringDefault('SenderDescription', 'SESOP - Seção de Suporte Operacional' );
end;

{ TProgItem }

constructor TProgItem.Create(const ADesc, AHive, AVerKey, AVerKeyEx, AExpectedVer, AExpectedVerEx : string);
begin
    Self.FUpdateStatus := usUnknow;
    Self.FVerKey   := AVerKey;
    Self.FExpectedVerEx := AExpectedVerEx;
    Self.FExpectedVer := AExpectedVer;
    Self.FHive     := AHive;
    Self.FDesc     := ADesc;
    Self.FVerKeyEx := AVerKeyEx;
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
		 if FileInfo.TVersionInfo.CompareTo( Self.CurrentVersion, Self.ExpectedVerEx   ) <= 0  then begin
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
    Desc, Hive, VerKey, VerKeyEx, ExpectedVer, ExpectedVerEx : string;
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
            prg      := TProgItem.Create(Desc, Hive, VerKey, VerKeyEx, ExpectedVer, ExpectedVerEx);
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
