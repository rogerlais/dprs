unit sqdbcConfig;

interface

uses
    SysUtils, AppSettings;

type
    TSQConvConfig = class(TBaseStartSettings)
    private
        function GetDestDir : string;
        function GetSourceDir : string;
    published
    public
        property SourceDir : string read GetSourceDir;
        property DestDir : string read GetDestDir;
    end;

var
    GlobalConfig : TSQConvConfig;

implementation

uses
    FileHnd;


procedure InitConfig();
begin
    GlobalConfig := TSQConvConfig.Create(ChangeFileExt(ParamStr(0), '.ini'));
end;

procedure FinalizeConfig();
begin
    FreeAndNil(GlobalConfig);
end;


{ TSQConvConfig }

function TSQConvConfig.GetDestDir : string;
begin
    Result := Self.ReadStringDefault('DestDir', GetCurrentDir());
end;

function TSQConvConfig.GetSourceDir : string;
begin
    Result := Self.ReadStringDefault('SourceDir', TFileHnd.ConcatPath([GetCurrentDir(), 'HTML Questions']));
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
