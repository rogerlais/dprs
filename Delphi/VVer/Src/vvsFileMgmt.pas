{$IFDEF vvsFileMgmt}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I VVERSvc.inc}

unit vvsFileMgmt;

interface

uses
    Windows, SysUtils, FileHnd, Generics.Collections, StreamHnd, XPFileEnumerator, Classes, WinFileNotification,
    XMLIntf, XMLConst, SyncObjs, DBXJSON, DBXJSONReflect;

type
     {$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublished]) FIELDS([vcPrivate])}
    TVVSFile = class
    private
        _MD5String : string;
        FFilename :  string;
        function GetMD5String : string;
        function GetLastWrite : TDateTime;
    public
        constructor Create(const FullFilename : string);
        procedure Refresh;
		 function ToString() : string;
        property Filename : string read FFilename;
        property MD5String : string read GetMD5String;
        property LastWrite : TDateTime read GetLastWrite;
    end;

    TManagedFolder = class(TDictionary<string, TVVSFile>)
    private
        FCriticalSection : TCriticalSection;
        FRootDir :         string;
        FMonitor :         TWinFileSystemMonitor;
        function GetGlobalHash : string;
        function GetMonitored : boolean;
        procedure SetMonitored(const Value : boolean);
        procedure DoFilesChange(Sender : TWinFileSystemMonitor; AFolderItem : TFolderItemInfo);
    protected
        procedure Lock;
        procedure UnLock;
    public
        constructor CreateLocal(const ARootDir : string);
        constructor CreateRemote(const AData : string);
		 destructor Destroy; override;
		 property Monitored : boolean read GetMonitored write SetMonitored;
		 procedure Reload;
		 function ToString() : string; override;
	 end;


implementation

uses
	 BinHnd, Str_pas, StrHnd, jclAnsiStrings;


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

function TVVSFile.ToString : string;
var
    m : TJSONMarshal;
    AsString : TJSONObject;  //Serialized for of object
begin
    m := TJSONMarshal.Create(TJSONConverter.Create);
	 try
		m.RegisterConverter( Self.ClassType, 'FFilename', function(Data: TObject; Field: string): string
		var
			v : string;
		begin
			v:=TVVSFile( Data ).FFilename;
			{$IF CompilerVersion <> 21.00}
			//Para esta versão havia erro na recuperação da cadeia contendo caracter "\"
			---***** A linha abaixo deve ser revista de acordo com a implementação json do compilador
			{$IFEND}
			Result := jclAnsiStrings.StrStringToEscaped( v );
		end
		);
        AsString := TJSONObject(m.Marshal(self));
        Result   := AsString.ToString;
    finally
        m.Free;
    end;
end;

{ TManagedFolder }

constructor TManagedFolder.CreateLocal(const ARootDir : string);
begin
    inherited Create;
    Self.FCriticalSection := TCriticalSection.Create;
    Self.FRootDir := ARootDir;
    Self.Reload;
end;

constructor TManagedFolder.CreateRemote(const AData : string);
var
    f :     TVVSFile;
    Lines : TStringList;
    s :     string;
    unm :   TJSONUnMarshal;
    SerialFile : TJSONObject;  //Serialized for of object
    buf :   TBytes;
    jPair : TJSONPair;
begin
    inherited Create;
    Self.FCriticalSection := TCriticalSection.Create;
    Lines := TStringList.Create();
    try
        unm := TJSONUnMarshal.Create();
        try
            Lines.Text := AData;
            for s in Lines do begin
				 try
					 SerialFile := TJSONObject.Create;
					 //SerialFile.Parse (TEncoding.ASCII.GetBytes(s), 0);
					 SerialFile.Parse (TEncoding.UTF8.GetBytes(s), 0);
					 f := unm.Unmarshal(SerialFile) as TVVSFile;
					 Self.Add(f.Filename, f);
                finally
                    SerialFile.Free;
                end;
            end;
        finally
            unm.Free;
        end;
    finally
        Lines.Free;
    end;
end;

destructor TManagedFolder.Destroy;
begin
    FreeAndNil(Self.FMonitor);
    Self.FCriticalSection.Free;
    inherited;
end;

procedure TManagedFolder.DoFilesChange(Sender : TWinFileSystemMonitor; AFolderItem : TFolderItemInfo);
var
    vf : TVVSFile;
begin
    Self.Lock();
    try
        {TODO -oroger -cdsg : identifica a mudanca e recarrega dados do arquivo}
        case AFolderItem.Action of
            faNew : begin
                vf := TVVSFile.Create(AFolderItem.Name);
                Self.Add(AFolderItem.Name, vf);
            end;
            faRemoved : begin
                Self.Remove(AFolderItem.Name); {TODO -oroger -cdsg : Validar destructor do vf nesta chamada}
            end;
            faModified : begin
                vf.Refresh;
            end;
            faRenamedOld : begin
                Self.Remove(AFolderItem.Name); {TODO -oroger -cdsg : Validar destructor do vf nesta chamada}
            end;
            faRenamedNew : begin
                vf := TVVSFile.Create(AFolderItem.Name);
                Self.Add(AFolderItem.Name, vf);
            end;
        end;
    finally
        Self.UnLock;
    end;
end;

function TManagedFolder.GetGlobalHash : string;
var
    vf :  TVVSFile;
    lst : TStringList;
begin
    lst := TStringList.Create;
    try
        lst.Sorted := True; //aumenta a unicidade
        for vf in Self.Values do begin
            lst.add(vf.MD5String);
        end;
        Result := Lst.Text;
    finally
        lst.Free;
    end;

end;

function TManagedFolder.GetMonitored : boolean;
begin
    if (Assigned(Self.FMonitor)) then begin
        Result := Self.FMonitor.IsActive;
    end else begin
        Result := False;
    end;
end;

procedure TManagedFolder.Lock;
begin
    Self.FCriticalSection.Acquire;
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
    Self.Lock;
    try
        Self.Clear; //Limpa tudo!!!!!
        IFiles := TDirectory.Entries(Self.FRootDir, '*.*', True, True);
        for f in IFiles do begin
            vf := TVVSFile.Create(f);
            Self.Add(vf.Filename, vf);
        end;
    finally
        self.UnLock;
    end;
end;

procedure TManagedFolder.SetMonitored(const Value : boolean);
begin
    if (Value) then begin
        if (not Assigned(Self.FMonitor)) then begin
            Self.FMonitor := TWinFileSystemMonitor.Create(nil);
            Self.FMonitor.Folder := Self.FRootDir;
            Self.FMonitor.MonitoredChanges := [ctFileName, ctDirName, ctSize, ctLastWriteTime, ctCreationTime];
            Self.FMonitor.Recursive := True;
            Self.FMonitor.OnFolderChange := Self.DoFilesChange;
            Self.FMonitor.IsActive := Value;
        end;
    end else begin
        FreeAndNil(Self.FMonitor);
    end;
end;

function TManagedFolder.ToString : string;
var
    x : Integer;
    f : TVVSFile;
begin
    Result := EmptyStr;
    for f in Self.Values do begin
        Result := Result + f.ToString() + #13#10;
    end;
end;

procedure TManagedFolder.UnLock;
begin
    Self.FCriticalSection.Release;
end;

end.
