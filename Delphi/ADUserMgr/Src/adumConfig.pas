{$IFDEF adumConfig}
	{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I ADUserMgr.inc}

unit adumConfig;

interface

uses
    SysUtils, AppSettings;

type
    TADUMConfig = class(TBaseStartSettings)
    private
        function GetDBPassword : string;
        function GetDBUserName : string;
        function GetServerName : string;
        procedure SetDBPassword(const Value : string);
        procedure SetDBUserName(const Value : string);

    protected

    public
        property ServerName : string read GetServerName;
        property DBUserName : string read GetDBUserName write SetDBUserName;
        property DBPassword : string read GetDBPassword write SetDBPassword;
    end;


var
   GlobalConfig : TADUMConfig = nil;

implementation

uses
    FileHnd;

{ TADUMConfig }


procedure InitConfig;
var
   fname : string;
begin
     fname:=ParamStr(0);
     fname:= SysUtils.ChangeFileExt( fname, '.ini' );
     GlobalConfig :=TADUMConfig.Create( fname, 'ADUM\1.0' );
end;


function TADUMConfig.GetDBPassword : string;
begin
    {TODO -oroger -cdsg : Leitura da senha do arquivo de configuração de forma criptografada}
    Result:='desenv';
end;

function TADUMConfig.GetDBUserName : string;
begin
    {TODO -oroger -cdsg : Leitura do nome da conta de acesso ao banco de dados de forma criptografada }
    Result:='desenv';
end;

function TADUMConfig.GetServerName : string;
begin
     {TODO -oroger -cdsg : Recupera nome do servidor com }
     Result:='localhost';
end;

procedure TADUMConfig.SetDBPassword(const Value : string);
begin

end;

procedure TADUMConfig.SetDBUserName(const Value : string);
begin

end;


initialization
begin
     InitConfig;
end;

finalization
begin
     FreeAndNil( GlobalConfig );
end;


end.
