unit magfmtdisk;

{$WARN UNSAFE_TYPE off}
{$WARN UNSAFE_CAST off}
{$WARN UNSAFE_CODE off}
{$WARN SYMBOL_PLATFORM OFF}
{$WARN SYMBOL_LIBRARY OFF}
{$WARN SYMBOL_DEPRECATED OFF}

 // Magenta Check Disk and Format Disk component
 // 20th August 2008 - Release 1.2 (C) Magenta Systems Ltd, 2008
 // based on Chkdskx and Formatx by Mark Russinovich at http://www.sysinternals.com

 // Copyright by Angus Robertson, Magenta Systems Ltd, England
 // delphi@magsys.co.uk, http://www.magsys.co.uk/delphi/

 // 20th Oct 2005 1.0 - baseline
 // 30th Jul 2008 1.1 - tested with Unicode and Delphi 2009, and Vista
 //                     a few more callback messages
 // 20th Aug 2008 1.2 - corrected progress message charset which was OEM (IBM-PC) not
 //                         ANSI or unicode, thanks to Francois Piette

interface

uses
	 Windows, Messages, SysUtils, Classes;

const
		 WM_GETOBJ = WM_USER + 701;  //Desnecessario, matido por repeito ao autor

var
	 // Chkdsk command in FMIFS
	 Chkdsk : procedure(
	 DriveRoot : PWCHAR;
	 Format : PWChar;
	 CorrectErrors : BOOL;
	 Verbose : BOOL;
	 CheckOnlyIfDirty : BOOL;
	 ScanDrive : BOOL;
	 Unused2 : DWORD;
	 Unused3 : DWORD;
	 Callback : Pointer); stdcall;

	 // Format command in FMIFS

	 FormatEx : procedure(
	 DriveRoot : PWCHAR;
	 MediaFlag : DWORD;
	 Format : PWCHAR;
	 DiskLabel : PWCHAR;
	 QuickFormat : BOOL;
	 ClusterSize : DWORD;
	 Callback : Pointer); stdcall;

	 // Enable/Disable volume compression command in FMIFS

	 EnableVolumeCompession : function(DriveRoot : PWCHAR; Enable : BOOL) : boolean; stdcall;

type

	 {TODO -oroger -clib : Corrigir o tipo derivado de fmifs.h corretamente e remover o lixo derivado deste erro(ver enumeracao correta abaixo ) }
	 TMediaType     = (mtHardDisk, mtFloppy, mtRemovable ); //Valores erroneamente derivados de fmifs.h
	 TFileSystem    = (fsNTFS, fsFAT, fsFAT32);
	 TProgressEvent = procedure(Percent : Integer; var Cancel : boolean) of object;
	 TInfoEvent = procedure(Info : string; var Cancel : boolean) of object;

	 TMagFmtChkDsk = class(TComponent)
	 private
		 { Private declarations }
		 fProgressEvent :  TProgressEvent;
		 fInfoEvent :      TInfoEvent;
		 fDoneOK :         boolean;
		 fFileSysProblem : boolean;
		 fFreeSpaceAlloc : boolean;
		 fFirstErrorLine : string;
	 protected
		 { Protected declarations }
		 function CheckDriveExists(const WDrive : WideString; CheckInUse : boolean; var WFormat : WideString) : boolean;
		 function doProgressEvent(const Percent : Integer) : boolean;
		 function doInfoEvent(const Info : string) : boolean;
		 procedure WMGETOBJ(var msg : TMessage); message WM_GETOBJ;
	 public
		 { Public declarations }
		 function LoadFmifs : boolean;
		 function FormatDisk(const DrvRoot : string; MediaType : TMediaType; FileSystem : TFileSystem;
			 const DiskLabel : string; QuickFormat : boolean; ClusterSize : Integer) : boolean;
		 function CheckDisk(const DrvRoot : string; CorrectErrors, Verbose, CheckOnlyIfDirty, ScanDrive : boolean) : boolean;
		 function VolumeCompression(const DrvRoot : string; Enable : boolean) : boolean;
	 published
		 { Published declarations }
		 property FileSysProblem : boolean read fFileSysProblem;
		 property FreeSpaceAlloc : boolean read fFreeSpaceAlloc;
		 property FirstErrorLine : string read fFirstErrorLine;
		 property onProgressEvent : TProgressEvent read fProgressEvent write fProgressEvent;
		 property onInfoEvent : TInfoEvent read fInfoEvent write fInfoEvent;
	 end;

	 FmtChkException = class(Exception);

implementation

var
	 MagFmifsib :      THandle = 0;
	 MagFmifs_Loaded : boolean = False;   // See if DLL functions are loaded
	 MagFmtObj :       TObject;

const
	 fmifs     = 'fmifs.dll';

	 // media flags
	 {TODO -oroger -clib : trazer valores abaixo corretamente oriundos de fmifs.h para aqui(trata-se originalmnete de enumeracao) }
	 FMIFS_HARDDISK  = $0C;
	 FMIFS_FLOPPY    = $08;
	 FMIFS_REMOVABLE = $0B;


// Output command
type
	 TextOutput = record
		 Lines:  DWORD;
		 Output: PAnsiChar;  // unicode
	 end;
	 PTextOutput = ^TextOutput;

	 // Callback command types
	 TCallBackCommand = (
		 PROGRESS,
		 DONEWITHSTRUCTURE,
		 UNKNOWN2,
		 UNKNOWN3,
		 UNKNOWN4,
		 UNKNOWN5,
        INSUFFICIENTRIGHTS,
        FSNOTSUPPORTED,  // added 1.1
        VOLUMEINUSE,     // added 1.1
        UNKNOWN9,
        UNKNOWNA,
        DONE,
        UNKNOWNC,
        UNKNOWND,
        OUTPUT,
        STRUCTUREPROGRESS,
        CLUSTERSIZETOOSMALL, // 16
        UNKNOWN11,
        UNKNOWN12,
        UNKNOWN13,
        UNKNOWN14,
        UNKNOWN15,
        UNKNOWN16,
        UNKNOWN17,
        UNKNOWN18,
        PROGRESS2,      // added 1.1, Vista percent done seems to duplicate PROGRESS
        UNKNOWN1A);


procedure Register;
begin
    RegisterComponents('Samples', [TMagFmtChkDsk]);
end;

// FMIFS callback definition

function FormatCallback(Command : TCallBackCommand; SubAction : DWORD; ActionInfo : Pointer) : boolean; stdcall;
var
    flag :    pboolean;
    percent : pinteger;
    toutput : PTextOutput;
    Obj :     TObject;
    cancelflag : boolean;
    info :    string;
    xlatbuf : ansistring;
    progper, slen : Integer;
begin
    Result  := True;
    cancelflag := False;
    //    Obj := TObject (SendMessage (HInstance, WM_GETOBJ, 0, 0)) ;
    Obj     := MagFmtObj;
    progper := -1;
    info    := '';
    if not Assigned(TMagFmtChkDsk(Obj)) then begin
        exit;
    end;
    case Command of
        Progress : begin
            percent := ActionInfo;
            progper := percent^;
        end;
        Progress2 :   // 1.1 added for Vista
        begin
            //    percent := ActionInfo ;
            //    progper := percent^ ;
        end;
        Output : begin
            toutput := ActionInfo;
            slen    := StrLen(toutput^.Output);
            SetLength(xlatbuf, slen);   // 1.2 change OEM charset to ANSI
            OemToCharBuffA(PAnsiChar(toutput^.Output), PAnsiChar(xlatBuf), slen);
            info := Trim(string(xlatBuf));
        end;
        Done : begin
            flag := ActionInfo;
            TMagFmtChkDsk(Obj).fDoneOK := flag^;
            if flag^ then begin
                info := 'Format Disk: Finished OK';
            end else begin
                info := 'Format Disk: Unable to Finish';
            end;
        end;
        DoneWithStructure : begin
            info := 'Format Disk: Structure Created OK';
        end;
        InsufficientRights : begin
            info := 'Format Disk: Insufficient Rights';
        end;
        UNKNOWN9 : begin
            info := 'Format Disk: Quick Format Not Allowed';
        end;
        ClusterSizeTooSmall : begin
            info := 'Format Disk: Cluster Size Too Small';
        end; // 1.1
        FSNotSupported : begin
            info := 'Format Disk: FS Not Supported';
        end; // 1.1
        VolumeInUse : begin
            info := 'Format Disk: Volume In-Use';
        end; // 1.1
        StructureProgress : begin
            //    percent := ActionInfo ;  does not seem to be a result
            //    if percent <> Nil then progper := percent^ ;
        end;
        else begin
            info := 'Format Disk Callback: ' + IntToStr(Ord(Command));
        end;
    end;
    if progper >= 0 then begin
        cancelflag := TMagFmtChkDsk(Obj).doProgressEvent(progper);
    end;
    if info <> '' then begin
        cancelflag := TMagFmtChkDsk(Obj).doInfoEvent(info);
    end;
    Result := not cancelflag;
end;

function ChkDskCallback(Command : TCallBackCommand; SubAction : DWORD; ActionInfo : Pointer) : boolean; stdcall;
var
    flag :    pboolean;
    percent : pinteger;
    toutput : PTextOutput;
    Obj :     TObject;
    info :    string;
    progper, slen : Integer;
    cancelflag : boolean;
    xlatbuf : ansistring;
begin
    Result := True;
    cancelflag := False;
    progper := -1;
    info := '';
    //    Obj := TObject (SendMessage (HInstance, WM_GETOBJ, 0, 0)) ;
    Obj  := MagFmtObj;
    if not Assigned(TMagFmtChkDsk(Obj)) then begin
        exit;
    end;
    case Command of
        Progress : begin
            percent := ActionInfo;
            progper := percent^;
        end;
        Progress2 :   // 1.1 added for Vista
        begin
            //    percent := ActionInfo ;
            //    progper := percent^ ;
        end;
        Output : begin
            toutput := ActionInfo;
            slen    := StrLen(toutput^.Output);
            SetLength(xlatbuf, slen);   // 1.2 change OEM charset to ANSI
            OemToCharBuffA(PAnsiChar(toutput^.Output), PAnsiChar(xlatBuf), slen);
            info := Trim(string(xlatBuf));
            if (Pos('found problems', info) > 0) or
                (Pos('Correcting errors', info) > 0) or
                (Pos('Errors found', info) > 0) or
                (Pos('(fix) option', info) > 0) then begin
                TMagFmtChkDsk(Obj).fFileSysProblem := True;
                if TMagFmtChkDsk(Obj).fFirstErrorLine = '' then begin
                    TMagFmtChkDsk(Obj).fFirstErrorLine := info;
                end;
            end;
            if (Pos('free space marked as allocated', info) > 0) then begin
                TMagFmtChkDsk(Obj).fFreeSpaceAlloc := True;
                if TMagFmtChkDsk(Obj).fFirstErrorLine = '' then begin
                    TMagFmtChkDsk(Obj).fFirstErrorLine := info;
                end;
            end;
        end;
        Done : begin
            flag := ActionInfo;
            TMagFmtChkDsk(Obj).fDoneOK := flag^;
            if flag^ then begin
                info := 'Check Disk: Finished OK';
            end else begin
                info := 'Check Disk: Unable to Finish';
            end;
        end;
        FSNotSupported : begin
            info := 'Check Disk: FS Not Supported';
        end; // 1.1
        VolumeInUse : begin
            info := 'Check Disk: Volume In-Use';
        end; // 1.1
        InsufficientRights : begin
            info := 'Check Disk: Insufficient Rights';
        end; // 1.1
        else begin
            info := 'Check Disk Callback: ' + IntToStr(Ord(Command));
        end;
    end;
    if progper >= 0 then begin
        cancelflag := TMagFmtChkDsk(Obj).doProgressEvent(progper);
    end;
    if info <> '' then begin
        cancelflag := TMagFmtChkDsk(Obj).doInfoEvent(info);
    end;
    Result := not cancelflag;
end;

procedure TMagFmtChkDsk.WMGETOBJ(var msg : TMessage);
begin
    msg.Result := Integer(TMagFmtChkDsk);
end;

function TMagFmtChkDsk.doProgressEvent(const Percent : Integer) : boolean;
begin
    Result := False;
    if Assigned(fProgressEvent) then begin
        fProgressEvent(Percent, Result);
    end;
end;

function TMagFmtChkDsk.doInfoEvent(const Info : string) : boolean;
begin
    Result := False;
    if Assigned(fInfoEvent) then begin
        fInfoEvent(Info, Result);
    end;
end;


function TMagFmtChkDsk.CheckDriveExists(const WDrive : WideString; CheckInUse : boolean; var WFormat : WideString) : boolean;
var
    FileSysName : array[0..MAX_PATH] of WChar;
    VolumeName :  array[0..MAX_PATH] of WChar;
    maxcomlen, flags : longword;
    handle :      THandle;
    voldev :      WideString;
begin
    if (Length(WDrive) < 2) or (WDrive[2] <> ':') then begin
        raise FmtChkException.Create('Invalid Drive Specification: ' + WDrive);
        exit;
    end;

    // see if volume exists, get file system (FAT32, NTFS)
    if not GetVolumeInformationW(PWChar(WDrive), VolumeName, SizeOf(VolumeName) div 2,
        nil, maxcomlen, flags, FileSysName, SizeOf(FileSysName) div 2) then begin
        raise FmtChkException.Create('Drive Not Found: ' + WDrive);
        exit;
    end;
    WFormat := FileSysName;
    doInfoEvent(WDrive + ' Volume Label: ' + VolumeName + ', File System: ' + FileSysName);

    // try and get exclusive access to volume
    if CheckInUse then begin
        voldev := '\\.\' + WDrive[1] + ':';
        handle := CreateFileW(PWChar(voldev), Generic_Write, 0, nil, Open_Existing, 0, 0);
        if handle = INVALID_HANDLE_VALUE then begin
            raise FmtChkException.Create('Drive In Use: ' + WDrive);
            exit;
        end;
        CloseHandle(handle);
    end;
    Result := True;
end;

function TMagFmtChkDsk.FormatDisk(const DrvRoot : string; MediaType : TMediaType; FileSystem : TFileSystem;
    const DiskLabel : string;
    QuickFormat : boolean; ClusterSize : Integer) : boolean;
var
    wdrive, wformat, wfilesystem, wdisklabel : WideString;
    mediaflags, newsize : DWORD;
begin
    Result := False;
    if not LoadFmifs then begin
        exit;
    end;
    wdrive     := Uppercase(DrvRoot);
    //    wdrive := 'T:\' ; // TESTING
    wdisklabel := Uppercase(DiskLabel);
    case MediaType of
		 mtHardDisk : begin
			 mediaflags := FMIFS_HARDDISK;
		 end;
		 mtFloppy : begin
			 mediaflags := FMIFS_FLOPPY;
		 end;
		 mtRemovable : begin
         	mediaflags:= FMIFS_REMOVABLE;
        end
		 else begin
            Exit;
        end;
    end;
    if FileSystem = fsFAT then begin
        wfilesystem := 'FAT';
    end else
    if FileSystem = fsFAT32 then begin
        wfilesystem := 'FAT32';
    end else
    if FileSystem = fsNTFS then begin
        wfilesystem := 'NTFS';
    end else begin
        exit;
    end;
    newsize := 0;
    if ((ClusterSize = 512) or (ClusterSize = 1024) or (ClusterSize = 2048) or
        (ClusterSize = 4096) or (ClusterSize = 8192) or (ClusterSize = 16384) or
        (ClusterSize = 32768) or (ClusterSize = 65536)) then begin
        newsize := ClusterSize;
    end;
    fDoneOK := False;
    if DiskSize(Ord(WDrive[1]) - 64) > 100 then begin // don't check drive unless it exists
        doInfoEvent(WDrive + ' Checking Existing Drive Format');
        if not CheckDriveExists(wdrive, True, wformat) then begin
            exit;
        end;
        if wformat <> wfilesystem then begin
            QuickFormat := False;
        end;
    end else begin
        if (Length(WDrive) < 2) or (WDrive[2] <> ':') then begin
            raise FmtChkException.Create('Invalid Drive Specification: ' + WDrive);
            exit;
        end;
        doInfoEvent(WDrive + ' Appears to be Unformatted or No Drive');
        QuickFormat := False;
    end;
    MagFmtObj := Self;
    fFirstErrorLine := '';
    doInfoEvent(WDrive + ' Starting to Format Drive');
	 FormatEx(PWchar(wdrive), mediaflags, PWchar(wfilesystem), PWchar(wdisklabel), QuickFormat, newsize, @FormatCallback);
	 Result := fDoneOK;
    if not Result then begin
        exit;
    end;
    doInfoEvent(WDrive + ' Checking New Drive Format');
    if not CheckDriveExists(wdrive, False, wformat) then begin
        exit;
    end;
    doInfoEvent(WDrive + ' New Volume Space: ' + IntToStr(DiskFree(Ord(WDrive[1]) - 64)));
end;

function TMagFmtChkDsk.CheckDisk(const DrvRoot : string; CorrectErrors, Verbose, CheckOnlyIfDirty, ScanDrive : boolean) : boolean;
var
    wdrive, wformat : WideString;
begin
    Result := False;
    if not LoadFmifs then begin
        exit;
    end;
    wdrive := Uppercase(DrvRoot);
    if not CheckDriveExists(wdrive, CorrectErrors, wformat) then begin
        exit;
    end;
    MagFmtObj := Self;
    fDoneOK   := False;
    fFileSysProblem := False;
    fFreeSpaceAlloc := False;
    fFirstErrorLine := '';
    Chkdsk(PWchar(wdrive), PWchar(wformat), CorrectErrors, Verbose, CheckOnlyIfDirty, ScanDrive, 0, 0, @ChkDskCallback);
    if fFileSysProblem then begin
        Result := True;
    end else begin // ignore stopped if got an error
        Result := fDoneOK;
    end;
end;

function TMagFmtChkDsk.VolumeCompression(const DrvRoot : string; Enable : boolean) : boolean;
var
    wdrive, wformat : WideString;
begin
    Result := False;
    if not LoadFmifs then begin
        exit;
    end;
    wdrive := Uppercase(DrvRoot);
    if not CheckDriveExists(wdrive, True, wformat) then begin
        exit;
    end;
    Result := EnableVolumeCompession(PWchar(wdrive), Enable);
end;

 // try and load various Format Manager for Installable File Systems functions.
 // Returns false if failed

function TMagFmtChkDsk.LoadFmifs : boolean;
begin
    Result := Assigned(Chkdsk);
    if MagFmifs_Loaded then begin
        exit;
    end;
    Result := False;
    if Win32Platform <> VER_PLATFORM_WIN32_NT then begin
        exit;
    end;

    // open libraries - only come here once
    Result     := False;
    MagFmifs_Loaded := True;
    MagFmifsib := LoadLibrary(fmifs);
    if MagFmifsib = 0 then begin
        exit;
    end;

    // set function addresses in DLL
    Chkdsk   := GetProcAddress(MagFmifsib, 'Chkdsk');
    FormatEx := GetProcAddress(MagFmifsib, 'FormatEx');
    EnableVolumeCompession := GetProcAddress(MagFmifsib, 'EnableVolumeCompession');
    Result   := Assigned(Chkdsk);
end;

initialization
    MagFmifsib      := 0;
    MagFmifs_Loaded := False;

finalization
    if MagFmifs_Loaded then begin
        FreeLibrary(MagFmifsib);
    end;
end.
