{$IFDEF fuConfiguration}
		  {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuConfiguration;

interface

uses
    SysUtils, Classes, XMLDoc, XMLIntf, Forms, AppSettings, fuFileOperation;

type
    TFUConfig = class(AppSettings.TXMLBasedSettings)
    private
        FFileOperations : TFUFileOperations;
        function GetFileOperations : TFUFileOperations;
    public
        property FileOperations : TFUFileOperations read GetFileOperations;
		 class function CreateFromFile(const Filename, RootNodeName : string) : TFUConfig; reintroduce;
		 destructor Destroy; override;
		 procedure ReadOperations;
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
    if (not FileExists(filename)) then begin
        xmlDoc := TXMLBasedSettings.CreateEmptyXMLFile(filename);
        xmlDoc.Free;
    end;
    GlobalConfig := TFUConfig.CreateFromFile(filename, '');
end;


{ TFUConfig }

class function TFUConfig.CreateFromFile(const Filename, RootNodeName : string) : TFUConfig;
begin
    Result := TFUConfig(inherited CreateFromFile(Filename, RootNodeName));
    Result.FFileOperations := TFUFileOperations.Create(True);
end;

destructor TFUConfig.Destroy;
begin
	Self.FFileOperations.Free;
	inherited;
end;

function TFUConfig.GetFileOperations : TFUFileOperations;
begin
	Result:=Self.FFileOperations;
end;

procedure TFUConfig.ReadOperations;
 ///Varre configuração e carrega as operations a serem realizadas
 ///
var
	 x :    Integer;
	 lst :  TStringList;
	 fo : TFUFileOperation;
begin
	 lst := TStringList.Create;
	 try
		 Self.ListSubKeys('Operations', lst); //todas do raiz de configuração
		 for x := 0 to lst.Count - 1 do begin
			fo:=TFUFileOperation.Create( lst.Strings[ x ] );
           fo.SourcePath:=Self.ReadStringDefault( lst.Strings[ x ] + '\SourcePath', 'D:\' );
			Self.FFileOperations.Add( fo );
		 end;
	 finally
		 lst.Free;
	 end;
end;

initialization
    begin
        //InitGlobalConfig;
    end;

finalization
    begin
       //FreeAndNil(GlobalConfig);
    end;

end.
