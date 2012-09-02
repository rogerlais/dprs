unit mrfConfiguration;

interface

uses
    Windows, Classes, SysUtils, AppSettings, FileHnd;

type
    TMRFSettings = class(AppSettings.TBaseStartSettings)
    private
        FSignatureList : TStringList;

    public
        destructor Destroy; override;
        function CheckSignatureList(const DeviceId : string) : boolean;
    end;

var
    GlobalConfig : TMRFSettings;

implementation

{ TMRFSettings }

procedure InitConfig();
begin
	 GlobalConfig := TMRFSettings.Create(
		ChangeFileExt(ParamStr(0), '.ini'),
		ExtractFileName( ChangeFileExt( ParamStr(0), '' )) );
end;

procedure CleanupConfig();
begin
	 FreeAndNil(GlobalConfig);
end;

function TMRFSettings.CheckSignatureList(const DeviceId : string) : boolean;
begin
	 {TODO -oroger -cdsg : Varre a lista de assinaturas de dispositivos para validar o questionado}
	 if (not Assigned(Self.FSignatureList)) then begin
		 Self.FSignatureList := TStringList.Create;
		 Self.FSignatureList.Delimiter:=';';
		 Self.FSignatureList.StrictDelimiter:=True;
		 Self.FSignatureList.DelimitedText := Self.ReadStringDefault('PermDeviceString', EmptyStr);
	 end;
	 Result := (Self.FSignatureList.IndexOf(DeviceId) >= 0);
end;

destructor TMRFSettings.Destroy;
begin
	 if (Assigned(Self.FSignatureList)) then begin
        FreeAndNil(Self.FSignatureList);
    end;
    inherited;
end;

initialization
    begin
        InitConfig();
    end;

finalization
    begin
        CleanupConfig();
    end;

end.
