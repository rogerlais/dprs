{
******************************************************
  USB Disk Ejector
  Copyright (c) 2006 - 2011 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}
{
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
}

//TODO - rewrite with tlist instead of arrays

unit uDriveEjector;

interface

uses
	 Classes, Windows, Forms, SysUtils, ExtCtrls, JwaWindows, jclsysinfo, uProcessAndWindowUtils, uDiskEjectConst;

type
    TRemovableDrive = packed record
        DriveMountPoint:  string;
        VolumeLabel:      string;
        VendorId:         string;
        ProductID:        string;
		 ProductRevision:  string;
		 SerialNumber:     string;
        IsCardReader:     boolean;
        HasSiblings:      boolean;
        CardMediaPresent: boolean;
        BusType:          Integer;
        ParentDevInst:    Integer;
        SiblingIndexes:   array of Integer;
    end;

	 TDriveEjector = class
	 private
		 PollTimer : TTimer;
		 FOnCardMediaChanged : TNotifyEvent;
		 FPollTimerInterval : cardinal;
		 FPolling : boolean;
		 FBusy :    boolean;
		 FOnDrivesChanged : TNotifyEvent;

		 function GetDrivesCount : Integer;
		 function GetBusy : boolean;
		 function GetDrivesDevInstByDeviceNumber(DeviceNumber : Integer; DriveType : UINT; szDosDeviceName : PChar) : DEVINST;
		 function EjectDevice(MountPoint : string; var EjectErrorCode : Integer; ShowEjectMessage : boolean = False) : boolean;
		 function EjectCard(MountPoint : string; var EjectErrorCode : Integer) : boolean;
		 function GetParentDriveDevInst(MountPoint : string; var ParentInstNum : Integer) : boolean;
		 function GetNoDevicesWithSameParentInst(ParentDevInst : Integer) : Integer;
		 function GetNoDevicesWithSameProductId(ProductId : string) : Integer;
		 function CheckIfDriveHasMedia(MountPoint : string) : boolean;
		 function GetCardPolling : boolean;
		 procedure SetCardPolling(Value : boolean);
		 function GetCardPollingInterval : cardinal;
		 procedure SetCardPollingInterval(Value : cardinal);
		 procedure FindRemovableDrives;
		 procedure ScanDrive(GUIDVolumeName : string);

		 procedure CheckForCardReaders;
		 procedure CheckForSiblings;
		 procedure OnTimer(Sender : TObject);
        procedure SetBusy(const Value : boolean);
		 procedure DeleteFromDrivesArray(const Index : cardinal);
		 function ReadVolumeSerial(const Drive : PChar) : string;
	 public
        RemovableDrives : array of TRemovableDrive;
        constructor Create;
        destructor Destroy; override;
        function RemoveDrive(MountPoint : string; var EjectErrorCode : Integer; ShowEjectMessage : boolean = False;
            CardEject : boolean = False; CloseRunningApps : boolean = False; ForceRunningAppsClosure : boolean = False) : boolean;
            overload;
        procedure RescanAllDrives;
        procedure ClearDriveList;
        procedure SetDriveAsCardReader(Index : Integer; CardReader : boolean);
        property DrivesCount : Integer read GetDrivesCount;
        property OnCardMediaChanged : TNotifyEvent read FOnCardMediaChanged write FOnCardMediaChanged;
        property CardPollingInterval : cardinal read GetCardPollingInterval write SetCardPollingInterval;
        property CardPolling : boolean read GetCardPolling write SetCardPolling;
        property Busy : boolean read GetBusy write SetBusy;
        property OnDrivesChanged : TNotifyEvent read FOnDrivesChanged write FOnDrivesChanged;
    end;

    TEventsThread = class(TThread)
    private
		 FEjector : TDriveEjector;
    protected
        procedure Execute; override;
    public
        constructor Create(Ejector : TDriveEjector);
    end;

implementation

var
	 GlobalPrevWndProc :    TFNWndProc = nil;
	 GlobalChangeMessageCount : Integer = 0;
	 GlobalCriticalSection : TCriticalSection;
	 GlobalCollectEventsThread :    TEventsThread;
	 GetVolumePathNamesForVolumeNameW : function(VolumeName, VolumePathNames : PWideChar;
	 BufferLength : longword; ReturnLength : PLongWord) : longbool; stdcall;


 {--------------------------Windows 2000 workaround-----------------------------}
 //This workaround by htmisu
 //http://www.delphipraxis.net/topic89088.html
function _GetVolumePathNamesForVolumeNameW(VolumeName, VolumePathNames : PWideChar; BufferLength : longword;
    ReturnLength : PLongWord) : longbool; stdcall;
var
    LogicalDriveStrings, SearchBuffer, ResultS : WideString;
    ResultBuffer : array[0..MAX_PATH - 1] of widechar;

    procedure SearchRecursiv(const SearchBuffer2 : WideString);
    var
        SearchHandle :  THandle;
        SearchBuffer3 : WideString;
    begin
        SearchHandle := FindFirstVolumeMountPointW(@ResultBuffer, @ResultBuffer, MAX_PATH);
        if SearchHandle = INVALID_HANDLE_VALUE then begin
            Exit;
        end;
        repeat
            SearchBuffer3 := SearchBuffer2 + ResultBuffer;
            if GetVolumeNameForVolumeMountPointW(PWideChar(SearchBuffer3), @ResultBuffer, MAX_PATH) then begin
                if CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, VolumeName, -1, @ResultBuffer, -1) = 2 then begin
                    ResultS := ResultS + Copy(SearchBuffer3, 5, MAX_PATH) + #0;
                end;
                SearchRecursiv(SearchBuffer3);
            end;
        until not FindNextVolumeMountPointW(SearchHandle, @ResultBuffer, MAX_PATH);

        FindVolumeMountPointClose(SearchHandle);
    end;

begin
	 ResultS := '';
    SetLength(LogicalDriveStrings, GetLogicalDriveStringsW(0, nil));
    GetLogicalDriveStringsW(255, @LogicalDriveStrings[1]);
    LogicalDriveStrings := Trim(LogicalDriveStrings);
    while LogicalDriveStrings <> '' do begin
        SearchBuffer := '\\.\' + PWideChar(LogicalDriveStrings);
        System.Delete(LogicalDriveStrings, 1, Length(SearchBuffer) - 4);
        LogicalDriveStrings := TrimLeft(LogicalDriveStrings);
        if (SearchBuffer[5] <= 'B') and (SearchBuffer[6] = ':') then begin
            Continue;
        end;
        if GetVolumeNameForVolumeMountPointW(PWideChar(SearchBuffer), @ResultBuffer, MAX_PATH) then begin
            if CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, VolumeName, -1, @ResultBuffer, -1) = 2 then begin
                ResultS := ResultS + Copy(SearchBuffer, 5, MAX_PATH) + #0;
            end;
            SearchRecursiv(SearchBuffer);
        end;
    end;

    ResultS := ResultS + #0;
    if (BufferLength >= longword(Length(ResultS))) and (VolumePathNames <> nil) then begin
        Move(ResultS[1], VolumePathNames^, 2 * Length(ResultS));
        if ReturnLength <> nil then begin
            ReturnLength^ := Length(ResultS);
        end;
		 Result := True;
    end else begin
        if (BufferLength = 0) and (VolumePathNames = nil) then begin
            if ReturnLength <> nil then begin
                ReturnLength^ := Length(ResultS);
            end;
            Result := True;
        end else begin
            if VolumePathNames <> nil then begin
                VolumePathNames^ := #0;
            end;
            if ReturnLength <> nil then begin
                ReturnLength^ := 1;
            end;

            Result := False;
        end;
    end;
end;

{------------------------Hook events in dummy window--------------------------}
function UsbWndProc(hWnd : HWND; Msg : UINT; wParam, lParam : longint) : longint; stdcall;
begin
	 Result := CallWindowProc(GlobalPrevWndProc, hWnd, Msg, wParam, lParam);

    if (Msg = WM_DEVICECHANGE) and
		 (
		   ( (wParam = DBT_DEVICEARRIVAL) and
			  (PDevBroadcastHeader(lParam).dbcd_devicetype = DBT_DEVTYP_VOLUME)
		   )
		   or
		   (wParam = DBT_DEVICEREMOVECOMPLETE)
		 )
		   then
	 begin
		 EnterCriticalSection(GlobalCriticalSection);
		 Inc(GlobalChangeMessageCount);
		 LeaveCriticalSection(GlobalCriticalSection);
		 if GlobalCollectEventsThread.Suspended then begin
			 GlobalCollectEventsThread.Resume;
		 end;
	 end;
end;

{-----------------------------------------------------------------------------}

//Event thread
constructor TEventsThread.Create(Ejector : TDriveEjector);
begin
	 FEjector := Ejector;
	 inherited Create(False);
end;

procedure TEventsThread.Execute;
begin
	 while ( not Terminated ) do begin
		 if Self.Terminated then begin
			 break;
		 end;

		 if (GlobalChangeMessageCount > 0) and (not FEjector.Busy) then begin
			 Sleep(500);
			 //gives extra time for devices with multi volumes/partitions - sometimes theres only 1 message but it takes a moment for windows to mount both partitions
			 EnterCriticalSection(GlobalCriticalSection);
			 GlobalChangeMessageCount := 0; //set it back to 0 because we're about to scan
			 LeaveCriticalSection(GlobalCriticalSection);
			 FEjector.RescanAllDrives;
			 //messagebeep(0);
		 end else begin
			 Self.Suspend;
		 end;
    end;
end;

{-----------------------------------------------------------------------------}

constructor TDriveEjector.Create;
begin
    LoadSetupApi;
    LoadConfigManagerApi;

    PollTimer := TTimer.Create(nil);
	 fPolling  := False;
	 PollTimer.OnTimer := OnTimer;
	 fPollTimerInterval := 5000;
    PollTimer.Interval := fPollTimerInterval;

	 {TODO -oroger -cbug : tentar criar janela a parte para evitar hook para a da aplicacao, ver exemplo em procedure TJvDeviceChanged.WndProc(var Msg: TMessage); }
    //Setup dummy window to catch messages
	 if not Assigned(GlobalPrevWndProc) then begin
		 GlobalPrevWndProc := TFNWndProc(GetWindowLong(Application.Handle, GWL_WNDPROC));
		 SetWindowLong(Application.Handle, GWL_WNDPROC, longint(@UsbWndProc));
    end;

    InitializeCriticalSection(GlobalCriticalSection);

	 fBusy := False;
    //Create a thread to keep polling fChangeMessageCount
    GlobalCollectEventsThread := TEventsThread.Create(self);

    FindRemovableDrives;
    //  FindOpenHandlesTest( RemovableDrives[0].DriveMountPoint);
end;

destructor TDriveEjector.Destroy;
begin
    GlobalCollectEventsThread.Terminate;
    if GlobalCollectEventsThread.Suspended then begin
		 GlobalCollectEventsThread.Resume;
    end;
    GlobalCollectEventsThread.Free;

    DeleteCriticalSection(GlobalCriticalSection);

    PollTimer.Free;
    SetLength(RemovableDrives, 0);

    UnloadConfigManagerApi;
    UnloadSetupApi;
    inherited;
end;

procedure TDriveEjector.DeleteFromDrivesArray(const Index : cardinal);
var
    ALength :      cardinal;
    TailElements : cardinal;
begin
    ALength := Length(RemovableDrives);
    Assert(ALength > 0);
    Assert(Index < ALength);
	 Finalize(RemovableDrives[Index]);
    TailElements := ALength - Index;

	 if TailElements > 0 then begin
        Move(RemovableDrives[Index + 1], RemovableDrives[Index], SizeOf(TRemovableDrive) * TailElements);
    end;

	 Initialize(RemovableDrives[ALength - 1]);
    SetLength(RemovableDrives, ALength - 1);
end;


procedure TDriveEjector.FindRemovableDrives;
var
    FindRec : cardinal;
    VolumeUniqueName : array[0..MAX_PATH] of char;
begin
    SetBusy(True);
    SetLength(RemovableDrives, 0);

    FindRec := FindFirstVolume(VolumeUniqueName, MAX_PATH);
    try
        while FindRec <> INVALID_HANDLE_VALUE do begin
            ScanDrive(VolumeUniqueName);

            if not (FindNextVolume(FindRec, VolumeUniqueName, MAX_PATH)) then begin
                break;
            end;
        end;
    finally
        FindVolumeClose(FindRec);
    end;


    SetBusy(False);

    //Finally check if any are card readers
    CheckForCardReaders;

    //Check if it has siblings (multiple partitions but 1 drive)
    CheckForSiblings;

    {--------------------------------------------------------------------------------------}
    //HACK - delete card readers
    {for i := DrivesCount - 1 downto 0 do
  begin
     if RemovableDrives[i].IsCardReader then
       DeleteFromDrivesArray(i);
  end;}
    {--------------------------------------------------------------------------------------}


    if Assigned(FOnDrivesChanged) then begin
        FOnDrivesChanged(nil);
    end;
end;

procedure TDriveEjector.ScanDrive(GUIDVolumeName : string);
type
    PCharArray = ^TCharArray;
    TCharArray = array[0..32767] of AnsiChar;

    STORAGE_PROPERTY_QUERY = packed record
        PropertyId: DWORD;
        QueryType:  DWORD;
        AdditionalParameters: array[0..3] of byte;
    end;

    STORAGE_DEVICE_DESCRIPTOR = packed record
        Version: ULONG;
        Size:    ULONG;
        DeviceType: byte;
        DeviceTypeModifier: byte;
        RemovableMedia: boolean;
        CommandQueueing: boolean;
        VendorIdOffset: ULONG;
        ProductIdOffset: ULONG;
        ProductRevisionOffset: ULONG;
        SerialNumberOffset: ULONG;
        STORAGE_BUS_TYPE: DWORD;
        RawPropertiesLength: ULONG;
        RawDeviceProperties: array[0..511] of byte;
    end;

const
    IOCTL_STORAGE_QUERY_PROPERTY = $2D1400;
var
    Returned, FFileHandle, MaxCompLen, FSFlags, ReturnLength : cardinal;
    DriveBuf, VolumeName : array[0..MAX_PATH] of char;
    Status : longbool;
    PropQuery : STORAGE_PROPERTY_QUERY;
    DeviceDescriptor : STORAGE_DEVICE_DESCRIPTOR;
    PCh :  PAnsiChar;
    Inst : Integer;
    DriveMountPoint : string;
begin
    FFileHandle := INVALID_HANDLE_VALUE;
    try
        FFileHandle := CreateFile(
            PChar(ExcludeTrailingPathDelimiter(GUIDVolumeName)),
            0,
            FILE_SHARE_READ or FILE_SHARE_WRITE,
            nil,
            OPEN_EXISTING,
            0,
            0
            );

        if FFileHandle = INVALID_HANDLE_VALUE then begin
            exit;
        end;

        ZeroMemory(@PropQuery, SizeOf(PropQuery));
        ZeroMemory(@DeviceDescriptor, SizeOf(DeviceDescriptor));
        DeviceDescriptor.Size := SizeOf(DeviceDescriptor);

        Status := DeviceIoControl(
            FFileHandle,
            IOCTL_STORAGE_QUERY_PROPERTY,
            @PropQuery,
            SizeOf(PropQuery),
            @DeviceDescriptor,
            DeviceDescriptor.Size,
            @Returned,
            nil
            );

        if not Status then begin
            exit;
        end;

        if DeviceDescriptor.STORAGE_BUS_TYPE <= 0 then begin
            exit;
        end;

		 if (DeviceDescriptor.STORAGE_BUS_TYPE = JwaWindows.BusTypeUsb {JwaWinIoctl}) or
			 (DeviceDescriptor.STORAGE_BUS_TYPE = JwaWindows.BusType1394) then  //7 is USB, 4 is firewire
		 begin
			 SetLength(RemovableDrives, length(RemovableDrives) + 1);
		 end else begin  //enlarge the array for another item
			 exit;
		 end;


		 //Error handling needed here  - use SysErrorMessage  to return string of error
        Status := GetVolumeInformation(PChar(GUIDVolumeName), VolumeName, MAX_PATH, nil, MaxCompLen, FSFlags, nil, 0);
        if not Status then begin
            VolumeName := '';
        end; //exit; //getlasterror;
             //outputdebugstring(pansichar(inttostr(getlasterror)));

        Status := GetVolumePathNamesForVolumeNameW(PChar(GUIDVolumeName), DriveBuf, MAX_PATH, @ReturnLength);
        if not Status then begin
            exit;
        end; //getlasterror;
             //outputdebugstring(pansichar(inttostr(getlasterror)));

        //Drivebuf is length of drive string + 2 trailing #0's - can be more than one separated by null
        //The list is an array of null-terminated strings terminated by an additional NULL character
        //Eg g:\00
        //Eg c:\my_usb_stick_mountpoint00

        {if temp = 5 then //Drive letter
       DriveMountPoint:=DriveBuf[0]
     else}//Mount point
        DriveMountPoint := trim(copy(DriveBuf, 0, ReturnLength));

        //Drive Letter
		 RemovableDrives[high(RemovableDrives)].DriveMountPoint := DriveMountPoint;

        //Volume Name
        RemovableDrives[high(RemovableDrives)].VolumeLabel := VolumeName;

        //Vendor Id
        if DeviceDescriptor.VendorIdOffset <> 0 then begin
            PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.VendorIdOffset];
            RemovableDrives[high(RemovableDrives)].VendorId := Trim(string(Pch));
        end;

        //Product Id
        if DeviceDescriptor.ProductIdOffset <> 0 then begin
            PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductIdOffset];
            RemovableDrives[high(RemovableDrives)].ProductID := Trim(string(PCh));
        end;

        //Product Revision
        if DeviceDescriptor.ProductRevisionOffset <> 0 then begin
            PCh := @PCharArray(@DeviceDescriptor)^[DeviceDescriptor.ProductRevisionOffset];
			 RemovableDrives[high(RemovableDrives)].ProductRevision := Trim(string(PCh));
        end;

		 //Volume Serial
		 RemovableDrives[high(RemovableDrives)].SerialNumber := Self.ReadVolumeSerial( PChar( DriveMountPoint ) );


        //Is Card Reader   //This is checked and changed later
        RemovableDrives[high(RemovableDrives)].IsCardReader := False;

        //Has siblings  //This is checked and changed later
        RemovableDrives[high(RemovableDrives)].HasSiblings := False;

        //Does Card Reader have media in it?
        if CheckIfDriveHasMedia(DriveMountPoint) then begin
            RemovableDrives[high(RemovableDrives)].CardMediaPresent := True;
        end else begin
            RemovableDrives[high(RemovableDrives)].CardMediaPresent := False;
        end;

        //Bus Type
        RemovableDrives[high(RemovableDrives)].BusType := DeviceDescriptor.STORAGE_BUS_TYPE;

        //Parents Device Instance
        if GetParentDriveDevInst(DriveMountPoint, Inst) then begin
            RemovableDrives[high(RemovableDrives)].ParentDevInst := Inst;
        end;

    finally
        if FFileHandle <> INVALID_HANDLE_VALUE then begin
            CloseHandle(FFileHandle);
        end;
    end;
end;

function TDriveEjector.GetBusy : boolean;
begin
    Result := fBusy;
end;

function TDriveEjector.GetCardPolling : boolean;
begin
    Result := fPolling;
end;

function TDriveEjector.GetCardPollingInterval : cardinal;
begin
    Result := FPollTimerInterval;
end;

procedure TDriveEjector.SetBusy(const Value : boolean);
begin
    fBusy := Value;
end;

procedure TDriveEjector.SetCardPolling(Value : boolean);
begin
    fPolling := Value;
    PollTimer.Enabled := fPolling;
end;

procedure TDriveEjector.SetCardPollingInterval(Value : cardinal);
begin
    FPollTimerInterval := Value;
    PollTimer.Interval := fPollTimerInterval;
end;

procedure TDriveEjector.SetDriveAsCardReader(Index : Integer; CardReader : boolean);
begin
    RemovableDrives[Index].IsCardReader := CardReader;
end;

function TDriveEjector.GetDrivesCount : Integer;
begin
    if fBusy then begin
        while fBusy do begin
            SwitchToThread();  //libera o controle para o thread liberar os recursos presos
		 end;
	 end;
	 Result := Length(RemovableDrives);
end;

function TDriveEjector.ReadVolumeSerial(const Drive: PChar): string;
var
	 VolumeSerialNumber : DWORD;
	 MaximumComponentLength : DWORD;
	 FileSystemFlags : DWORD;
	 SerialNumber :    string;
begin
	 Result := '';

	 GetVolumeInformation(
		 Drive,
		 nil,
		 0,
		 @VolumeSerialNumber,
		 MaximumComponentLength,
		 FileSystemFlags,
		 nil,
		 0);
	 SerialNumber :=
		 IntToHex(HiWord(VolumeSerialNumber), 4) +
		 ' - ' +
		 IntToHex(LoWord(VolumeSerialNumber), 4);

	 Result := SerialNumber;
end;

//This version returns an error code on failure
function TDriveEjector.RemoveDrive(MountPoint : string; var EjectErrorCode : Integer;
    ShowEjectMessage, CardEject, CloseRunningApps, ForceRunningAppsClosure : boolean) : boolean;
var
    DriveIndex, i : Integer;
begin
    Result     := False;
    EjectErrorCode := REMOVE_ERROR_NONE;
    DriveIndex := -1;

    //First find the MountPoint
    if DrivesCount = 0 then begin
        EjectErrorCode := REMOVE_ERROR_DRIVE_NOT_FOUND;
        exit;
    end;

    for I := 0 to DrivesCount - 1 do begin
        if RemovableDrives[i].DriveMountPoint = MountPoint then begin
            DriveIndex := i;
            break;
        end;
    end;

    if DriveIndex <> -1 then begin
        //First try and close explorer windows
        EnumWindows(@EnumWindowsAndCloseFunc, LParam(MountPoint));

        //Then close windows for other drives if its a partition
        if RemovableDrives[DriveIndex].HasSiblings then begin
            for I := low(RemovableDrives[DriveIndex].SiblingIndexes) to high(RemovableDrives[DriveIndex].SiblingIndexes) do begin
                EnumWindows(@EnumWindowsAndCloseFunc,
                    LParam(RemovableDrives[RemovableDrives[DriveIndex].SiblingIndexes[i]].DriveMountPoint));
            end;
        end;


        //Then try and close any programs that might be running from the drive
        if CloseRunningApps then begin
            CloseAppsRunningFrom(MountPoint, ForceRunningAppsClosure);

            //Then close for other drives if its a partition
            if RemovableDrives[DriveIndex].HasSiblings then begin
                for I := low(RemovableDrives[DriveIndex].SiblingIndexes) to high(RemovableDrives[DriveIndex].SiblingIndexes) do
                begin
                    CloseAppsRunningFrom(RemovableDrives[RemovableDrives[DriveIndex].SiblingIndexes[i]].DriveMountPoint,
                        ForceRunningAppsClosure);
                end;
            end;
        end;


        //CHECK - stop card style eject if device isnt a card
        if ( not RemovableDrives[DriveIndex].IsCardReader ) then begin
            CardEject := False;
        end;

        if CardEject then begin //keep the card reader device - eject the media
            if EjectCard(MountPoint, EjectErrorCode) then begin
                RemovableDrives[DriveIndex].CardMediaPresent := False;
                Result := True;
            end;
        end else
        if EjectDevice(MountPoint, EjectErrorCode, ShowEjectMessage) then begin
            FindRemovableDrives;
            Result := True;
        end;
    end else begin
        EjectErrorCode := REMOVE_ERROR_DRIVE_NOT_FOUND;
    end;

end;

procedure TDriveEjector.RescanAllDrives;
begin
    FindRemovableDrives;
end;

procedure TDriveEjector.ClearDriveList;
begin
    SetLength(RemovableDrives, 0);
end;

procedure TDriveEjector.CheckForCardReaders;
var
    i : Integer;
begin
    if DrivesCount = 0 then begin
        exit;
    end;

    for i := 0 to DrivesCount - 1 do begin
        if GetNoDevicesWithSameParentInst(RemovableDrives[i].ParentDevInst) > 1 then begin
            if GetNoDevicesWithSameProductID(RemovableDrives[i].ProductId) > 1 then begin //Hard drive partitions
                RemovableDrives[i].IsCardReader := False;
            end else begin
                RemovableDrives[i].IsCardReader := True;
            end;
        end; //Matching devices with parent inst but differing device names are likely to be card readers
    end;
end;

procedure TDriveEjector.CheckForSiblings;
var
    i, j : Integer;
begin
    {for I := 0 to DrivesCount - 1 do
  begin
    if GetNoDevicesWithSameParentInst(RemovableDrives[i].ParentDevInst) > 0 then
      if GetNoDevicesWithSameProductID(RemovableDrives[i].ProductId) > 0 then //Hard drive partitions
		 RemovableDrives[i].HasSiblings := true
      else
        RemovableDrives[i].HasSiblings := false;
  end;}

    for I := 0 to DrivesCount - 1 do begin
        for J := 0 to DrivesCount - 1 do begin
            if I = J then begin
                continue;
            end; //Same drive
            if RemovableDrives[i].ParentDevInst = RemovableDrives[j].ParentDevInst then begin
                if RemovableDrives[i].ProductId = RemovableDrives[j].ProductId then begin
                    RemovableDrives[i].HasSiblings := True;
                    SetLength(RemovableDrives[i].SiblingIndexes, length(RemovableDrives[i].SiblingIndexes) + 1);
                    RemovableDrives[i].SiblingIndexes[High(RemovableDrives[i].SiblingIndexes)] := j;
                end else begin
                    RemovableDrives[i].HasSiblings := False;
                end;
            end;
        end;
    end;
end;

function TDriveEjector.CheckIfDriveHasMedia(MountPoint : string) : boolean;
var
    Returned, DriveHandle : cardinal;
    VolumeName : array[0..MAX_PATH - 1] of char;
begin
    Result := False;

    GetVolumeNameForVolumeMountPoint(PChar(MountPoint), VolumeName, MAX_PATH);

    //GENERIC_READ or GENERIC_WRITE
    DriveHandle := CreateFile(PChar(ExcludeTrailingPathDelimiter(VolumeName)),
        FILE_READ_ATTRIBUTES, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    try
        if DeviceIoControl(DriveHandle, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, @Returned, nil) then begin
            Result := True;
        end; //Card is in reader

    finally
        CloseHandle(Drivehandle);
    end;
end;

function TDriveEjector.EjectCard(MountPoint : string; var EjectErrorCode : Integer) : boolean;
var
    Returned, DriveHandle : cardinal;
    VolumeName : array[0..MAX_PATH - 1] of char;
begin
    Result := False;

    GetVolumeNameForVolumeMountPoint(PChar(MountPoint), VolumeName, MAX_PATH);

    DriveHandle := CreateFile(PChar(ExcludeTrailingPathDelimiter(VolumeName)),
        GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
    try
        if DriveHandle = INVALID_HANDLE_VALUE then begin
            if GetLastError = 32 then begin
                EjectErrorCode := REMOVE_ERROR_DISK_IN_USE;
            end else begin
                EjectErrorCode := REMOVE_ERROR_UNKNOWN_ERROR;
            end;

            exit;
        end;

        if ( not DeviceIoControl(DriveHandle, IOCTL_STORAGE_CHECK_VERIFY2, nil, 0, nil, 0, @Returned, nil) ) then begin
            EjectErrorCode := REMOVE_ERROR_NO_CARD_MEDIA;
            exit; //No card in reader
        end;


        Result := DeviceIoControl(Drivehandle, IOCTL_STORAGE_EJECT_MEDIA, nil, 0, nil, 0, @Returned, nil);

        if not Result then begin
            if GetLastError = 32 then begin
                EjectErrorCode := REMOVE_ERROR_DISK_IN_USE;
            end else begin
                EjectErrorCode := REMOVE_ERROR_UNKNOWN_ERROR;
            end;
        end;

    finally
        CloseHandle(Drivehandle);
    end;
end;

function TDriveEjector.EjectDevice(MountPoint : string; var EjectErrorCode : Integer;
    ShowEjectMessage : boolean = False) : boolean;
var
    szRootPath, szDevicePath, szVolumeAccessPath : string;
    dwBytesReturned : DWord;
    DriveType : UINT;
    hVolume :  THandle;
    SDN :      STORAGE_DEVICE_NUMBER;
    funcResult, tries, DeviceNumber : Integer;
    funcResultBool : boolean;
    DeviceInst, DevInstParent : DEVINST;
    szDosDeviceName, VetoNameW, VolumeName : array[0..MAX_PATH - 1] of char;
    VetoType : PNP_VETO_TYPE;
begin
    Result := False;

    GetVolumeNameForVolumeMountPoint(PChar(MountPoint), VolumeName, MAX_PATH);
    szRootPath   := VolumeName;
    szDevicePath := ExcludeTrailingPathDelimiter(VolumeName);
    szVolumeAccessPath := ExcludeTrailingPathDelimiter(VolumeName);
    szDevicePath := Copy(szVolumeAccessPath, 5, length(szVolumeAccessPath) - 4);
    DeviceNumber := -1;

    hVolume := INVALID_HANDLE_VALUE;
    try
        //Open the storage volume
        hVolume := CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
        if hVolume = INVALID_HANDLE_VALUE then begin
            if GetLastError = 32 then begin
                EjectErrorCode := REMOVE_ERROR_DISK_IN_USE;
            end else begin
                EjectErrorCode := REMOVE_ERROR_UNKNOWN_ERROR;
            end;

            exit;
        end;


        //Get the volume's device number
        dwBytesReturned := 0;
        funcResultBool  := DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN,
            SizeOf(SDN), @dwBytesReturned, nil);
        if funcResultBool then begin
            DeviceNumber := SDN.DeviceNumber;
        end;

    finally
        CloseHandle(hVolume);
    end;

    if DeviceNumber = -1 then begin
        EjectErrorCode := REMOVE_ERROR_WINAPI_ERROR;
        exit;
    end;


    //Get the drive type
    DriveType := GetDriveType(PChar(szRootPath));
    szDosDeviceName[0] := #0;

    //Get the dos device name (like \deviceloppy0)
    funcResult := QueryDosDevice(PChar(szDevicePath), szDosDeviceName, MAX_PATH);
    if funcResult = 0 then begin
        EjectErrorCode := REMOVE_ERROR_WINAPI_ERROR;
        exit;
    end;


    //Get the device instance handle of the storage volume through a SetupDi enum and matching the device number
    DeviceInst := GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);
    if (DeviceInst = 0) then begin
        EjectErrorCode := REMOVE_ERROR_WINAPI_ERROR;
        exit;
    end;


    VetoType     := PNP_VetoTypeUnknown;
    VetoNameW[0] := #0;

    //Get drives's parent - this is what gets ejected
    DevInstParent := 0;
    CM_Get_Parent(DevInstParent, DeviceInst, 0);

    //Try and eject 3 times
    for tries := 0 to 2 do begin
        VetoNameW[0] := #0;

        if ShowEjectMessage then begin
            funcResult := CM_Request_Device_EjectW(DevInstParent, nil, nil, 0, 0);
        end else begin //With messagebox (W2K, Vista) or balloon (XP)
            funcResult := CM_Request_Device_EjectW(DevInstParent, @VetoType, VetoNameW, MAX_PATH, 0);
        end;

        if (funcResult = CR_SUCCESS) and (VetoType = PNP_VetoTypeUnknown) then begin
            Result := True;
            break;
        end;

        Sleep(500); //Wait and then try again
    end;

    if not Result then begin
        if GetLastError = 32 then begin
            EjectErrorCode := REMOVE_ERROR_DISK_IN_USE;
        end else begin
            EjectErrorCode := REMOVE_ERROR_UNKNOWN_ERROR;
        end;
    end;
end;

function TDriveEjector.GetDrivesDevInstByDeviceNumber(DeviceNumber : Integer; DriveType : UINT; szDosDeviceName : PChar) : DEVINST;
var
    IsFloppy, DoLoop : boolean;
    myGUID : TGUID;
    myhDevInfo : HDEVINFO;
    dwIndex, dwSize, dwBytesReturned : DWORD;
    //Buf: array[0..1024-1] of BYTE;
    FunctionResult : boolean;
    pspdidd : PSPDeviceInterfaceDetailData;
    spdid :  SP_DEVICE_INTERFACE_DATA;
    spdd :   SP_DEVINFO_DATA;
    hDrive : THandle;
    SDN :    STORAGE_DEVICE_NUMBER;
begin
    Result   := 0;
    IsFloppy := True;

    if StrPos(szDosDeviceName, '\Floppy') = nil then begin
        IsFloppy := False;
    end;

    case (DriveType) of
        DRIVE_REMOVABLE : begin
            if (IsFloppy) then begin
                myguid := GUID_DEVINTERFACE_FLOPPY;
            end else begin
                myguid := GUID_DEVINTERFACE_DISK;
            end;
        end;

        DRIVE_FIXED : begin
            myguid := GUID_DEVINTERFACE_DISK;
        end;

        DRIVE_CDROM : begin
            myguid := GUID_DEVINTERFACE_CDROM;
        end;

        else begin
            exit;
        end;

    end;

    //Get device interface info set handle for all devices attached to system
    myhDevInfo := SetupDiGetClassDevs(@myguid, nil, 0, DIGCF_PRESENT or DIGCF_DEVICEINTERFACE);

    if (cardinal(myhDevInfo) = INVALID_HANDLE_VALUE) then begin
        exit;
    end;

    //Retrieve a context structure for a device interface of a device information set
    dwIndex := 0;

    //pspdidd :=PSP_DEVICE_INTERFACE_DETAIL_DATA(@Buf);
    ZeroMemory(@spdd, SizeOf(spdd));
    spdid.cbSize := SizeOf(spdid);

	 DoLoop := True;
	 while (DoLoop) do begin
        FunctionResult := SetupDiEnumDeviceInterfaces(myhDevInfo, nil, myGUID, dwIndex, spdid);
        if ( not FunctionResult ) then begin
            break;
        end;

        dwSize := 0;
        SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, nil, 0, dwSize, nil); //Check the buffer size

        if (dwSize <> 0) and (dwSize <= 1024) {SizeOf(Buf))} then begin
            GetMem(pspdidd, dwSize);
            try
                pspdidd.cbSize := SizeOf(pspdidd^); //SizeOf(TSPDeviceInterfaceDetailData)
                ZeroMemory(@spdd, SizeOf(spdd));
                spdd.cbSize := SizeOf(spdd);

                FunctionResult := SetupDiGetDeviceInterfaceDetail(myhDevInfo, @spdid, pspdidd, dwSize, dwSize, @spdd);
                if FunctionResult then begin
                    //Open the disk or cdrom or floppy
                    hDrive := INVALID_HANDLE_VALUE;
					 try
                        hDrive := CreateFile(pspdidd.DevicePath, 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                        if (hDrive <> INVALID_HANDLE_VALUE) then begin
                            //Get its device number
                            dwBytesReturned := 0;
                            FunctionResult  := DeviceIoControl(hDrive, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @sdn,
                                SizeOf(sdn), @dwBytesReturned, nil);
                            if FunctionResult then begin
                                if DeviceNumber = longint(sdn.DeviceNumber) then begin
                                    //Match the device number with that of the current device
                                    Result := spdd.DevInst;
                                    break;
                                end;
                            end;
                        end;
                    finally
                        CloseHandle(hDrive);
                    end;
                end;

            finally
                FreeMem(pspdidd);
            end;
        end;

        dwIndex := dwIndex + 1;
    end;

    SetupDiDestroyDeviceInfoList(myhDevInfo);
end;

function TDriveEjector.GetNoDevicesWithSameParentInst(ParentDevInst : Integer) : Integer;
var
    i : Integer;
begin
    Result := -1; //will be inc'ed once when it goes through the one we're comparing to
    for I := 0 to DrivesCount - 1 do begin
        if RemovableDrives[i].ParentDevInst = ParentDevInst then begin
            Inc(Result);
        end;
    end;
end;

function TDriveEjector.GetNoDevicesWithSameProductId(ProductId : string) : Integer;
var
    i : Integer;
begin
    Result := -1; //will be inc'ed once when it goes through the one we're comparing to
    for I := 0 to DrivesCount - 1 do begin
        if RemovableDrives[i].ProductID = ProductID then begin
            Inc(Result);
        end;
    end;
end;

function TDriveEjector.GetParentDriveDevInst(MountPoint : string; var ParentInstNum : Integer) : boolean;
var
    szRootPath, szDevicePath, szVolumeAccessPath : string;
    DeviceNumber : longint;
    hVolume : THandle;
    dwBytesReturned : DWord;
    DriveType : UINT;
    SDN : STORAGE_DEVICE_NUMBER;
    FunctionResultInt : Integer;
    FunctionResultBool : boolean;
    DeviceInst, DevInstParent : DEVINST;
    szDosDeviceName, VolumeName : array[0..MAX_PATH - 1] of char;
begin
    Result := False;

    GetVolumeNameForVolumeMountPoint(PChar(MountPoint), VolumeName, MAX_PATH);
    szRootPath   := VolumeName;
    szDevicePath := ExcludeTrailingPathDelimiter(VolumeName);
    szVolumeAccessPath := ExcludeTrailingPathDelimiter(VolumeName);
    szDevicePath := Copy(szVolumeAccessPath, 5, length(szVolumeAccessPath) - 4);
    DeviceNumber := -1;

    hVolume := INVALID_HANDLE_VALUE;
    try
        //Open the storage volume
        hVolume := CreateFile(PChar(szVolumeAccessPath), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
        if hVolume = INVALID_HANDLE_VALUE then begin
            exit;
        end;

        //Get the volume's device number
        dwBytesReturned    := 0;
        FunctionResultBool := DeviceIoControl(hVolume, IOCTL_STORAGE_GET_DEVICE_NUMBER, nil, 0, @SDN,
            SizeOf(SDN), @dwBytesReturned, nil);
        if FunctionResultBool then begin
            DeviceNumber := SDN.DeviceNumber;
        end;

    finally
        CloseHandle(hVolume);
    end;

    if DeviceNumber = -1 then begin
        exit;
    end;

    //Get the drive type which is required to match the device numbers correctely
    DriveType := GetDriveType(PChar(szRootPath));
    szDosDeviceName[0] := #0;

    //Get the dos device name (like \deviceloppy0) to decide if it's a floppy or not
    FunctionResultInt := QueryDosDevice(PChar(szDevicePath), szDosDeviceName, MAX_PATH);
    if FunctionResultInt = 0 then begin
        exit;
    end;

    //Get the device instance handle of the storage volume by means of a SetupDi enum and matching the device number
    DeviceInst := GetDrivesDevInstByDeviceNumber(DeviceNumber, DriveType, szDosDeviceName);

    if (DeviceInst = 0) then begin
        exit;
    end;

    //Get drives's parent
    DevInstParent := 0;
    CM_Get_Parent(DevInstParent, DeviceInst, 0);

    if DevInstParent > 0 then begin
        ParentInstNum := DevInstParent;
        Result := True;
    end;

end;

procedure TDriveEjector.OnTimer(Sender : TObject);
var
    i : Integer;
begin
    //sysutils.Beep;
    if GetDrivesCount = 0 then begin
        exit;
	 end;
	 if ( not Self.FPolling ) then begin
        Exit;
    end;


    for I := 0 to GetDrivesCount - 1 do begin
        if RemovableDrives[i].IsCardReader then begin
            if CheckIfDriveHasMedia(RemovableDrives[i].DriveMountPoint) then begin
				 if ( not RemovableDrives[i].CardMediaPresent ) then begin //Has changed - generate event
                    RemovableDrives[i].CardMediaPresent := True;
					 if assigned(FOnCardMediaChanged) then begin
						 FOnCardMediaChanged(nil);
                    end;
                end;
            end else begin
				 if RemovableDrives[i].CardMediaPresent then begin  //Has changed - generate event
					 RemovableDrives[i].CardMediaPresent := False;
					 if assigned(FOnCardMediaChanged) then begin
						 FOnCardMediaChanged(nil);
                    end;
                end;
            end;
        end;
    end;

end;

initialization
    //Windows 2000 workaround
    GetVolumePathNamesForVolumeNameW := GetProcAddress(GetModuleHandle('kernel32.dll'), 'GetVolumePathNamesForVolumeNameW');
    if @GetVolumePathNamesForVolumeNameW = nil then begin
		 GetVolumePathNamesForVolumeNameW := @_GetVolumePathNamesForVolumeNameW;
    end;

end.
