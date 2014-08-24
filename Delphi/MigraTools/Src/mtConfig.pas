{$IFDEF mtConfig}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtConfig;

interface

uses
    Classes, SysUtils, TREConsts, TREConfig, AppSettings, FileHnd, AppLog;

var
    GlobalConfig : TTREBaseConfig;


implementation

procedure InitConfig;
var
    path : string;
    AutoMode : boolean;
    x : Integer;
begin
	AutoMode:=False;
    for x := 0 to ParamCount do begin
        AutoMode := SameText('/auto', ParamStr(x));
        if AutoMode then    begin
            Break;
        end;
    end;
    try
        path := ExtractFilePath(ParamStr(0));
        path := TFileHnd.ConcatPath([path, TRE_DV_CONFIG_FILENAME]);
		 GlobalConfig := TTREBaseConfig.Create(path);
		 AppLog.TLogFile.GetDefaultLogFile.DebugLevel := GlobalConfig.DebugLevel;
    except
        on E : Exception do begin
			 AppFatalError(E.Message, 1, not AutoMode);
        end;
    end;
end;


initialization
    begin
        InitConfig();
    end;

end.
