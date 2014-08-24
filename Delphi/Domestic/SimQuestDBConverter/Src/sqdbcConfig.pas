unit sqdbcConfig;

interface

uses
    SysUtils, AppSettings;

type
    TSQConvConfig = class(TBaseStartSettings)
    private
        function GetDestDir : string;
        function GetSourceDir : string;
        procedure SetDestDir(const Value : string);
        procedure SetSourceDir(const Value : string);
    published
    public
        property SourceDir : string read GetSourceDir write SetSourceDir;
        property DestDir : string read GetDestDir write SetDestDir;
    end;

var
    GlobalConfig : TSQConvConfig;

implementation

uses
    FileHnd;

resourcestring
    StrDestDir   = 'DestDir';
    StrSourceDir = 'SourceDir';


procedure InitConfig();
begin
	 GlobalConfig := TSQConvConfig.Create(ChangeFileExt(ParamStr(0), '.ini'), 'SQConverter' );
end;

procedure FinalizeConfig();
begin
    FreeAndNil(GlobalConfig);
end;


{ TSQConvConfig }

function TSQConvConfig.GetDestDir : string;
begin
    Result := Self.ReadStringDefault(StrDestDir, GetCurrentDir());
end;

function TSQConvConfig.GetSourceDir : string;
begin
    Result := Self.ReadStringDefault(StrSourceDir, TFileHnd.ConcatPath([GetCurrentDir(), 'HTML Questions']));
end;

procedure TSQConvConfig.SetDestDir(const Value : string);
begin
    Self.WriteString(StrDestDir, Value);
end;

procedure TSQConvConfig.SetSourceDir(const Value : string);
begin
    Self.WriteString(StrSourceDir, Value);
end;

initialization
    begin
        InitConfig();
    end;

finalization
    begin
        FinalizeConfig();
    end;

end.
