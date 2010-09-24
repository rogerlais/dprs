{$IFDEF vvConfig}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVer.inc}
{$TYPEINFO OFF}

unit vvConfig;

interface

uses
    Classes, SysUtils, Windows, FileHnd, AppSettings, Contnrs, WinReg32;

const
	VERSION_URL_FILE = 'http://dcsesop/suporte/AppData/VVer/VVer.ini';
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
        function GetCurrentVersion : string;
        function GetExpectedVerEx : string;
        function GetIsUpdated : boolean;
    public
        constructor Create(const ADesc, AHive, AVerKey, AVerKeyEx, AExpectedVer, AExpectedVerEx : string);
        property Desc : string read FDesc;
        property Hive : string read FHive;
        property VerKey : string read FVerKey;
        property VerKeyEx : string read FVerKeyEx;
        property ExpectedVer : string read FExpectedVer;
        property ExpectedVerEx : string read GetExpectedVerEx;
        property CurrentVersion : string read GetCurrentVersion;
        property isUpdated : boolean read GetIsUpdated;
        property UpdateStatus : TVVUpdateStatus read FUpdateStatus;
    end;

    TVVInfo = class(TBaseStartSettings)
	 private
		 FProgList : TObjectList;
		 function GetItems(index : Integer) : TProgItem;
		 function GetProgCount : Integer;
		 function GetGlobalStatus : string;
		 function GetInfoText : string;
	 public
		 constructor Create(const FileName : string; const AKeyPrefix : string = ''); override;
		 property Items[index : Integer] : TProgItem read GetItems;
		 property ProgCount : Integer read GetProgCount;
		 property GlobalStatus : string read GetGlobalStatus;
		 property InfoText : string read GetInfoText;
	 end;

	 procedure LoadGlobalInfo( const Filename : string );

var
	 GlobalInfo : TVVInfo = nil;

implementation

uses
	 WinNetHnd;

procedure LoadGlobalInfo( const Filename : string );
begin
	 GlobalInfo := TVVInfo.Create(filename);
end;

{ TVVInfo }

constructor TVVInfo.Create(const FileName, AKeyPrefix : string);
var
	 x :     Integer;
	 progs : TStringList;
	 VerKey, ExpectedVerEx, ExpectedVer, Hive, Desc, VerKeyEx : string;
	 prg :   TProgItem;
begin
	 inherited;
	 Self.FProgList := TObjectList.Create;
    Self.FProgList.OwnsObjects := True;
    progs := TStringList.Create;
    try
        Self.FIni.ReadSections(progs);
        for x := 0 to progs.Count - 1 do begin
            //Descrição e nome da seção
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

function TVVInfo.GetGlobalStatus : string;
var
    x : Integer;
begin
    Result := 'OK';
    for x := 0 to Self.FProgList.Count - 1 do begin
        if not TProgItem(Self.FProgList.Items[x]).isUpdated then begin
            Result := 'Pendente';
            Exit;
        end;
    end;
end;

function TVVInfo.GetInfoText : string;
var
    x : Integer;
    p : TProgItem;
begin
    Result := 'Resumo da verficação das versões'#13#10;
    Result := Result + 'Computador: ' + WinNetHnd.GetComputerName();
    for x := 0 to Self.FProgList.Count - 1 do begin
        Result := Result + #13#10;
        p      := TProgItem(Self.FProgList.Items[x]);
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

function TVVInfo.GetItems(index : Integer) : TProgItem;
begin
    Result := TProgItem(Self.FProgList.Items[index]);
end;

function TVVInfo.GetProgCount : Integer;
begin
    Result := Self.FProgList.Count;
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
    reg : TRegistryNT;
    veSimple, veDetail : string;
    ret : boolean;
begin
    {TODO -oroger -cdsg : Leitura das entrada svinculadas para retorno da versão instalada}
    if Self._CurrentVersion <> EmptyStr then begin
        Result := Self._CurrentVersion;
    end else begin
        Result := 'Não Identificada';
    end;
    reg := TRegistryNT.Create;
    try
        veSimple := TFileHnd.ConcatPath([Self.FHive, Self.FVerKey]);
        veDetail := TFileHnd.ConcatPath([Self.FHive, Self.FVerKeyEx]);
        if reg.FullKeyExists(veDetail) then begin
            ret := reg.ReadFullString(veDetail, Result);
        end else begin
            ret := reg.ReadFullString(veSimple, Result);
        end;
        if not ret then begin
            Result := 'Não identificada';
        end;
    finally
        Self._CurrentVersion := Result;
        reg.Free;
    end;
end;

function TProgItem.GetExpectedVerEx : string;
begin
    {TODO -oroger -cdsg : Para o caso de não atribuido vai o valor da versão simples}
    if Self.FExpectedVerEx <> EmptyStr then begin
        Result := Self.FExpectedVerEx;
    end else begin
        Result := Self.FExpectedVer;
    end;
end;

function TProgItem.GetIsUpdated : boolean;
begin
    {$IFDEF DEBUG}
	 if Self.FExpectedVer = '7.00' then begin
		 Self.FUpdateStatus := usOK;
	 end else begin
		 if Self.FUpdateStatus = usUnknow then begin
			 if SameText(Self.CurrentVersion, Self.ExpectedVerEx) then begin
				 Self.FUpdateStatus := usOK;
			 end else begin
				 Self.FUpdateStatus := usOld;
			 end;
		 end;
	 end;
	 Result := (Self.UpdateStatus = usOK);
	 {$ENDIF}

    {TODO -oroger -cdsg : Comparar o valor da versão atual com a esperada}
    if Self.FUpdateStatus = usUnknow then begin
        if SameText(Self.CurrentVersion, Self.ExpectedVerEx) then begin
            Self.FUpdateStatus := usOK;
        end else begin
            Self.FUpdateStatus := usOld;
        end;
    end;
    Result := (Self.UpdateStatus = usOK);
end;

end.
