unit fuConfiguration;

interface

uses
    SysUtils, Classes, XMLDoc, XMLIntf, Forms, AppSettings, fuFileOperation;

type
	 TFUConfig = class(AppSettings.TXMLBasedSettings)
	 private
		 FFileOperations : TFUFileOperations;
    	function GetFileOperations: TFUFileOperations;
	 public
		 property FileOperations : TFUFileOperations read GetFileOperations;
		 class function CreateFromFile( const Filename, RootNodeName : string ) :  TFUConfig; reintroduce;
	 end;

var
    GlobalConfig : TFUConfig;

implementation

uses
	 FileHnd;

procedure InitGlobalConfig();
var
	 filename : string;
	 xmlDoc :   TXMLDocument;
begin
	 filename := TFileHnd.ChangeFileName(ParamStr(0), 'Config.xml');
	 if ( not FileExists( filename  ) ) then begin
		xmlDoc := TXMLBasedSettings.CreateEmptyXMLFile(filename);
		xmlDoc.Free;
	 end;
	 GlobalConfig:=TFUConfig.CreateFromFile( filename, '' );
end;


{ TFUConfig }

class function TFUConfig.CreateFromFile(const Filename, RootNodeName: string): TFUConfig;
begin
  Result:=	TFUConfig( inherited CreateFromFile( Filename, RootNodeName ) );
  Result.FFileOperations:= TFUFileOperations.Create(True);
end;

function TFUConfig.GetFileOperations: TFUFileOperations;
begin

end;

initialization
    begin
    	 InitGlobalConfig;
    end;

finalization
    begin
        FreeAndNil(GlobalConfig);
    end;

end.
