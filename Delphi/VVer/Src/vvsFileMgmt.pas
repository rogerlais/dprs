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
	  {-$RTTI EXPLICIT METHODS([]) PROPERTIES([vcPublished]) FIELDS([vcPrivate])}

	 TManagedFolder = class;
	 TVVSFile = class
	 private
		 _MD5String : string;
		 _LastWrite : TDateTime;
		 _Size : int64;
		 FFilename :  string;
		 [JSONMarshalled(false)] [JSONUnMarshalled(false)]
		 FParent : TManagedFolder;
		 function GetMD5String : string;
		 function GetLastWrite : TDateTime;
		 function GetSize: int64;
    	 function GetFullFilename: string;
    function GetFingerprints: string;
	 public
		 constructor Create(AParent : TManagedFolder ; const AFilename : string);
		 procedure Refresh;
		 function ToString() : string;
		 procedure Delete();
		 property Filename : string read FFilename;
		 property FullFilename : string read GetFullFilename;
		 property MD5String : string read GetMD5String;
		 property LastWrite : TDateTime read GetLastWrite;
		 property Size : int64 read GetSize;
		 property Parent : TManagedFolder read FParent;
		 property FingerPrints : string read GetFingerprints;
	 end;

	 TVVSFileList = TList<TVVsFile>;

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
		 property RootDir : string read FRootDir;
		 procedure Reload;
		 function ToString() : string; override;
		 function Diff( remoteFolder : TManagedFolder; List : TVVSFileList ) : boolean;
	 end;

	 TVVSPublication = class
	 private
		 FManagedFolder : TManagedFolder;
		 FName: string;
	 public
		 constructor Create(const AName, APath : string); virtual;
		 destructor Destroy; override;
		 property Name : string read FName;
		 property ManagedFolder : TManagedFolder read FManagedFolder;
	 end;


var
	GlobalPublication : TVVSPublication = nil;

implementation

uses
	 BinHnd, Str_pas, StrHnd, jclAnsiStrings, Applog, vvsConsts, vvsConfig, Math;


{ TVVSFile }

constructor TVVSFile.Create(AParent : TManagedFolder ; const AFilename : string);
begin
	inherited Create;
	Self.FParent := AParent;
	if ( TStrHnd.startsWith( AFilename, '.') ) then begin
		Self.FFilename := AFilename;
	end else begin
		Self.FFilename:= ReplaceSubString( AFilename, Self.FParent.RootDir, '.' );
	end;
end;

procedure TVVSFile.Delete;
begin
	if ( not DeleteFile( Self.FullFilename ) ) then begin
		TLogFile.Log( Format( 'Arquivo("%s") não pode ser apagado', [ Self.FullFilename ] ), lmtError );
	end;
end;

function TVVSFile.GetFingerprints: string;
var
	fs : TFileStream;
	ms : TMemoryStream;
	bs : integer;
begin
	{TODO -oroger -cdsg : cadeia com os hashs do arquivo em blocos do tamanho da configuração em vigor}
	Result := EmptyStr;
	bs:=VVSvcConfig.BlockSize;
	ms := TMemoryStream.Create;
	try
		fs := TFileStream.Create( Self.FullFilename,  fmOpenRead + fmShareDenyWrite );
		while fs.Position < fs.Size do begin
			ms.CopyFrom( fs, Math.Min( bs, fs.Size - fs.Position ) );
			ms.Position := 0;
			Result := Result + THashHnd.MD5( ms ) + TOKEN_DELIMITER;
			ms.Position := 0;
		end;
	finally
		ms.Free;
	end;
end;

function TVVSFile.GetFullFilename: string;
begin
	if ( Assigned( Self.FParent ) ) then begin
		if ( TStrHnd.startsWith( Self.FFilename, '.' ) or TStrHnd.startsWith( Self.FFilename, '\' ) ) then begin
			Result := TFileHnd.ConcatPath( [ Self.FParent.RootDir, Copy( Self.FFilename, 2, Length( Self.FFilename ) ) ] );
		end else begin
			Result:=Self.FFilename;
		end;
	end else begin
		Result:= Self.FFilename;
	end;
end;

function TVVSFile.GetLastWrite : TDateTime;
begin
	if ( Self._LastWrite = 0 ) then begin
		Self._LastWrite := TFileHnd.FileTimeChangeTime(Self.FullFilename);
	end;
	Result:=Self._LastWrite;
end;

function TVVSFile.GetMD5String : string;
begin
    if (Self._MD5String = EmptyStr) then begin
		 Self._MD5String := THashHnd.MD5(Self.FullFilename);
    end;
    Result := Self._MD5String;
end;

function TVVSFile.GetSize: int64;
begin
	if ( Self._Size = 0 ) then begin
		_Size:=TFileHnd.GetFileSizeEx( Self.FullFilename );
	end;
	Result := Self._Size;
end;

procedure TVVSFile.Refresh;
/// <sumary>
/// recarrega todos os atributos, principalmente os de cache
/// </sumary>
begin
	Self.GetMD5String();
	Self.GetLastWrite();
	Self.GetSize();
end;

function TVVSFile.ToString : string;
var
	 m : TJSONMarshal;
	 AsString : TJSONObject;  //Serialized for of object
begin
	 Self.Refresh;
	 m := TJSONMarshal.Create(TJSONConverter.Create);
	 try
	 	//registra conversor para resolver problema dos escapes"\" do nome do arquivo
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
		//Registra conversor para anular instancia de FParent(sempre ajustada no Unmarshalling)
		m.RegisterConverter( Self.ClassType, 'FParent', function(Data: TObject; Field: String): TObject
		begin
			Result := nil;
		end);
        AsString := TJSONObject(m.Marshal(self));
        Result   := AsString.ToString;
    finally
        m.Free;
    end;
end;

{ TManagedFolder }

function TManagedFolder.Diff(remoteFolder: TManagedFolder; List: TVVSFileList): boolean;
var
	locFile, remFile : TVVSFile;
  I: Integer;
begin
	List.Clear;
	//varre remotos
	for remFile in remoteFolder.Values do begin
		if ( Self.TryGetValue( remFile.Filename, locFile ) ) then begin  //busca na lista local o mesmo nome do remoto
			if ( remFile.MD5String <> locFile.MD5String ) then begin
				List.Add( remFile ); //existem e são diferentes
			end;
		end else begin
			List.Add( remFile ); //encontrado apenas no remoto -> ser baixado completamente
		end;
	end;

	for locFile in Self.Values do begin
		if ( not remoteFolder.TryGetValue( locFile.Filename, remFile ) ) then begin
			List.Add( locFile ); //existe no local apenas -> será apagado(checar parent = local para isso)
		end;
	end;

	Result := (List.Count > 0);
end;

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
begin
	 inherited Create;
	 Self.FCriticalSection := TCriticalSection.Create;
	 Lines := TStringList.Create();
	 try
		 unm := TJSONUnMarshal.Create();
		 try
		 	//nada abaixo resolveu, o pulo do gato foi no Marshalling onde setado objeto como null
			(*
			unm.RegisterReverter( TVVSFile, 'FParent', procedure(Data: TObject; Field: String; Arg: TObject)
			begin
				TVVSFile( Data ).FParent:=Self;
			end);
			*)
			(*
			unm.RegisterReverter( TVVSFile, function(Data: TObject): TObject
			begin
				TVVSFile( Data ).FParent := Self;
				Result := Self;
			end);
			*)
			 Lines.Text := AData;
			 for s in Lines do begin
				 try
					 SerialFile := TJSONObject.Create;
					 //SerialFile.Parse (TEncoding.ASCII.GetBytes(s), 0);
					 SerialFile.Parse (TEncoding.UTF8.GetBytes(s), 0);
					 f := unm.Unmarshal(SerialFile) as TVVSFile;
					 f.FParent := Self;
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
	 Self.Lock();  //poder-se-ia proteger apenas as alterações após criação de instância, ie, Add e Remove overrided
    try
		//identifica a mudanca e recarrega dados do arquivo
        case AFolderItem.Action of
            faNew : begin
                vf := TVVSFile.Create(Self, AFolderItem.Name);
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
                vf := TVVSFile.Create(Self, AFolderItem.Name);
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
            vf := TVVSFile.Create(Self, f);
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

{ TVVSPublication }

constructor TVVSPublication.Create(const AName, APath : string);
begin
	 inherited Create;
    Self.FName := AName;
	 Self.FManagedFolder := TManagedFolder.CreateLocal(APath);
	 Self.FManagedFolder.Monitored:=True;
end;

destructor TVVSPublication.Destroy;
begin
	 Self.FManagedFolder.Free;
	 inherited;
end;

end.
