{$IFDEF gvUtils}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I GPO2VPN.inc}


unit gvUtils;

interface

uses
    Classes, SysUtils, Windows, Graphics, FileHnd;

type
    TGPOVPNController = class
    private
        FTempDir : string;
    public
        constructor Create(const ATempDir : string);
        destructor Destroy; override;
        function ExpandResource(const DestPath : string) : Integer;
        function RunCommand(const Cmd : string) : Integer;
    end;

implementation

{ TGPOVPNController }

constructor TGPOVPNController.Create(const ATempDir : string);
begin
    inherited Create;
    Self.FTempDir := ATempDir;
end;

destructor TGPOVPNController.Destroy;
begin
    //Limpar pasta temporaria
    TFileHnd.RmDir(Self.FTempDir);
    inherited;
end;

function TGPOVPNController.ExpandResource(const DestPath : string) : Integer;
var
    Stream : TCustomMemoryStream;
begin
    Stream := TResourceStream.Create(HInstance, 'FULL_GPO_PACKAGE', RT_RCDATA);
    try
        ForceDirectories(Self.FTempDir);
        Stream.SaveToFile(TFileHnd.ConcatPath([Self.FTempDir, 'temp.7z']));
    finally
        Stream.Free;
    end;
end;

function TGPOVPNController.RunCommand(const Cmd : string) : Integer;
begin

end;

end.
