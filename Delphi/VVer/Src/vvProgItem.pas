unit vvProgItem;


interface

uses
    SysUtils, Classes;

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

implementation

uses
    FileHnd, WinReg32, FileInfo, Windows, AppLog;


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
    try
        Result := Self.CurrentVersionEx;
        if Result = EmptyStr then begin
            Result := 'Não identificada';
        end;
    except
        on E : Exception do begin
            TLogFile.LogDebug('Leitura da informação falhou' + E.Message, DBGLEVEL_NONE);
        end;
    end;
end;

function TProgItem.GetCurrentVersionEx : string;
var
    Entry : string;
begin
    if (Self._CurrentVersionEX = EmptyStr) then begin
        Entry := TFileHnd.ConcatPath([Self.FHive, Self.FVerKeyEx]);

        TLogFile.LogDebug('Lendo ' + Self.FHive + '  e ' + Self.FVerKeyEx, DBGLEVEL_NONE);

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
		if ( not reg.ReadFullString( Entry, Result )) then begin
       	TLogFile.Log( 'Erro lendo entrada: ' + Entry + #13#10 + SysErrorMessage( GetLastError ) );
		end;
	 finally
		 Self._CurrentVersion := Result;
        reg.Free;
    end;
end;


end.
