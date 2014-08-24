{$IFDEF vvsFileMgmt}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsFileMgmt;

interface

uses
    Windows, SysUtils, FileHnd, Generics.Collections, StreamHnd, XPFileEnumerator, Classes;


type
    TVVSFile = class
    private
        _MD5String : string;
        FFilename :  string;
        function GetMD5String : string;
        function GetLastWrite : TDateTime;
    public
        constructor Create(const FullFilename : string);
        procedure Refresh;
        property Filename : string read FFilename;
        property MD5String : string read GetMD5String;
        property LastWrite : TDateTime read GetLastWrite;
    end;

    TManagedFolder = class(TDictionary<string, TVVSFile>)
    private
        FRootDir : string;
        function GetGlobalHash : string;
    protected

    public
        constructor Create(ARootDir : string);
        property GlobalHash : string read GetGlobalHash;
        procedure Reload;
    end;


implementation

uses
    BinHnd;

{ TVVSFile }

constructor TVVSFile.Create(const FullFilename : string);
begin
    Self.FFilename := FullFilename;
end;

function TVVSFile.GetLastWrite : TDateTime;
begin
    Result := TFileHnd.FileTimeChangeTime(Self.FFilename);
end;

function TVVSFile.GetMD5String : string;
begin
    if (Self._MD5String = EmptyStr) then begin
        Self._MD5String := THashHnd.MD5(Self.FFilename);
    end;
    Result := Self._MD5String;
end;

procedure TVVSFile.Refresh;
begin

end;

{ TManagedFolder }

constructor TManagedFolder.Create(ARootDir : string);
begin
    inherited Create;
    Self.FRootDir := ARootDir;
    Self.Reload;
end;

function TManagedFolder.GetGlobalHash : string;
var
    vf :  TVVSFile;
    lst : TStringList;
begin
    lst := TStringList.Create;
	 try
		lst.Sorted:=True; //aumenta a unicidade
		 for vf in Self.Values do begin
			lst.add( vf.MD5String );
		 end;
		 Result := Lst.Text;
    finally
        lst.Free;
    end;

end;

procedure TManagedFolder.Reload;
 ///
 /// Apaga todas as entradas e remonta estrutura
 ///
 ///
var
    vf :     TVVSFile;
    IFiles : IEnumerable<string>;
    f :      string;
begin
    Self.Clear; //Limpa tudo!!!!!
    IFiles := TDirectory.Entries(Self.FRootDir, '*.*', True, True);
    for f in IFiles do begin
        vf := TVVSFile.Create(f);
        Self.Add(vf.Filename, vf);
    end;
end;

end.
