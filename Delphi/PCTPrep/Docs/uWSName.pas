unit uWSName;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    StdCtrls, Registry, ShellApi, wsocket, ExtCtrls, FileCtrl, DNSQuery, NB30,
    WinSvc;

const
    WinNTHostNameRegKey: string = '\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\';
    Win9xHostNameRegKey: string = '\SYSTEM\CurrentControlSet\Services\VxD\MSTCP\';
    WinNTComputerDescriptionKey: string = '\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters';
    Win9xComputerDescriptionKey: string = 'System\CurrentControlSet\Services\VxD\VNETSUP\';
    MyRegistryBaseKey = HKey_Local_Machine;
    MyVersionNumber: string = '2.73a';
    MyVersionDate: string = '9 March 2005';
    CRLF = ^M^J;
    MAX_LOG_FILE_SIZE = 512;                //Size in K
    UnRegProgramName: string = 'unreg32.exe';
    UnRegSwitch: string = '/UNREG';
    PostGhostSwitch: string = '/PG:';
    NameSyncSwitch: string = '/NS';
    RebootSwitch: string = '/REBOOT';
    NoRebootSwitch: string = '/NOREBOOT';
    NEW_COMPUTERNAME_SWITCH: string = '/N:';
    UseMyNameSwitch: string = '/UMN';
    ResolveByDNSSwitch: string = '/DNS:';
    UseMACAddressSwitch: string = '/MAC';
    UseMACAddressSwitchII: string = '/!MAC2';
    UseIPAddressSwitch: string = '/IP';
    TestOnlySwitch: string = '/TEST';
    MACPrefixSwitch: string = '/PRE:';
    SetDiskLabelSwitch: string = '/SDL';
    SetMyComputerNameSwitch: string = '/MCN';
    SetMyComputerDescriptionSwitch: string = '/SCD';
    SetLogOnToSwitch: string = '/LOT';
    ChangeHostNameOnlySwitch: string = '/CHO';
    AlwaysDoRenameSwitch: string = '/ADR';
    RenameComputerInDomainSwitch: string = '/RCID';
    DomainUserIDSwitch: string = '/USER:';
    DomainPasswordSwitch: string = '/PASS:';
    ReadFromDataFileSwitch: string = '/RDF:';
    DataFileKeySwitch: string = '/DFK:';
    WebPage: string = 'http://mystuff.clarke.co.nz';
    HelpFileName: string = 'WSName.html';
    LogFileName: string = 'WSName.Log';
    AmounttoGrowForm = 180;
    DefaultFormHeightSmall = 93;
    BorderAllowance = 5;
    FormTopMarginSize = 27;
    FormMoreLabelSmall: string = '&More >>';
    FormMoreLabelBig: string = '&Less <<';
    WSManagerDLL: string = 'WMSCHAPI.dll';
    MaxPrefixLength = 3;
    DNS_TIMEOUT_INTERVAL = 5000; //5 Seconds
    MAX_LENGTH_COMPUTER_NAME = 15;
    OS_WIN95: string = 'WIN95';
    OS_WIN98: string = 'WIN98';
    OS_WINME: string = 'WINME';
    OS_WINNT: string = 'WINNT';
    OS_WIN2K: string = 'WIN2K';
    OS_WINXP: string = 'WINXP';
    OS_WIN2K3: string = 'WIN2K3';
    SILENT_IP_ADDRESS: string = '%IP';
    SILENT_USER_NAME: string = '%USERID';
    SILENT_OS_TYPE: string = '%OSVER';
    SILENT_MAC_ADDRESS: string = '%MAC';
    SILENT_MAC_ADDRESS_II: string = '%MAC2';
    SILENT_RANDOM_NAME: string = '%RANDOM';
    SILENT_REVERSE_DNS: string = '%DNS';

    MAX_HOSTNAME_LEN           = 128; { from IPTYPES.H }
    MAX_DOMAIN_NAME_LEN        = 128;
    MAX_SCOPE_ID_LEN           = 256;
    MAX_ADAPTER_NAME_LENGTH    = 256;
    MAX_ADAPTER_DESCRIPTION_LENGTH = 128;
    MAX_ADAPTER_ADDRESS_LENGTH = 8;

    // For ExtractFromGetAdapterInformation
    ADAP_ADAPTER_NUMBER = 0;
    ADAP_COMBOINDEX     = 1;
    ADAP_ADAPTER_NAME   = 2;
    ADAP_DESCRIPTION    = 3;
    ADAP_ADAPTER_ADDRESS = 4;
    ADAP_INDEX          = 5;
    ADAP_TYPE           = 6;
    ADAP_DHCP           = 7;
    ADAP_CURRENT_IP     = 8;
    ADAP_IP_ADDRESSES   = 9;
    ADAP_GATEWAYS       = 10;
    ADAP_DHCP_SERVERS   = 11;
    ADAP_HAS_WINS       = 12;
    ADAP_PRIMARY_WINS   = 13;
    ADAP_SECONDARY_WINS = 14;
    ADAP_LEASE_OBTAINED = 15;
    ADAP_LEASE_EXPIRES  = 16;

    // For DWSplit
    qoPROCESS    = $0001;
    qoNOBEGINEND = $0002;
    qoNOCRLF     = $0004;

    // For MagicChango
    TRIM_LEFT  = 0;
    TRIM_RIGHT = 1;


type
    TIPAddressString = array[0..4 * 4 - 1] of char;
    PIPAddrString    = ^TIPAddrString;

    TIPAddrString = record
        Next:      PIPAddrString;
        IPAddress: TIPAddressString;
        IPMask:    TIPAddressString;
        Context:   Integer;
    end;

    PFixedInfo = ^TFixedInfo;

    TFixedInfo = record { FIXED_INFO }
        HostName:         array[0..MAX_HOSTNAME_LEN + 3] of char;
        DomainName:       array[0..MAX_DOMAIN_NAME_LEN + 3] of char;
        CurrentDNSServer: PIPAddrString;
        DNSServerList:    TIPAddrString;
        NodeType:         Integer;
        ScopeId:          array[0..MAX_SCOPE_ID_LEN + 3] of char;
        EnableRouting:    Integer;
        EnableProxy:      Integer;
        EnableDNS:        Integer;
    end;

    PIPAdapterInfo = ^TIPAdapterInfo;

    TIPAdapterInfo = record { IP_ADAPTER_INFO }
        Next:          PIPAdapterInfo;
        ComboIndex:    Integer;
        AdapterName:   array[0..MAX_ADAPTER_NAME_LENGTH + 3] of char;
        Description:   array[0..MAX_ADAPTER_DESCRIPTION_LENGTH + 3] of char;
        AddressLength: Integer;
        Address:       array[1..MAX_ADAPTER_ADDRESS_LENGTH] of byte;
        Index:         Integer;
        _Type:         Integer;
        DHCPEnabled:   Integer;
        CurrentIPAddress: PIPAddrString;
        IPAddressList: TIPAddrString;
        GatewayList:   TIPAddrString;
        DHCPServer:    TIPAddrString;
        HaveWINS:      Bool;
        PrimaryWINSServer: TIPAddrString;
        SecondaryWINSServer: TIPAddrString;
        LeaseObtained: Integer;
        LeaseExpires:  Integer;
    end;

var
    ComputerName, PathtoUnRegProgram, OSVer, OSVerDetailed, UserName,
    NovellClientVersion, TempDirectory, LogFilePathandName, HostName,
    DNSServer, AsEnteredComputerName, sComputerDescription,
    strDomainUserID, strDomainPassword, strDataFileName, strDataFileKey : string;
    TaskUnReg, TaskHelpStuff, TaskPostGhost, TaskResolvebyReverseDNS,
    TaskUseMACAddressforName, TaskNameSync, TaskNoReboot, TaskReboot,
    TaskSilent, LocalAdminRights, ShowGUI, TaskPrefixMACAddress,
    TaskTestOnly, TaskSetDiskLabel, TaskUseIPAddressforName, TaskAlwaysDoRename,
    TaskUseMyName, TaskSetMyComputerName, TaskLogOnTo, TaskChangeHostNameOnly,
    TaskSetMyComputerDescription, TaskRenameComputerInDomain, TaskReadFromDataFile,
    UseAlternateMACAddressRoutine, blnNetWareClientInstalled : boolean;
    FormHeightSmall : Integer;


function GetFileSizeEx(const filename : string) : int64;
function SetPrivilege(privilegeName : string; enable : boolean) : boolean;
function WinExit(flags : Integer) : boolean;
function fSetComputerName(sNewName : string) : boolean;
function RunProcess(const AppPath, AppParams : string; Visibility : Word; MustWait : boolean) : DWord;
function CheckValidityofCompterName(ComputerNametoCheck : string) : boolean;
function ReadAsStringFromRegistry(rootkey : HKEY; basekey, keyvalue : string) : string;
function ReadNovellClientDetails : string;
function IsDLLOnSystem(DLLName : string) : boolean;
function CheckInTrim(targetstring : string; maxsize : Integer) : string;
function RenameComputer(newname : string; UnRegisterFromNDS, RebootOnCompletion : boolean) : boolean;
function GetMACAddress(AdapterNumber : Integer) : string;
function IsValidIPAddress(address : string) : boolean;
function GetIPAddress(intIPAddressIndex : Integer) : string;
function GetMACAddressPrefix : string;
function GetServicePackVersion : string;
function InStrRev(Start : Integer; const BigStr, SmallStr : string) : Integer;
function OSVer_To_Friendly_Name(strOSVer : string) : string;
procedure SetLogOnTo(NewName : string);
procedure SetHostName(HostName : string);
procedure SetNVHostName(HostName : string);
procedure MainCodeBlock;
procedure ShowHelpFile;
procedure ExtractRes(ResType, ResName, ResNewName : string);
procedure AppendtoLogFile(s : string);
procedure ExitRoutine(exitcode : byte);
function GetAdapterInformation : TStringList;
function GetAdapterInformationII : TStringList;
procedure DW_Split(aValue : string; aDelimiter : char; var Result : TStrings; Flag : Integer = $0001);
function ExtractFromGetAdapterInformation(tlAdaperInfo : TStringList; intAdapterIndex, intDataIndex : Integer) : string;
function GetMACAddressLegacy(AdapterNumber : Integer) : string;
function ReverseDNSLookup(strIPAddress, strDNSServer : string; intPTRTimeOut : Integer; out strResult : string) : boolean;
function GetDNSUsingGetNetworkParams : string;
function GetDNSUsingScreenScraping : string;
function GetDNSServer : string;
function OSVersionToTLA : string;
function ReplacementStringSizeSpecified(strMarker, strInput : string; out intStringSize : Integer;
    out strOutput : string) : boolean;
function MagicChango(strInput, sID, strReplacementString : string; iTruncateSide : Integer) : string;
function PadIPAddress(strIPAddress : string) : string;
function MyStrtoInt(x : string; blnStrict : boolean) : Integer;
function PosX(Substr : string; S : string) : Integer;
function GenerateRandomName(iLength : Integer) : string;

implementation

type
    TInstance = class(TObject)
        intPTRResult : Integer;
        Timer1 :    TTimer;
        DNSQuery1 : TDNSQuery;
        procedure PTRQueryOnTimeOut(Sender : TObject);
        procedure DnsQuery1RequestDone(Sender : TObject; Error : Word);
    end;



function GetFileSizeEx(const filename : string) : int64;
var
    SRec :      TSearchrec;
    converter : packed record
        case boolean of
            False : (n : int64);
            True : (low, high : DWORD);
    end;
begin
    if FindFirst(filename, faAnyfile, SRec) = 0 then begin
        converter.low := SRec.FindData.nFileSizeLow;
        converter.high := SRec.FindData.nFileSizeHigh;
        Result := converter.n;
        FindClose(SRec);
    end else begin
        Result := -1;
    end;
end;

function SetPrivilege(privilegeName : string; enable : boolean) : boolean;
var
    tpPrev, tp : TTokenPrivileges;
    token :      THandle;
    dwRetLen :   DWord;
begin
    Result := False;
    OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, token);
    tp.PrivilegeCount := 1;
    if LookupPrivilegeValue(nil, PChar(privilegeName), tp.Privileges[0].LUID) then begin
        if enable then begin
            tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
        end else begin
            tp.Privileges[0].Attributes := 0;
        end;
        dwRetLen := 0;
        Result   := AdjustTokenPrivileges(token, False, tp, SizeOf(tpPrev), tpPrev, dwRetLen);
    end;
    CloseHandle(token);
end;


function WinExit(flags : Integer) : boolean;
{   Call WinExit(flags)

   Where flags must be one of the following:

   EWX_LOGOFF     - Shuts down processes and logs user off
   EWX_REBOOT     - Shuts down the restarts the system
   EWX_SHUTDOWN   - Shuts down system

   The following attributes may be combined (OR'd) with above flags

   EWX_POWEROFF  - shuts down system and turns off the power.
   EWX_FORCE     - forces processes to terminate.

   Example:
           WinReboot1.WinExit(EWX_REBOOT or EWX_FORCE);      }

begin
    Result := True;
    SetPrivilege('SeShutdownPrivilege', True);
    if not ExitWindowsEx(flags, 0) then begin
        Result := False;
    end;
    SetPrivilege('SeShutdownPrivilege', False);
end;


  {function WinExit (iFlags: integer) : Boolean; 
begin
 result := true;
 if SetPrivilege ('SeShutdownPrivilege', true) then
 begin
   if (not ExitWindowsEx (iFlags, 0)) then
   begin
     // handle errors...
     result := False 
   end;
   SetPrivilege ('SeShutdownPrivilege', False)
 end
 else
 begin
   // handle errors... 
   result := False
 end
end;
}


{*****************************[ RUNPROCESS ] ***********************************
*
* Type: Function
* Use: To launch an application and optionally wait until the launched
* Application is terminated before running the rest of the code.
*
* PARAMETERS:
*
* AppPath: The full path and Application Name to run ie. c:\winnt\notepad.exe
*
* AppParams: Commandline params to send to the app.
*
* Visibility:
* Can have any of the following values:
*   Value    Meaning
*   SW_HIDE    Hides the window and activates another window.
*   SW_MAXIMIZE    Maximizes the specified window.
*   SW_MINIMIZE    Minimizes the specified window and activates the next top-level
*     window in the Z order.
*   SW_RESTORE    Activates and displays the window. If the window is minimized or
*     maximized, Windows restores it to its original size and position. An
*     application should specify this flag when restoring a minimized window.
*   SW_SHOW    Activates the window and displays it in its current size and position.
*   SW_SHOWDEFAULT    Sets the show state based on the SW_ flag specified in the
*     STARTUPINFO structure passed to the CreateProcess function by the program
*     that started the application.
*   SW_SHOWMAXIMIZED    Activates the window and displays it as a maximized window.
*   SW_SHOWMINIMIZED    Activates the window and displays it as a minimized window.
*   SW_SHOWMINNOACTIVE    Displays the window as a minimized window. The active
*     window remains active.
*   SW_SHOWNA    Displays the window in its current state. The active window remains
*     active.
*   SW_SHOWNOACTIVATE    Displays a window in its most recent size and position.
*     The active window remains active.
*   SW_SHOWNORMAL    Activates and displays a window. If the window is minimized or
*     maximized, Windows restores it to its original size and position. An
*     application should specify this flag when displaying the window for the
*     first time.
*
* MustWait: true if the code must be paused until the termination of the launched
*   Application. false if the code must run directly after launching the app.
*
********************************************************************************}

function RunProcess(const AppPath, AppParams : string; Visibility : Word; MustWait : boolean) : DWord;
var
    SI :   TStartupInfo;
    PI :   TProcessInformation;
    Proc : THandle;
begin
    FillChar(SI, SizeOf(SI), 0);
    SI.cb := SizeOf(SI);
    SI.wShowWindow := Visibility;
    //if not CreateProcess(PChar(AppPath), PChar(AppParams), nil, nil, false, Normal_Priority_Class, nil, nil, SI, PI) then
    //  raise Exception.CreateFmt('Failed to excecute program. Error Code %d', [GetLastError]);
    // DJC - Above two lines remmed out following line added so no error is posted
    CreateProcess(PChar(AppPath), PChar(AppParams), nil, nil, False, Normal_Priority_Class, nil, nil, SI, PI);
    Proc := PI.hProcess;
    CloseHandle(PI.hThread);
    if MustWait then begin
        if WaitForSingleObject(Proc, Infinite) <> Wait_Failed then begin
            GetExitCodeProcess(Proc, Result);
        end;
    end;
    CloseHandle(Proc);
end;

function FindPathtoFile(Target : string) : string;
const
    MAX_SIZE = 500;
var
    PathandFileName : array[0..MAX_SIZE] of char;
    FileNamePart : PChar;
    retcode : Integer;
begin
    retcode := SearchPath(nil, PChar(Target), nil, MAX_SIZE, @PathandFileName, FileNamePart);
    if retcode <> 0 then begin
        Result := PathandFileName;
    end else begin
        Result := '';
    end;
end;


function InStrRev(Start : Integer; const BigStr, SmallStr : string) : Integer;
var
    L9, L8, P : Integer;
    BigL, SmallL : Integer;
    C : char;
begin
    Result := 0; // Set Default

    // Take String Lengths
    BigL   := Length(BigStr);
    SmallL := Length(SmallStr);

    // 0 Starts from end of String
    if Start <= 0 then begin
        Start := BigL;
    end;

    if Start > BigL then begin
        Start := BigL;
    end;

    // '' Target always returns 0
    if BigL = 0 then begin
        Exit;
    end;

    // '' Convention returns Start
    if SmallL = 0 then begin
        Result := Start;
        Exit;
    end;

    // Take First Char of Search String
    C := SmallStr[1];

    // Run back if BigStr not long enough
    if (Start + SmallL - 1) > BigL then begin
        Start := BigL - SmallL + 1;
    end;

    // Hunt Backwards for a match
    for L9 := Start downto 1 do begin
        if BigStr[L9] = C then  // If first Char Found
        begin
            P := L9 + SmallL - 1;
            for L8 := SmallL downto 2 do // Scan Backwards
            begin
                if BigStr[P] <> SmallStr[L8] then begin
                    Break;
                end;
                P := P - 1;
            end;
            // Success - we know first Char matches
            if P = L9 then begin
                Result := L9;
                Break;
            end;
        end;
    end;

end;{InStrRev}

function IsDLLOnSystem(DLLName : string) : boolean;
var
    ret :  Integer;
    good : boolean;
    //tmpstr: integer;
begin
    ret  := LoadLibrary(PChar(DLLNAME));
    //tmpstr:=GetlastError();
    Good := ret > 0;
    if good then begin
        FreeLibrary(ret);
    end;
    Result := Good;
end;

function IsAdmin : boolean;
var
    hSC : SC_HANDLE;
begin
    hSC    := OpenSCManager(nil, nil, GENERIC_READ or GENERIC_WRITE or GENERIC_EXECUTE);
    Result := hSC <> 0;
    if Result then begin
        CloseServiceHandle(hSC);
    end;
end;

function IsAdminX : boolean;
    // Returns TRUE if the user is an Administrator
const
    SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
    SECURITY_BUILTIN_DOMAIN_RID = $00000020;
    DOMAIN_ALIAS_RID_ADMINS     = $00000220;

var
    hAccessToken : THandle;
    ptgGroups : PTokenGroups;
    dwInfoBufferSize : DWORD;
    psidAdministrators : PSID;
    x : Integer;
    bSuccess : boolean;

begin
    Result   := False;
    bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, hAccessToken);
    if not bSuccess then begin
        if GetLastError = ERROR_NO_TOKEN then begin
            bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hAccessToken);
        end;
    end;
    if bSuccess then begin
        GetMem(ptgGroups, 1024);
        bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024, dwInfoBufferSize);
        CloseHandle(hAccessToken);
        if bSuccess then begin
            AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0,
                0, 0, 0, 0, 0, psidAdministrators);
            for x := 0 to ptgGroups.GroupCount - 1 do begin
                if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then begin
                    Result := True;
                    Break;
                end;
            end;
            FreeSid(psidAdministrators);
        end;
        FreeMem(ptgGroups);
    end;
end;

function GetOSVersion(blnDetailed : boolean) : string;
var
    VersionInfo : TOSVersionInfo;
begin
    Result := 'Unknown';
    VersionInfo.dwOSVersionInfoSize := Sizeof(TOSVersionInfo);
    GetVersionEx(VersionInfo);
    case VersionInfo.dwPlatformID of
        VER_PLATFORM_WIN32S : begin
            Result := 'WIN32';
        end;
        VER_PLATFORM_WIN32_WINDOWS : begin
            Result := 'WIN9X';
            if blnDetailed then begin
                if (VersionInfo.dwMinorVersion = 0) then begin
                    Result := OS_WIN95;
                end else
                if (VersionInfo.dwMinorVersion = 10) then begin
                    Result := OS_WIN98;
                end else
                if (VersionInfo.dwMinorVersion = 90) then begin
                    Result := OS_WINME;
                end else begin
                    Result := OS_WIN95;
                end;
            end;
        end;
        VER_PLATFORM_WIN32_NT : begin
            Result := OS_WINNT;
            if blnDetailed then begin
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 2) then begin
                    Result := OS_WIN2K3;
                end else
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 1) then begin
                    Result := OS_WINXP;
                end else
                if (VersionInfo.dwMajorVersion = 5) and (VersionInfo.dwMinorVersion = 0) then begin
                    Result := OS_WIN2K;
                end else begin
                    Result := OS_WINNT;
                end;
            end;
        end;
    end;
end;

function GetServicePackVersion : string;
var
    osvi : TOSVersionInfo;
begin
    osvi.dwOSVersionInfoSize := SizeOf(Osvi);
    if GetVersionEX(osvi) then begin
        Result := osvi.szCSDVersion;
    end else begin
        Result := '';
    end;
end;

function GetWorkstationName : string;
var
    CompName : PChar;
    BuffSize : Dword;
begin
    Buffsize := 20;
    CompName := StrAlloc(Buffsize);
    GetComputerName(CompName, BuffSize);
    Result := StrPas(CompName);
end;

function fSetComputerName(sNewName : string) : boolean;
var
    ComputerName : array[0..MAX_COMPUTERNAME_LENGTH + 1] of char;  // holds the name
begin
    {copy the specified name to the ComputerName buffer}
    StrPCopy(ComputerName, sNewName);
    if TaskTestOnly then begin
        Result := True;
    end else begin
        Result := SetComputerName(ComputerName);
    end;
end;

function fSetComputerNameEx(strNewName : string) : boolean;
    //http://msdn.microsoft.com/library/default.asp?url=/library/en-us/sysinfo/sysinfo_84s8.asp
type
    Type_SetComputerNameEx = function(nType : Integer; newname : string) : longint stdcall;
var
    _SetComputerNameEx : Type_SetComputerNameEx;
    lngResultCode, lngModuleHandle : longint;
begin
    fSetComputerNameEx := False;
    lngModuleHandle := LoadLibrary(PChar('kernel32.dll'));
    @_SetComputerNameEx := GetProcAddress(lngModuleHandle, PChar('SetComputerNameExA'));
    lngResultCode := _SetComputerNameEx(5, strNewName);
    FreeLibrary(lngModuleHandle);
    if lngResultCode <> 0 then begin
        fSetComputerNameEx := True;
    end;
end;

function RenameComputerInDomain(strTargetComputer, strNewComputerName, strUserID, strPassword : string) : boolean;
type
    Type_NetRenameMachineInDomain = function(lpserver, machinename, lpaccount, passwrd : PWideChar;
            foptions : longint) : longint stdcall;
var
    pwcNewComputerName, pwcUserID, pwcPassword,
    pwcTargetComputer : PWideChar;
    lngResultCode :     longint;
    intResultCode :     Integer;
    _NetRenameMachineInDomain : Type_NetRenameMachineInDomain;
begin
    RenameComputerInDomain := False;
    pwcNewComputerName := nil;
    pwcUserID   := nil;
    pwcPassword := nil;
    pwcTargetComputer := nil;
    try
        intResultCode := LoadLibrary(PChar('netapi32.dll'));
        @_NetRenameMachineInDomain := GetProcAddress(intResultCode, PChar('NetRenameMachineInDomain'));
        GetMem(pwcNewComputerName, 2 * Length(strNewComputerName) + 2);
        GetMem(pwcUserID, 2 * Length(strUserID) + 2);
        GetMem(pwcPassword, 2 * Length(strPassword) + 2);
        GetMem(pwcTargetComputer, 2 * Length(strTargetComputer) + 2);
        StringToWideChar(strNewComputerName, pwcNewComputerName, Length(strNewComputerName) + 2);
        StringToWideChar(strUserID, pwcUserID, Length(strUserID) + 2);
        StringToWideChar(strPassword, pwcPassword, Length(strPassword) + 2);
        StringToWideChar(strTargetComputer, pwcTargetComputer, Length(strTargetComputer) + 2);
        lngResultCode := _NetRenameMachineInDomain(pwcTargetComputer, pwcNewComputerName, pwcUserID, pwcPassword, 2);
        FreeLibrary(intResultCode);
    finally
        FreeMem(pwcNewComputerName);
        FreeMem(pwcUserID);
        FreeMem(pwcPassword);
        FreeMem(pwcTargetComputer);
    end;
    if lngResultCode = 0 then begin
        RenameComputerInDomain := True;
    end else begin
        AppendToLogFile('Call to Rename Computer in Domain returned error : ' + IntToStr(lngResultCode));
        AppendToLogFile('Refer to http://msdn.microsoft.com/library/default.asp?url=/library/en-us/netmgmt/netmgmt/network_management_error_codes.asp');
    end;
end;


function GetHostName : string;
var
    Reg : TRegistry;
begin
    Reg := TRegistry.Create;
    Reg.RootKey := HKey_Local_Machine;
    if GetOSVersion(False) = OS_WINNT then begin
        Reg.OpenKey(WinNTHostNameRegKey, True);
    end else begin
        Reg.OpenKey(Win9xHostNameRegKey, True);
    end;
    Result := Reg.ReadString('Hostname');
    Reg.Free;
end;

procedure SetHostName(HostName : string);
var
    Reg : TRegistry;
begin
    if not TaskTestOnly then begin
        Reg := TRegistry.Create;
        Reg.RootKey := HKey_Local_Machine;
        if GetOSVersion(False) = OS_WINNT then begin
            Reg.OpenKey(WinNTHostNameRegKey, True);
        end else begin
            Reg.OpenKey(Win9xHostNameRegKey, True);
        end;
        Reg.WriteString('Hostname', HostName);
        Reg.Free;
    end;
end;


procedure SetNVHostName(HostName : string);
var
    Reg : TRegistry;
begin
    if not TaskTestOnly then begin
        AppendToLogFile('SetNVHostName             : Setting "NV HostName" value for Novell Client');
        Reg := TRegistry.Create;
        Reg.RootKey := HKey_Local_Machine;
        if GetOSVersion(False) = OS_WINNT then begin
            Reg.OpenKey(WinNTHostNameRegKey, True);
        end else begin
            Reg.OpenKey(Win9xHostNameRegKey, True);
        end;
        Reg.WriteString('NV Hostname', HostName);
        Reg.Free;
    end;
end;

procedure SetLogOnTo(NewName : string);
var
    Reg : TRegistry;
begin
    AppendToLogFile('Set Log On To             : Setting default target for local logon to ' + NewName);

    if not TaskTestOnly then begin
        if GetOSVersion(False) = OS_WINNT then begin
            Reg := TRegistry.Create;
            Reg.RootKey := HKEY_LOCAL_MACHINE;
            Reg.OpenKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon', True);
            Reg.WriteString('DefaultDomainName', NewName);
            Reg.Free;
        end else begin
            AppendToLogFile('Set Log On To             : This feature requires Windows NT or Windows 2000');
        end;
    end;
end;

function GetExplorerVersion : string;
var
    Reg : TRegistry;
    strExpVersion : string;
begin
    strExpVersion := '0';
    Reg := TRegistry.Create;
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    Reg.OpenKey('\Software\Microsoft\Internet Explorer', True);
    strExpVersion := Reg.ReadString('Version');
    Reg.Free;
    GetExplorerVersion := strExpVersion;
end;

function GetMajorExplorerVersionInt : Integer;
var
    strExpVersion : string;
begin
    strExpVersion := '';
    strExpVersion := GetExplorerVersion;
    if length(strExpVersion) < 1 then begin
        strExpVersion := '0';
    end;
    if not (strExpVersion[1] in ['0'..'9']) then begin
        strExpVersion := '0';
    end;
    GetMajorExplorerVersionInt := StrToInt(strExpVersion[1]);
end;

function GetWindowsSystemDirectory : string;
var
    arrTemp : array [0..MAX_PATH + 1] of char;
begin
    Result := '';
    if (GetSystemDirectory(arrTemp, SizeOf(arrTemp)) > 0) then begin
        if (Copy(arrTemp, Length(arrTemp), 1) <> '\') then begin
            StrCat(arrTemp, '\');
        end;
        Result := arrTemp;
    end;
end;

procedure SetMyComputerName(NewName : string);
var
    Reg :  TRegistry;
    IE6orBetter : boolean;
    strLocalizedString : string;
    intI : Integer;
begin
    //http://www.jsifaq.com/SUBE/tip2000/rh2001.htm
    AppendToLogFile('Set My Computer Name      : Renaming "My Computer" on the desktop to ' + NewName);
    if not TaskTestOnly then begin
        Reg := TRegistry.Create;
        if OSver = 'WIN9X' then begin
            AppendToLogFile('Set My Computer Name      : Updating HKLM\Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}');
            Reg.RootKey := HKEY_LOCAL_MACHINE;
            Reg.OpenKey('Software\Classes\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}', True);
            Reg.WriteString('', NewName);
            AppendToLogFile('Set My Computer Name      : Updating HKCR\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}');
            Reg.RootKey := HKEY_CLASSES_ROOT;
            Reg.OpenKey('CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}', True);
            Reg.WriteString('', NewName);
        end         //End of WIN9X section
        else begin  //Must be WinNT or better
            AppendToLogFile('Set My Computer Name      : Updating HKCR\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}');
            AppendToLogFile('Set My Computer Name      : Refer http://www.jsifaq.com/SUBE/tip2000/rh2001.htm');
            Reg.RootKey := HKEY_CLASSES_ROOT;
            Reg.OpenKey('\CLSID\{20D04FE0-3AEA-1069-A2D8-08002B30309D}', True);
            Reg.WriteExpandString('', '%ComputerName%');
            if (OSVerDetailed <> OS_WINNT) then begin
                //Additional work required for W2K and above
                IE6orBetter := False;
                if GetMajorExplorerVersionInt > 5 then begin
                    IE6orBetter := True;
                end;
                if (OSVerDetailed = 'WIN2K') and not IE6orBetter then begin
                    strLocalizedString := Reg.ReadString('LocalizedString');
                    AppendToLogFile('Set My Computer Name      : LocalizedString is ' + strLocalizedString);
                    intI := InStrRev(0, strLocalizedString, ',');
                    if intI <> 0 then begin
                        strLocalizedString := Copy(strLocalizedString, 1, intI) + '%ComputerName%';
                        AppendToLogFile('Set My Computer Name      : Setting LocalizedString to ' + strLocalizedString);
                        Reg.WriteExpandString('LocalizedString', strLocalizedString);
                    end else begin
                        AppendToLogFile('Set My Computer Name      : Error! - LocalizedString contained an unexpected string');
                    end;
                end else begin
                    Reg.WriteExpandString('LocalizedString', '%ComputerName%');
                end;
            end;
        end;        //End of WinNT, 2K, XP
        Reg.Free;
    end; //End TestOnly
end;

procedure SetMyComputerDescription(NewName : string);
var
    Reg : TRegistry;
begin
    AppendToLogFile('Set Computer Description  : Setting computer description to "' + NewName + '" [' +
        IntToStr(Length(NewName)) + ']');
    if Length(NewName) > 256 then begin
        AppendToLogFile('Set Computer Description  : Truncating description to 256 characters');
        NewName := Copy(NewName, 1, 256);
        AppendToLogFile('Set Computer Description  : Now Setting computer description to "' + NewName + '"');
    end;
    if not TaskTestOnly then begin
        if OSver = 'WIN9X' then begin
            Reg := TRegistry.Create;
            Reg.RootKey := HKEY_LOCAL_MACHINE;
            Reg.OpenKey(Win9xComputerDescriptionKey, True);
            Reg.WriteString('Comment', NewName);
            Reg.Free;
        end else begin
            Reg := TRegistry.Create;
            Reg.RootKey := HKEY_LOCAL_MACHINE;
            Reg.OpenKey(WinNTComputerDescriptionKey, True);
            Reg.WriteString('srvcomment', NewName);
            Reg.Free;
        end;
    end;
end;

function GetCurrentUserName : string;
var
    UserName : string;
    NameSize : DWORD;
begin
    Result   := '';
    NameSize := 255;
    SetLength(UserName, 254);
    if GetUserName(PChar(UserName), NameSize) then begin
        SetLength(UserName, NameSize);
        Result := Trim(UserName);
    end;
end;

function GenerateRandomName(iLength : Integer) : string;
const
    Codes64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';


var
    i, x :   Integer;
    s1, s2 : string;
begin
    s1 := Codes64;
    s2 := '';
    Randomize;
    for i := 0 to iLength - 1 do begin
        x  := Random(Length(s1));
        x  := Length(s1) - x;
        s2 := s2 + s1[x];
        s1 := Copy(s1, 1, x - 1) + Copy(s1, x + 1, Length(s1));
    end;
    Result := s2;
end;

function GetTempDirectory : string;
var
    TempDirectory : PChar;
    BuffSize : Dword;
    s : string;
begin
    Buffsize      := 255;
    TempDirectory := StrAlloc(Buffsize);
    GetTempPath(BuffSize, TempDirectory);
    s := StrPas(TempDirectory);
    if s[length(s)] <> '\' then begin
        s := s + '\';
    end;
    Result := s;
end;

procedure AppendtoLogFile(s : string);
var
    f : textfile;
begin
    assignfile(f, LogFilePathandName);
    if fileexists(LogFilePathandName) then begin
        append(f);
    end else begin
        rewrite(f);
    end;
    writeln(f, DateTimetoStr(Now) + ' : ' + s);
    flush(f);
    closefile(f);
end;

function ReadAsStringFromRegistry(rootkey : HKEY; basekey, keyvalue : string) : string;
var
    reg :     TRegistry;
    keytype : TRegDataType;

begin
    Reg := TRegistry.Create;
    Reg.RootKey := rootkey;
    Reg.OpenKey(basekey, True);
    Result := '';
    if Reg.ValueExists(keyvalue) then begin           // Check key exists first to avoid errors
        keytype := Reg.GetDataType(keyvalue);
        if keytype = rdInteger then begin
            Result := IntToStr(Reg.ReadInteger(keyvalue));
        end else
        if keytype = rdString then begin
            Result := Reg.Readstring(keyvalue);
        end;
    end;
    Reg.Free;
end;

procedure CheckCommandLine;
var
    intI :    Integer;
    strTEMP : string;
begin
    TaskUnReg     := False;
    TaskHelpStuff := False;
    TaskPostGhost := False;
    TaskNameSync  := False;
    TaskReboot    := False;
    TaskNoReboot  := False;
    TaskResolvebyReverseDNS := False;
    TaskUseMACAddressforName := False;
    UseAlternateMACAddressRoutine := False;
    TaskPrefixMACAddress := False;
    TaskTestOnly  := False;
    TaskSetDiskLabel := False;
    TaskUseIPAddressforName := False;
    TaskSetMyComputerName := False;
    TaskUseMyName := False;
    TaskLogOnTo   := False;
    TaskChangeHostNameOnly := False;
    TaskAlwaysDoRename := False;
    TaskSetMyComputerDescription := False;
    TaskRenameComputerInDomain := False;
    TaskReadFromDataFile := False;
    AsEnteredComputerName := '';
    sComputerDescription := '';
    if Pos(UpperCase(UnRegSwitch), UpperCase(strPas(cmdline))) <> 0 then begin
        TaskUnReg := True;
    end;
    if (Pos(UpperCase('/H'), UpperCase(strPas(cmdline))) <> 0) or (Pos(UpperCase('/?'), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskHelpStuff := True;
    end;
    if (Pos(UpperCase(PostGhostSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskPostGhost := True;
    end;
    if (Pos(UpperCase(NameSyncSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskNameSync := True;
    end;
    if (Pos(UpperCase(RebootSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskReboot := True;
    end;
    if (Pos(UpperCase(NoRebootSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskNoReboot := True;
    end;
    if (Pos(UpperCase(NEW_COMPUTERNAME_SWITCH), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskSilent := True;
    end;
    if (Pos(UpperCase(ResolveByDNSSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskResolvebyReverseDNS := True;
    end;
    if (Pos(UpperCase(UseMACAddressSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskUseMACAddressforName := True;
    end;
    if (Pos(UpperCase(UseMACAddressSwitchII), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskUseMACAddressforName      := True;
        UseAlternateMACAddressRoutine := True;
    end;
    if (Pos(UpperCase(MACPrefixSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskPrefixMACAddress := True;
    end;
    if (Pos(UpperCase(TestOnlySwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskTestOnly := True;
    end;
    if (Pos(UpperCase(SetDiskLabelSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskSetDiskLabel := True;
    end;
    if (Pos(UpperCase(UseIPAddressSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskUseIPAddressforName := True;
    end;
    if (Pos(UpperCase(SetMyComputerNameSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskSetMyComputerName := True;
    end;
    if (Pos(UpperCase(UseMyNameSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskUseMyName := True;
    end;
    if (Pos(UpperCase(SetLogOnToSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskLogOnTo := True;
    end;
    if (Pos(UpperCase(ChangeHostNameOnlySwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskChangeHostNameOnly := True;
    end;
    if (Pos(UpperCase(AlwaysDoRenameSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskAlwaysDoRename := True;
    end;
    if (Pos(UpperCase(SetMyComputerDescriptionSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskSetMyComputerDescription := True;
        if (Pos(UpperCase(SetMyComputerDescriptionSwitch) + ':', UpperCase(strPas(cmdline))) <> 0) then begin
            strTEMP := strPas(cmdline);
            intI    := Pos(SetMyComputerDescriptionSwitch + ':', UpperCase(strTEMP));
            strTEMP := copy(strTEMP, intI + Length(SetMyComputerDescriptionSwitch + ':'), length(strTEMP) - intI -
                Length(SetMyComputerDescriptionSwitch + ':') + 1);
            if length(strTEMP) > 0 then begin    // Catch switch with no value
                if strTEMP[1] = '"' then begin   // Handle filenames with spaces in path
                    strTEMP := Copy(strTEMP, 2, Length(strTEMP) - 1);
                    intI    := Pos('"', strTEMP);     //Find position of closing quote
                    if intI <> 0 then begin
                        strTEMP := copy(strTEMP, 1, intI - 1);
                    end else begin
                        //Add error handling for no closing quote here
                    end;
                end else begin                       // No quotes to worry about
                    intI := Pos(' ', strTEMP);
                    if intI <> 0 then begin
                        strTEMP := copy(strTEMP, 1, intI - 1);
                    end;
                end;
                sComputerDescription := strTEMP;
            end;
        end;
    end;
    if (Pos(UpperCase(RenameComputerInDomainSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskRenameComputerInDomain := True;
    end;
    if (Pos(UpperCase(DomainUserIDSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        strTEMP := strPas(cmdline);
        intI    := Pos(DomainUserIDSwitch, UpperCase(strTEMP));
        strTEMP := copy(strTEMP, intI + Length(DomainUserIDSwitch), length(strTEMP) - intI - Length(DomainUserIDSwitch) + 1);
        intI    := Pos(' ', strTEMP);
        if intI <> 0 then begin
            strTEMP := copy(strTEMP, 1, intI - 1);
        end;
        strDomainUserID := strTEMP;
    end;
    if (Pos(UpperCase(DomainPasswordSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        strTEMP := strPas(cmdline);
        intI    := Pos(DomainPasswordSwitch, UpperCase(strTEMP));
        strTEMP := copy(strTEMP, intI + Length(DomainPasswordSwitch), length(strTEMP) - intI - Length(DomainPasswordSwitch) + 1);
        intI    := Pos(' ', strTEMP);
        if intI <> 0 then begin
            strTEMP := copy(strTEMP, 1, intI - 1);
        end;
        strDomainPassword := strTEMP;
    end;
    if (Pos(UpperCase(ReadFromDataFileSwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        TaskReadFromDataFile := True;
        strTEMP := strPas(cmdline);
        intI    := Pos(ReadFromDataFileSwitch, UpperCase(strTEMP));
        strTEMP := copy(strTEMP, intI + Length(ReadFromDataFileSwitch), length(strTEMP) - intI - Length(ReadFromDataFileSwitch) + 1);
        if length(strTEMP) > 0 then begin    // Catch switch with no value
            if strTEMP[1] = '"' then begin   // Handle filenames with spaces in path
                strTEMP := Copy(strTEMP, 2, Length(strTEMP) - 1);
                intI    := Pos('"', strTEMP);     //Find position of closing quote
                if intI <> 0 then begin
                    strTEMP := copy(strTEMP, 1, intI - 1);
                end else begin
                    //Add error handling for no closing quote here
                end;
            end else begin                       // No quotes to worry about
                intI := Pos(' ', strTEMP);
                if intI <> 0 then begin
                    strTEMP := copy(strTEMP, 1, intI - 1);
                end;
            end;
            strDataFileName := strTEMP;
        end;
    end;
    if (Pos(UpperCase(DataFileKeySwitch), UpperCase(strPas(cmdline))) <> 0) then begin
        strTEMP := strPas(cmdline);
        intI    := Pos(DataFileKeySwitch, UpperCase(strTEMP));
        strTEMP := copy(strTEMP, intI + Length(DataFileKeySwitch), length(strTEMP) - intI - Length(DataFileKeySwitch) + 1);
        if length(strTEMP) > 0 then begin    // Catch switch with no value
            if strTEMP[1] = '"' then begin    // strings with spaces in path
                strTEMP := Copy(strTEMP, 2, Length(strTEMP) - 1);
                intI    := Pos('"', strTEMP);     // Find position of closing quote
                if intI <> 0 then begin
                    strTEMP := copy(strTEMP, 1, intI - 1);
                end else begin
                    //Add error handling for no closing quote here
                end;
            end else begin                       // No quotes to worry about
                intI := Pos(' ', strTEMP);
                if intI <> 0 then begin
                    strTEMP := copy(strTEMP, 1, intI - 1);
                end;
            end;
            strDataFileKey := strTEMP;
        end;
    end;
end;

function NumberofSubStringsInString(strTMP : string; strSUBTMP : char) : Integer;
var
    i, Count : Integer;
begin
    Count := 0;
    if length(strTMP) = 0 then begin
        Result := 0;
        exit;
    end;
    i := Pos(strSUBTMP, strTMP);
    while i <> 0 do begin
        Count := Count + 1;
        Delete(strTMP, 1, i);
        i := Pos(strSUBTMP, strTMP);
    end;
    Result := Count;
end;

function IsValidIPAddress(address : string) : boolean;
var
    IPOctet : array[1..4] of string;
    i, j :    Integer;
begin
    if NumberofSubStringsInString(address, '.') = 3 then begin
        i := pos('.', address);
        IPOctet[1] := copy(address, 1, i - 1);
        Delete(address, 1, i);
        i := pos('.', address);
        IPOctet[2] := copy(address, 1, i - 1);
        Delete(address, 1, i);
        i := pos('.', address);
        IPOctet[3] := copy(address, 1, i - 1);
        Delete(address, 1, i);
        IPOctet[4] := address;
        if (length(IPOctet[1]) = 0) or (length(IPOctet[2]) = 0) or (length(IPOctet[3]) = 0) or (length(IPOctet[4]) = 0) or
            (length(IPOctet[1]) > 3) or (length(IPOctet[2]) > 3) or (length(IPOctet[3]) > 3) or (length(IPOctet[4]) > 3) then
        begin
            Result := False;
            exit;
        end;
        for i := 1 to 4 do begin
            for j := 1 to length(IPOctet[i]) do begin
                if not (IPOctet[i, j] in ['0'..'9']) then begin
                    Result := False;
                    exit;
                end;
            end;
        end;
        for i := 1 to 4 do begin
            j := StrToInt(IPOctet[i]);
            if j > 254 then begin
                Result := False;
                exit;
            end;
        end;
        Result := True;
    end else begin
        Result := False;
    end;
    exit;
end;

function GetValueFromFile(strDataFileName : string; strKeyString : string) : string;
var
    tfDataFile : TextFile;
    strBuffer, strKey, strValue, strResult : string;
    intIndex :   Integer;
    blnExit :    boolean;

begin
    strValue  := '';
    strKey    := '';
    strBuffer := '';
    strResult := '';
    blnExit   := False;
    strDataFileName := Trim(strDataFileName);
    strKeyString := Trim(strKeyString);
    if not FileExists(strDataFileName) then begin
        Exit;
    end;
    try
        AssignFile(tfDataFile, strDataFileName);
        Reset(tfDataFile);
        while (not EOF(tfDataFile)) and (not blnExit) do begin
            ReadLn(tfDataFile, strBuffer);
            intIndex := Pos('=', strBuffer);
            if intIndex <> 0 then begin
                strKey   := Trim(Copy(strBuffer, 1, intIndex - 1));
                strValue := Trim(Copy(strBuffer, intIndex + 1, length(strBuffer) - intIndex + 1));
                if UpperCase(strKey) = UpperCase(strKeyString) then begin
                    strResult := strValue;
                    blnExit   := True;
                end;
            end;
        end;
    finally
        CloseFile(tfDataFile);
    end;
    GetValueFromFile := strResult;
end;


procedure ExitRoutine(exitcode : byte);
begin
    case exitcode of
        14 : begin
            Halt(exitcode);
        end;  // Search Key not found in Data File
        13 : begin
            Halt(exitcode);
        end;  // Filename specified in /RDF not found
        12 : begin
            Halt(exitcode);
        end;  // Search key for /RDF mode not passed
        11 : begin
            Halt(exitcode);
        end;  // RenameinDomain on unsupported OS
        10 : begin
            Halt(exitcode);
        end;  // Request to Reboot Failed
        9 : begin
            Halt(exitcode);
        end;  // No local Admin Rights
        8 : begin
            Halt(exitcode);
        end;  // New name validity check failed
        7 : begin
            Halt(exitcode);
        end;  // Computer is already named "newname"
        6 : begin
            Halt(exitcode);
        end;  // Rename failed - cause unknown
        5 : begin
            Halt(exitcode);
        end;  // Can't read MAC Address
        4 : begin
            Halt(exitcode);
        end;  // Could not determine local IP address
        3 : begin
            Halt(exitcode);
        end;  // Reverse Lookup Failed

        else begin
            Application.Terminate;
        end;
    end;

end;

procedure NameSync;
begin
    if UpperCase(HostName) <> UpperCase(ComputerName) then begin
        AppendToLogFile('Name Sync                 : Computer and Host Names Do Not Match - setting hostname to ' + ComputerName);
        SetHostName(ComputerName);
        if blnNetWareClientInstalled then begin
            SetNVHostName(ComputerName);
        end;
        if TaskReboot then begin
            if not WinExit(EWX_REBOOT or EWX_FORCE) then begin
                AppendToLogFile('ERROR - Reboot request failed, WSName terminating');
                ExitRoutine(10);
            end;
        end;
    end else begin
        AppendToLogFile('Name Sync                 : Computer and Host Names Match - no action required');
    end;
end;

function PostGhostNameMatch : boolean;
    // Returns TRUE if names match
var
    tmpstr : string;
    i :      Integer;
begin
    AppendToLogFile('Operation                 : Post Ghost Mode');
    Result := False;
    tmpstr := UpperCase(strPas(cmdline));
    i      := Pos('/PG:', tmpstr);
    tmpstr := copy(tmpstr, i + 4, length(tmpstr) - i - 3);
    i      := Pos(' ', tmpstr);
    if i <> 0 then begin
        tmpstr := copy(tmpstr, 1, i - 1);
    end;
    if UpperCase(ComputerName) = tmpstr then begin
        AppendToLogFile('Post Ghost                : Names Match - I''ve got work to do!');
        Result := True;
    end else begin
        AppendToLogFile('Post Ghost                : No Name Match - no action required');
    end;
end;

procedure ExtractRes(ResType, ResName, ResNewName : string);
var
    Res : TResourceStream;
begin
    Res := TResourceStream.Create(hInstance, ResName, PChar(ResType));
    Res.SaveToFile(ResNewName);
    Res.Free;
end;

function CheckValidityofCompterName(ComputerNametoCheck : string) : boolean;
const
    validchars = ['a'..'z', 'A'..'Z', '0'..'9', '!', '@', '#', '$', '%', '^', '&', '(', ')', '-', '_', '''', '{', '}', '~']; //removed '.'
var
    i : Integer;
    blnAllNumeric : boolean;

begin
    AppendToLogFile('Name Validity Check       : Proposed name is "' + ComputerNametoCheck + '"');
    Result := True;
    if (GetOSVersion(False) = OS_WINNT) and (GetOSVersion(True) <> OS_WINNT) then begin
        // Only want to check for numeric names on Windows 2000 or above
        blnAllNumeric := True;
        for i := 1 to length(ComputerNametoCheck) do begin
            if not (ComputerNametoCheck[i] in ['0'..'9']) then begin
                blnAllNumeric := False;
                Break;
            end;
        end;
        if blnAllNumeric then begin
            AppendToLogFile('Name Validity Check       : FAILED - All numeric name not permitted under ' + GetOSVersion(True));
            Result := False;
            Exit;
        end;
    end;
    if length(ComputerNametoCheck) > MAX_LENGTH_COMPUTER_NAME then begin
        AppendToLogFile('Name Validity Check       : FAILED - Name too long');
        Result := False;
        Exit;
    end;
    if ComputerNametoCheck[1] = '-' then begin
        AppendToLogFile('Name Validity Check       : FAILED - Name starts with "-"');
        Result := False;
        Exit;
    end;
    for i := 1 to length(ComputerNametoCheck) do begin
        if not (ComputerNametoCheck[i] in ValidChars) then begin
            AppendToLogFile('Name Validity Check       : FAILED - Contains one of more invalid characters (' +
                ComputerNametoCheck[i] + ')');
            Result := False;
            Break;
        end;
    end;
end;

function CheckInTrim(targetstring : string; maxsize : Integer) : string;
    // Trims strings to a maximum length, over size strings are cut down to
    // "maxsize" - 3 and have '...' appended to them
begin
    trim(targetstring);
    if length(targetstring) > maxsize then begin
        targetstring := copy(targetstring, 1, maxsize - 3) + '...';
    end;
    Result := targetstring;
end;

function IncludeTrailingBackslash(S : string) : string;
begin
    if not (s[length(s)] = '\') then begin
        Result := S + '\';
    end else begin
        Result := S;
    end;
end;

function SetDiskLabel(targetdrive, newname : string) : boolean;
begin
    if not TaskTestOnly then begin
        Result := SetVolumeLabel(PChar(IncludeTrailingBackslash(targetdrive)), PChar(newname));
    end else begin
        Result := True;
    end;
end;

function RenameComputer(newname : string; UnRegisterFromNDS, RebootOnCompletion : boolean) : boolean;
var
    tmpstr, OSVer : string;
    res : boolean;

begin
    OSVer := GetOSVersion(True);
    AppendToLogFile('Operation                 : Rename Computer to ' + newname);
    if not (CheckValidityofCompterName(newname)) then begin
        AppendToLogFile('New name validity check   : Failed - Rename request aborted!');
        ExitRoutine(8);
    end else begin
        AppendToLogFile('New name validity check   : Passed');
    end;
    if (UpperCase(ComputerName) = UpperCase(newname)) then begin
        if not TaskAlwaysDoRename then begin
            AppendToLogFile('Computer is already named ' + newname + '. - Rename request aborted!');
            ExitRoutine(7);
        end else begin
            AppendToLogFile('Computer is already named ' + newname + ' but processing continuing due to /ACN switch');
        end;
    end;

    if not TaskChangeHostNameOnly then begin
        if ((OSVer = OS_WIN2K) or (OSVer = OS_WINXP)) and (TaskRenameComputerInDomain = False) then begin
            AppendToLogFile('Rename Method             : SetComputerNameEx');
            Result := fSetComputerNameEx(newname);     //SetComputerNameEx - W2K and XP only
        end else
        if ((OSVer = OS_WIN2K) or (OSVer = OS_WINXP)) and (TaskRenameComputerInDomain = True) then begin
            AppendToLogFile('Rename Method             : NetRenameMachineInDomain');
            AppendToLogFile('User ID                   : ' + strDomainUserID);
            Result := RenameComputerInDomain('', newname, strDomainUserID, strDomainPassword);
            //NetRenameMachineInDomain - W2K and XP only
        end else begin
            AppendToLogFile('Rename Method             : SetComputerName');
            Result := fSetComputerName(newname);       //Standard old rename for Win9x and WinNT4
        end;
    end else begin
        Result := True;
        AppendToLogFile('Change HostName Only option selected (/CHO) NetBIOS name not changed ');
    end;

    if Result then begin
        if not TaskChangeHostNameOnly then begin
            AppendToLogFile('Rename Successful - reboot required to take effect');
        end;
        //Set Host name happens here - only required for Win9x and NT 4
        if (OSVer <> 'WIN2K') and (OSVer <> 'WINXP') then begin
            SetHostName(newname);
        end;
        // Added in ver 2.66e - Set NV hostname
        if blnNetWareClientInstalled then begin
            SetNVHostName(newname);
        end;
        if TaskSetDiskLabel then begin
            tmpstr := newname;
            if length(tmpstr) > 11 then begin
                tmpstr := copy(newname, 1, 11);
            end;
            res := SetDiskLabel('c:\', tmpstr);
            if res then begin
                AppendToLogFile('C: Drive Name set to      : ' + tmpstr);
            end else begin
                AppendToLogFile('Failed to set Drv Name to : ' + tmpstr);
            end;
        end;

        if TaskSetMyComputerDescription then begin
            if sComputerDescription = '' then begin
                SetMyComputerDescription(AsEnteredComputerName);
            end else begin
                SetMyComputerDescription(sComputerDescription);
            end;
        end;

        if TaskSetMyComputerName then begin
            SetMyComputerName(AsEnteredComputerName);
        end;

        if TaskLogOnTo then begin
            SetLogOnTo(newname);
        end;

        if UnRegisterFromNDS then begin
            if UnRegProgramName <> '' then begin
                AppendToLogFile('called ' + UnRegProgramName);
                if not TaskTestOnly then begin
                    RunProcess(UnRegProgramName, '', SW_SHOWNORMAL, True);
                end;
            end else begin
                AppendToLogFile('The request to UnRegister was made could not be actioned as WSName could not find ' +
                    UnRegProgramName + ' in the path');
            end;
        end;
        if RebootOnCompletion then begin
            AppendToLogFile('Rebooting');
            if not WinExit(EWX_REBOOT or EWX_FORCE) then begin
                AppendToLogFile('ERROR - Reboot request failed, WSName terminating');
                ExitRoutine(10);
            end;
        end;
    end else begin
        AppendToLogFile('Rename Failed');
        ExitRoutine(6);
    end;
end;

function PosX(Substr : string; S : string) : Integer;
    //Case Insensitive Pos
begin
    Result := Pos(UpperCase(Substr), UpperCase(S));
end;

procedure SilentMode;
var
    tmpstr, strIPAddress, strDNSServer, sStr : string;
    i, iI, iJ, iP : Integer;
    blnBreak :      boolean;
begin
    AppendToLogFile('Silent Mode               : Starting (' + NEW_COMPUTERNAME_SWITCH + '<name>)');
    AsEnteredComputerName := strPas(cmdline);
    tmpstr := AsEnteredComputerName;
    i      := PosX(NEW_COMPUTERNAME_SWITCH, tmpstr);
    tmpstr := copy(tmpstr, i + Length(NEW_COMPUTERNAME_SWITCH), length(tmpstr) - i - 2);
    AsEnteredComputerName := copy(AsEnteredComputerName, i + 3, length(AsEnteredComputerName) - i - 2);
    i      := PosX(' ', tmpstr);
    if i <> 0 then begin
        tmpstr := copy(tmpstr, 1, i - 1);
        AsEnteredComputerName := copy(AsEnteredComputerName, 1, i - 1);
    end;

    // ------------ Start Complex Parameter Support - Added 11 June 2003

    if PosX(SILENT_IP_ADDRESS, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_IP_ADDRESS);
        sStr := GetIPAddress(0);
        if sStr = '' then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end;
        sStr := PadIPAddress(sStr);
        AppendToLogFile('Silent Mode               : IP Address  : "' + sStr + '"');
        sStr := StringReplace(sStr, '.', '-', [rfReplaceAll, rfIgnoreCase]);
        AppendToLogFile('Silent Mode               : Fix for DNS : "' + sStr + '"');
        tmpstr := MagicChango(tmpstr, SILENT_IP_ADDRESS, sStr, TRIM_RIGHT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_MAC_ADDRESS_II, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_MAC_ADDRESS_II);
        UseAlternateMACAddressRoutine := True;
        sStr := GetMACAddress(0);
        if UpperCase(sStr) = UpperCase('ERROR') then begin
            AppendToLogFile('Can''t read MAC Address - Rename request aborted!');
            ExitRoutine(5);
        end;
        AppendToLogFile('Silent Mode               : MAC Address  : "' + sStr + '"');
        tmpstr := MagicChango(tmpstr, SILENT_MAC_ADDRESS_II, sStr, TRIM_RIGHT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_MAC_ADDRESS, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_MAC_ADDRESS);
        sStr := GetMACAddress(0);
        if UpperCase(sStr) = UpperCase('ERROR') then begin
            AppendToLogFile('Can''t read MAC Address - Rename request aborted!');
            ExitRoutine(5);
        end;
        AppendToLogFile('Silent Mode               : MAC Address  : "' + sStr + '"');
        tmpstr := MagicChango(tmpstr, SILENT_MAC_ADDRESS, sStr, TRIM_RIGHT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_USER_NAME, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_USER_NAME);
        AppendToLogFile('Silent Mode               : Username is "' + UserName + '"');
        tmpstr := MagicChango(tmpstr, SILENT_USER_NAME, UserName, TRIM_LEFT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_RANDOM_NAME, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_RANDOM_NAME);
        sStr := GenerateRandomName(15);
        AppendToLogFile('Silent Mode               : Gernerated Name is "' + sStr + '"');
        tmpstr := MagicChango(tmpstr, SILENT_RANDOM_NAME, sStr, TRIM_LEFT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_OS_TYPE, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_OS_TYPE);
        sStr := OSVersionToTLA;
        AppendToLogFile('Silent Mode               : OS Shortname is "' + sStr + '"');
        tmpstr := MagicChango(tmpstr, SILENT_OS_TYPE, sStr, TRIM_LEFT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;
    if PosX(SILENT_REVERSE_DNS, tmpstr) <> 0 then begin
        AppendToLogFile('Silent Mode               : Evaluating ' + SILENT_REVERSE_DNS);
        if Copy(tmpstr, PosX(SILENT_REVERSE_DNS, tmpstr) + length(SILENT_REVERSE_DNS), 1) = ':' then begin
            AppendToLogFile('Silent Mode               : Extracting DNS Server Address');
            iI := Pos('%DNS', tmpstr) + length('%DNS') + 1;
            iJ := iI;
            iP := iI;
            blnBreak := False;
            repeat
                if tmpstr[iJ] = '.' then begin
                    iP := iJ;
                end;
                if (iJ > iP + 3) or (not (tmpstr[iJ] in ['0'..'9', '.'])) then begin
                    blnBreak := True;
                end;
                iJ := iJ + 1;
            until (iJ > (iI + 15)) or (iJ > Length(tmpstr)) or blnBreak;
            strDNSServer := Copy(tmpstr, iI, iJ - iI);
            AppendToLogFile('Silent Mode               : Extracted DNS Server address is ' + strDNSServer);
            Delete(tmpstr, iI - 1, iJ - iI + 1);
            AppendToLogFile('Silent Mode               : Updated input parameter is ' + tmpstr);
        end else begin
            strDNSServer := GetDNSServer;
        end;
        if not IsValidIPAddress(strDNSServer) then begin
            AppendToLogFile('Invalid Address for DNS Server (' + strDNSServer + ') - Rename request aborted!');
            ExitRoutine(3);
        end;
        if LocalIPList.Count < 1 then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end;
        strIPaddress := LocalIPList.Strings[0];
        if strIPaddress = '127.0.0.1' then  // Avoid returning localhost
        begin
            strIPaddress := '';
        end;
        if strIPaddress = '' then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end;
        AppendToLogFile('IP Address                : ' + strIPaddress);
        AppendToLogFile('DNS Server IP Address     : ' + strDNSServer);
        if ReverseDNSLookup(strIPAddress, strDNSServer, DNS_TIMEOUT_INTERVAL, sStr) then begin
            AppendToLogFile('Reverse Lookup Returned   : ' + sStr);
            i := PosX('.', sStr);
            if i <> 0 then begin
                sStr := Trim(Copy(sStr, 1, i - 1));
            end;
            AppendToLogFile('Reverse Lookup Shortname  : ' + sStr);
        end else begin
            AppendToLogFile(sStr + ' - Script Terminating');
            ExitRoutine(3);
        end;
        tmpstr := MagicChango(tmpstr, SILENT_REVERSE_DNS, sStr, TRIM_LEFT);
        AppendToLogFile('Silent Mode               : Updated input parameter is ' + NEW_COMPUTERNAME_SWITCH + tmpstr);
    end;

    AsEnteredComputerName := tmpstr;
    // ------------ End Complex Parameter Support - Added 11 June 2003


    //Temp Compatibility Hack
    if TaskResolvebyReverseDNS then begin
        tmpstr := UpperCase(strPas(cmdline));
        i      := PosX('/DNS:', tmpstr);
        tmpstr := copy(tmpstr, i + 5, length(tmpstr) - i - 4);
        i      := PosX(' ', tmpstr);
        if i <> 0 then begin
            tmpstr := copy(tmpstr, 1, i - 1);
        end;
        tmpstr := SILENT_REVERSE_DNS + ':' + tmpstr;
    end;
    // End Temp Compatibility Hack


    if tmpstr = SILENT_IP_ADDRESS then begin
        AppendToLogFile('Silent Mode               : Using IP address for name ' + NEW_COMPUTERNAME_SWITCH + SILENT_IP_ADDRESS);
        tmpstr := GetIPAddress(0);
        if tmpstr = '' then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end else begin
            AppendToLogFile('Silent Mode               : IP Address  : "' + tmpstr + '"');
            tmpstr := StringReplace(tmpstr, '.', '-', [rfReplaceAll, rfIgnoreCase]);
            AppendToLogFile('Silent Mode               : Fix for DNS : "' + tmpstr + '"');
            AsEnteredComputerName := tmpstr;
        end;
    end else
    if tmpstr = SILENT_USER_NAME then begin
        AppendToLogFile('Silent Mode               : Using User ID for Name  /N:' + SILENT_USER_NAME);
        tmpstr := UserName;
        AsEnteredComputerName := tmpstr;
        AppendToLogFile('Silent Mode               : User Name is "' + tmpstr + '"');
    end else
    if (tmpstr = SILENT_MAC_ADDRESS) or (tmpstr = SILENT_MAC_ADDRESS_II) then begin
        if tmpstr = SILENT_MAC_ADDRESS_II then begin
            UseAlternateMACAddressRoutine := True;
            AppendToLogFile('Silent Mode               : Using MAC address for name /N:' + SILENT_MAC_ADDRESS_II);
        end else begin
            AppendToLogFile('Silent Mode               : Using MAC address for name /N:' + SILENT_MAC_ADDRESS);
        end;
        tmpstr := GetMACAddress(0);
        if UpperCase(tmpstr) = UpperCase('ERROR') then begin
            AppendToLogFile('Can''t read MAC Address - Rename request aborted!');
            ExitRoutine(5);
        end;
        if GetMACAddressPrefix <> '' then begin
            AppendToLogFile('Silent Mode               : Prefix = ' + GetMACAddressPrefix);
            tmpstr := GetMACAddressPrefix + tmpstr;
        end;
        AsEnteredComputerName := tmpstr;
    end else
    if Copy(tmpstr, 1, length(SILENT_REVERSE_DNS)) = SILENT_REVERSE_DNS then begin
        AppendToLogFile('Silent Mode               : Resolve by Reverse DNS Look Up');
        i      := PosX(SILENT_REVERSE_DNS, tmpstr);
        tmpstr := copy(tmpstr, i + length(SILENT_REVERSE_DNS), length(tmpstr) - i - length(SILENT_REVERSE_DNS) + 1);
        i      := PosX(' ', tmpstr);
        if i <> 0 then begin
            tmpstr := copy(tmpstr, 1, i - 1);
        end;
        if length(tmpstr) = 0 then begin
            strDNSServer := GetDNSServer;
        end else
        if tmpstr[1] = ':' then begin
            strDNSServer := copy(tmpstr, 2, length(tmpstr) - 1);
        end;
        if not IsValidIPAddress(strDNSServer) then begin
            AppendToLogFile('Invalid Address for DNS Server (' + strDNSServer + ') - Rename request aborted!');
            ExitRoutine(3);
        end;
        if LocalIPList.Count < 1 then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end;
        strIPaddress := LocalIPList.Strings[0];
        if strIPaddress = '127.0.0.1' then  // Avoid returning localhost
        begin
            strIPaddress := '';
        end;
        if strIPaddress = '' then begin
            AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
            ExitRoutine(4);
        end else begin
            AppendToLogFile('IP Address                : ' + strIPaddress);
            AppendToLogFile('DNS Server IP Address     : ' + strDNSServer);
        end;
        if ReverseDNSLookup(strIPAddress, strDNSServer, DNS_TIMEOUT_INTERVAL, tmpstr) then begin
            AppendToLogFile('Reverse Lookup Returned   : ' + tmpstr);
            i := PosX('.', tmpstr);
            if i <> 0 then begin
                tmpstr := Trim(Copy(tmpstr, 1, i - 1));
            end;
            AppendToLogFile('Reverse Lookup Shortname  : ' + tmpstr);
        end else begin
            AppendToLogFile(tmpstr + ' - Script Terminating');
            ExitRoutine(3);
        end;
        AsEnteredComputerName := tmpstr;
    end;
    if not TaskTestOnly then begin
        RenameComputer(tmpstr, TaskUnReg, TaskReboot);
    end;
end;

function GetMACAddressPrefix : string;
var
    intI : Integer;
    strCommandLine, strPrefix : string;

begin
    strCommandLine := strPas(cmdline);
    intI := Pos(UpperCase(MACPrefixSwitch), UpperCase(strCommandLine));
    if intI <> 0 then begin
        strPrefix := copy(strCommandLine, intI + length(MACPrefixSwitch), length(strCommandLine) - length(MACPrefixSwitch));
        intI      := Pos(' ', strPrefix);
        if intI <> 0 then begin
            strPrefix := copy(strPrefix, 1, intI - 1);
        end;
        if (length(strPrefix) > MaxPrefixLength) then begin
            strPrefix := copy(strPrefix, 1, MaxPrefixLength);
        end;
    end;
    Result := strPrefix;
end;

procedure UseMACAddressforName;
var
    MACAddress, tmpstr : string;
    I : Integer;
begin
    AppendToLogFile('GETMACAddress             : MAC Naming Mode Processing (/MAC)');

    if TaskPrefixMACAddress then begin
        tmpstr := UpperCase(strPas(cmdline));
        I      := Pos(MACPrefixSwitch, tmpstr);
        tmpstr := copy(tmpstr, i + length(MACPrefixSwitch), length(tmpstr) - length(MACPrefixSwitch));
        i      := Pos(' ', tmpstr);
        if i <> 0 then begin
            tmpstr := copy(tmpstr, 1, i - 1);
        end;
        if (length(tmpstr) > MaxPrefixLength) then begin
            tmpstr := copy(tmpstr, 1, MaxPrefixLength);
        end;
        AppendToLogFile('MAC Address Prefix        : ' + tmpstr);
    end;

    MACAddress := GetMACAddress(0);
    if UpperCase(MACAddress) = UpperCase('ERROR') then begin
        AppendToLogFile('Can''t read MAC Address - Rename request aborted!');
        ExitRoutine(5);
    end;

    if TaskPrefixMACAddress then begin
        MACAddress := tmpstr + MACAddress;
        AppendToLogFile('MAC Address               : ' + MACAddress);
    end;

    if not TaskTestOnly then begin
        RenameComputer(MACAddress, TaskUnReg, TaskReboot);
    end;
end;

procedure ReadNameFromDataFile;
var
    strNameFromFile : string;
begin
    strNameFromFile := '';
    AppendToLogFile('Starting Data File Mode Processing (/RDF)');
    AppendToLogFile('Data File Name            : ' + strDataFileName);
    AppendToLogFile('Search Key                : ' + strDataFileKey);
    if strDataFileKey = '' then begin
        AppendToLogFile('No search key passed (/DFK) - Rename request aborted!');
        ExitRoutine(12);
    end;
    if not FileExists(strDataFileName) then begin
        AppendToLogFile('Can''t find data file "' + strDataFileName + '" - Rename request aborted!');
        ExitRoutine(13);
    end;
    if (UpperCase(strDataFileKey) = '!MAC') or (UpperCase(strDataFileKey) = SILENT_MAC_ADDRESS) then begin
        AppendToLogFile('Data File Mode            : Evaluating ' + SILENT_MAC_ADDRESS);
        strDataFileKey := GetMACAddress(0);
        AppendToLogFile('GetMACAddress Returned    : ' + strDataFileKey);
    end;
    AppendToLogFile('Data File Mode            : Reading Data File');
    strNameFromFile := GetValueFromFile(strDataFileName, strDataFileKey);
    if strNameFromFile = '' then begin
        AppendToLogFile('Search Key not found in Data File - Rename request aborted!');
        ExitRoutine(14);
    end else begin
        AppendToLogFile('New Name From Data File   : ' + strNameFromFile);
    end;
    RenameComputer(strNameFromFile, TaskUnReg, TaskReboot);
end;

function ReadNovellClientDetails : string;
const
    NTBaseKey: string = '\SOFTWARE\Novell\NetWareWorkstation\CurrentVersion';
    W9BaseKey: string = '\Network\Novell\System Config\Install\Client Version';

var
    NetWareClientVersion, Basekey, gsClientTitle, gsClientBuild, gsClientMajorVersion, gsClientMinorVersion,
    gsClientACUVersionMajor, gsClientACUVersionMinor, gsClientServicePack : string;

begin
    Result := '';
    NetWareClientVersion := '';

    if OSVer = 'WIN9X' then begin
        Basekey := W9BaseKey;
    end else begin
        Basekey := NTBaseKey;
    end;

    gsClientTitle := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, Basekey, 'Title');
    gsClientBuild := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'BuildNumber');

    if OSVer = 'WIN9X' then begin
        gsClientMajorVersion := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'Major Version');
        gsClientMinorVersion := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'Minor Version');
    end else begin
        gsClientMajorVersion := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'MajorVersion');
        gsClientMinorVersion := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'MinorVersion');
    end;

    gsClientACUVersionMajor := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'Revision');
    gsClientACUVersionMinor := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'Level');
    gsClientServicePack     := ReadAsStringFromRegistry(HKEY_LOCAL_MACHINE, BaseKey, 'Service Pack');

    if gsClientACUVersionMajor = '' then begin
        gsClientACUVersionMajor := '0';
    end;

    if gsClientACUVersionMinor = '' then begin
        gsClientACUVersionMinor := '0';
    end;

    NetWareClientVersion := gsClientMajorVersion + '.' + gsClientMinorVersion + '.' + gsClientACUVersionMajor +
        '.' + gsClientACUVersionMinor;

    if gsClientBuild <> '' then begin
        NetWareClientVersion := NetWareClientVersion + '.' + gsClientBuild;
    end;

    Result := NetWareClientVersion + ' ' + gsClientServicePack;
end;


procedure ShowHelpFile;
var
    HelpFilePathandName : string;
begin
    HelpFilePathandName := TempDirectory + HelpFileName;
    ExtractRes('HTM', 'HelpFile', HelpFilePathandName);
    ShellExecute(Application.handle, PChar('Open'), PChar(ExtractFileName(HelpFilePathandName)), nil,
        PChar(ExtractFileDir(HelpFilePathandName)), SW_SHOWNORMAL);
end;


function GetMACAddress(AdapterNumber : Integer) : string;
var
    slAdapter : TStringList;
    strMACAddress, strAdapterDescription : string;
    intAdaptertoReadFrom : Integer;
    bFoundOne : boolean;

begin
    AppendToLogFile('GETMACAddress             : Checking OS support');
    strMACAddress := '';
    intAdaptertoReadFrom := 0;
    if UseAlternateMACAddressRoutine then begin
        AppendToLogFile('GETMACAddress             : Using alternative MAC Address routine');
        slAdapter := GetAdapterInformationII;
        repeat
            strAdapterDescription := Trim(ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom, ADAP_DESCRIPTION));
            if (Pos('Wireless', strAdapterDescription) <> 0) then begin
                AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                    ' appears to be a Wireless, I''ll try the next one (this one is "' + strAdapterDescription + '")');
            end;
            if (Pos('PPP', strAdapterDescription) <> 0) then begin
                AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                    ' appears to be the dial up adapter, I''ll try the next one (this one is "' + strAdapterDescription + '")');
            end;
            intAdaptertoReadFrom := intAdaptertoReadFrom + 1;
        until ((Pos('Wireless', strAdapterDescription) = 0) and (Pos('Wireless', strAdapterDescription) = 0)) or
            (intAdaptertoReadFrom > slAdapter.Count);
        if intAdaptertoReadFrom > slAdapter.Count then begin
            AppendToLogFile('ERROR                     : Could not determine correct network adapter');
            ExitRoutine(5);
        end;
        AppendToLogFile('GETMACAddress             : Reading MAC Address from "' + strAdapterDescription +
            '"  (Adapter ' + IntToStr(intAdaptertoReadFrom - 1) + ')');
        strMACAddress := ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom - 1, ADAP_ADAPTER_ADDRESS);
        slAdapter.Free;
    end else
    if (IsDLLOnSystem('iphlpapi.dll')) and (GetOSVersion(True) <> OS_WIN95) and (GetOSVersion(True) <> OS_WINNT) then begin
        AppendToLogFile('GETMACAddress             : IPHLPAPI.DLL found using GetAdaptersInfo API');
        slAdapter := GetAdapterInformation;
        bFoundOne := False;
        repeat
            strAdapterDescription := Trim(ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom, ADAP_DESCRIPTION));
            if (Pos('Wireless', strAdapterDescription) <> 0) then begin
                if (intAdaptertoReadFrom + 1) <> slAdapter.Count then begin
                    AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                        ' appears to be a Wireless, I''ll try the next one (this one is "' + strAdapterDescription + '")');
                end else begin
                    AppendToLogFile('GETMACAddress             : Using Wireless adapter (no more adapters found)');
                    bFoundOne := True;
                end;
            end;
            if (Pos('PPP', strAdapterDescription) <> 0) then begin
                AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                    ' appears to be the dial up adapter, I''ll try the next one (this one is "' + strAdapterDescription + '")');
            end;
            intAdaptertoReadFrom := intAdaptertoReadFrom + 1;
        until ((Pos('Wireless', strAdapterDescription) = 0) and (Pos('Wireless', strAdapterDescription) = 0)) or
            (intAdaptertoReadFrom > slAdapter.Count) or bFoundOne;
        if intAdaptertoReadFrom > slAdapter.Count then begin
            AppendToLogFile('ERROR                     : Could not determine correct network adapter');
            ExitRoutine(5);
        end;
        AppendToLogFile('GETMACAddress             : Reading MAC Address from "' + strAdapterDescription +
            '"  (Adapter ' + IntToStr(intAdaptertoReadFrom - 1) + ')');
        strMACAddress := ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom - 1, ADAP_ADAPTER_ADDRESS);
        slAdapter.Free;
    end else begin
        AppendToLogFile('GETMACAddress             : IPHLPAPI.DLL NOT found (Win95/NT4), using old NetBIOS method');
        strMACAddress := GetMACAddressLegacy(AdapterNumber);
        if UpperCase(strMACAddress) = UpperCase('Error') then begin
            AppendToLogFile('GETMACAddress             : NetBIOS method returned Error');
            AppendToLogFile('GETMACAddress             : Using alternative MAC Address routine');
            slAdapter := GetAdapterInformationII;
            repeat
                strAdapterDescription := Trim(ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom, ADAP_DESCRIPTION));
                if (Pos('Wireless', strAdapterDescription) <> 0) then begin
                    AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                        ' appears to be a Wireless, I''ll try the next one (this one is "' + strAdapterDescription + '")');
                end;
                if (Pos('PPP', strAdapterDescription) <> 0) then begin
                    AppendToLogFile('GETMACAddress             : Adapter ' + IntToStr(intAdaptertoReadFrom) +
                        ' appears to be the dial up adapter, I''ll try the next one (this one is "' + strAdapterDescription + '")');
                end;
                intAdaptertoReadFrom := intAdaptertoReadFrom + 1;
            until ((Pos('Wireless', strAdapterDescription) = 0) and (Pos('Wireless', strAdapterDescription) = 0)) or
                (intAdaptertoReadFrom > slAdapter.Count);
            if intAdaptertoReadFrom > slAdapter.Count then begin
                AppendToLogFile('ERROR                     : Could not determine correct network adapter');
                ExitRoutine(5);
            end;
            AppendToLogFile('GETMACAddress             : Reading MAC Address from "' +
                strAdapterDescription + '"  (Adapter ' + IntToStr(intAdaptertoReadFrom - 1) + ')');
            strMACAddress := ExtractFromGetAdapterInformation(slAdapter, intAdaptertoReadFrom - 1, ADAP_ADAPTER_ADDRESS);
            slAdapter.Free;
        end;
    end;
    AppendToLogFile('GETMACAddress             : Returned ' + strMACAddress);
    Result := strMACAddress;
end;

procedure UseMyNameforComputerName;
begin
    if not TaskTestOnly then begin
        AsEnteredComputerName := UserName;
        RenameComputer(UserName, TaskUnReg, TaskReboot);
    end;
end;

procedure UseIPAddressforName;
var
    tmpstr : string;

begin
    tmpstr := LocalIPList.Strings[0];

    if tmpstr = '127.0.0.1' then  // Avoid returning localhost
    begin
        tmpstr := '';
    end;

    if tmpstr = '' then begin
        AppendToLogFile('Could not determine local IP address. - Rename request aborted!');
        ExitRoutine(4);
    end else begin
        AppendToLogFile('IP Address                : ' + tmpstr);
    end;
    tmpstr := StringReplace(tmpstr, '.', '-', [rfReplaceAll, rfIgnoreCase]);

    //function StringReplace(const S, OldStr, NewStr: string; Flags: TReplaceFlags): string;

    AppendToLogFile('Sanitised IP Address      : ' + tmpstr);

    if not TaskTestOnly then begin
        RenameComputer(tmpstr, TaskUnReg, TaskReboot);
    end;

end;

function GetIPAddress(intIPAddressIndex : Integer) : string;
var
    strTEMP : string;
begin
    strTEMP := LocalIPList.Strings[intIPAddressIndex];
    if strTEMP = '127.0.0.1' then  // Avoid returning localhost
    begin
        strTEMP := '';
    end;
    Result := strTEMP;
end;

procedure WritetoLogFile;
var
    f :    textfile;
    intI : Integer;
    bLogRolled : boolean;
    strTEMP, strLeft, strPassWd : string;
begin
    bLogRolled := False;
    if fileexists(LogFilePathandName) then begin    // Start check on log file to ensure it doesn't get too big
        if GetFilesizeEx(LogFilePathandName) > (MAX_LOG_FILE_SIZE * 1024) then begin  //Convert Meg to Bytes
            DeleteFile(LogFilePathandName);
            bLogRolled := True;
        end;
    end;
    assignfile(f, LogFilePathandName);
    if fileexists(LogFilePathandName) then begin
        append(f);
    end else begin
        rewrite(f);
    end;
    writeln(f, '');
    writeln(f, '');
    writeln(f, DateTimetoStr(Now) + ' : Version                   : ' + MyVersionNumber);
    writeln(f, DateTimetoStr(Now) + ' : Release Date              : ' + MyVersionDate);
    strTEMP := OSVer_To_Friendly_Name(GetOSVersion(True));
    if GetOSVersion(False) = OS_WINNT then begin
        if GetServicePackVersion <> '' then begin
            strTEMP := strTEMP + ' (' + GetServicePackVersion + ')';
        end;
    end;
    writeln(f, DateTimetoStr(Now) + ' : Operating System          : ' + strTEMP);
    writeln(f, DateTimetoStr(Now) + ' : Temporary Directory       : ' + TempDirectory);
    if not Directoryexists(TempDirectory) then begin
        writeln(f, DateTimetoStr(Now) + ' :                           : NOTE: This directory does not exist Log File set to C:\');
    end;
    writeln(f, DateTimetoStr(Now) + ' : Log File                  : ' + LogFilePathandName);
    if bLogRolled then begin
        writeln(f, DateTimetoStr(Now) + '                               Logfile has been rolled as it exceeded ' +
            IntToStr(MAX_LOG_FILE_SIZE) + ' KByte(s)');
    end;
    writeln(f, DateTimetoStr(Now) + ' : User Name                 : ' + UserName);
    writeln(f, DateTimetoStr(Now) + ' : Computer Name (NetBIOS)   : ' + ComputerName);
    writeln(f, DateTimetoStr(Now) + ' : Host Name (IP)            : ' + HostName);

    if LocalAdminRights then begin
        writeln(f, DateTimetoStr(Now) + ' : Operator Rights           : Administrator');
    end else begin
        writeln(f, DateTimetoStr(Now) + ' : Operator Rights           : User');
    end;

    if NovellClientVersion[1] <> '.' then begin
        writeln(f, DateTimetoStr(Now) + ' : Novell Client Version     : ', NovellClientVersion);
        if UnRegProgramName <> '' then begin
            writeln(f, DateTimetoStr(Now) + ' : Path to ZENworks UnReg    : ', UnRegProgramName);
        end else begin
            writeln(f, DateTimetoStr(Now) + ' : Path to ZENworks UnReg    : Not Found');
        end;
    end;

    //  Added logic to avoid domain password appearing in the log file
    strTEMP := strPas(cmdline);
    intI    := Pos(UpperCase(DomainPasswordSwitch), UpperCase(strPas(cmdline)));
    if intI = 0 then begin
        writeln(f, DateTimetoStr(Now) + ' : Command Line              : ', strTEMP);
    end else begin
        strLeft   := Copy(strTEMP, 1, intI + Length(DomainPasswordSwitch) - 1);
        strTemp   := Copy(strTEMP, intI + Length(DomainPasswordSwitch), length(strTEMP) - intI - Length(DomainPasswordSwitch) + 1);
        strPassWd := strTEMP;
        intI      := Pos(' ', strTemp);
        if intI <> 0 then begin
            strPassWd := copy(strTemp, 1, intI - 1);
            strTEMP   := copy(strTEMP, intI, length(strTEMP) - intI + 1);
        end else begin
            strTEMP := '';
        end;
        strTEMP := strLeft + '##########' + strTEMP;
        writeln(f, DateTimetoStr(Now) + ' : Command Line              : ', strTemp);
    end;
    flush(f);
    closefile(f);
end;



procedure MainCodeBlock;
begin
    ShowGUI := True;
    LocalAdminRights := False;
    OSVer   := GetOSVersion(False);
    OSVerDetailed := GetOSVersion(True);
    TempDirectory := GetTempDirectory;
    strDomainUserID := '';
    strDomainPassword := '';
    AsEnteredComputerName := '';
    blnNetWareClientInstalled := False;
    if DirectoryExists(TempDirectory) then begin
        LogFilePathandName := TempDirectory + LogFileName;
    end else begin
        LogFilePathandName := 'C:\' + LogFileName;
    end;

    if (IsAdmin) or (OSVer = 'WIN9X') then begin
        LocalAdminRights := True;
    end;

    UserName     := GetCurrentUserName;
    ComputerName := UpperCase(GetWorkstationName);
    HostName     := GetHostName;

    NovellClientVersion := ReadNovellClientDetails;
    if NovellClientVersion[1] <> '.' then begin
        blnNetWareClientInstalled := True;
    end;
    UnRegProgramName := FindPathtoFile(UnRegProgramName);

    WritetoLogFile;

    CheckCommandLine;          //  Any thing special to do?

    if TaskHelpStuff then begin
        AppendToLogFile('Operation               : Show Help File');
        ShowGUI := False;
        ShowHelpFile;            //  Show the help file in the default browser
        Exit;
    end;

    if TaskRenameComputerInDomain then begin
        AppendToLogFile('Option                    : Rename Computer in Domain');
        if (OSVerDetailed <> 'WIN2K') and (OSVerDetailed <> 'WINXP') then begin
            AppendToLogFile('Rename in Domain        : Operation not supported on this OS');
            ExitRoutine(11);
        end;
    end;

    if TaskNameSync then begin
        AppendToLogFile('Operation                 : Name Sync Mode');
        ShowGUI := False;
        if LocalAdminRights then //  Can't change the names without administrator rights
        begin
            NameSync;
        end               //  Set host name the same as the netBIOS name
        else begin
            AppendToLogFile('Name Sync               : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskSilent then begin
        AppendToLogFile('Operation                 : Silent (scripted) Mode');
        ShowGUI := False;
        if LocalAdminRights then //  Can't change the names without administrator rights
        begin
            SilentMode;
        end             //  Set the host and netBIOS name as specified on the command line
        else begin
            AppendToLogFile('Silent Mode               :  Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskResolvebyReverseDNS then begin
        AppendToLogFile('Operation                 : Resolve by Reverse DNS Look Up (/DNS)');
        ShowGUI := False;
        if LocalAdminRights then              //  Can't change the names without administrator rights
        begin
            SilentMode;
        end else begin
            AppendToLogFile('Reverse DNS Look Up        : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskUseMACAddressforName then begin
        AppendToLogFile('Operation                 : Use MAC Address for Computer Name');
        ShowGUI := False;
        if LocalAdminRights then //  Can't change the names without administrator rights
        begin
            UseMACAddressforName;
        end   //  Set Computer Name to MAC Address
        else begin
            AppendToLogFile('Use MAC Address for Name  : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskUseIPAddressforName then begin
        AppendToLogFile('Operation                 : Use IP Address for Computer Name');
        ShowGUI := False;
        if LocalAdminRights then //  Can't change the names without administrator rights
        begin
            UseIPAddressforName;
        end   //  Set Computer Name to MAC Address
        else begin
            AppendToLogFile('Use IP Address for Name   : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskUseMyName then begin
        AppendToLogFile('Operation                 : Use Current Users Name as Computer Name');
        ShowGUI := False;
        if LocalAdminRights then       //  Can't change the names without administrator rights
        begin
            UseMyNameforComputerName;
        end    //  Set Computer Name to Username
        else begin
            AppendToLogFile('Use User Name for Name    : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

    if TaskPostGhost and not (PostGhostNameMatch) then begin
        ShowGUI := False;
    end;


    if TaskReadFromDataFile then begin
        AppendToLogFile('Operation                 : Read Name From File');
        ShowGUI := False;
        if LocalAdminRights then       //  Can't change the names without administrator rights
        begin
            ReadNameFromDataFile;
        end         //  Get new name from datafile
        else begin
            AppendToLogFile('Read Name From File       : Can''t Proceed - No Administrator Rights');
            ExitRoutine(9);
        end;
        Exit;
    end;

end;


function OSVer_To_Friendly_Name(strOSVer : string) : string;
begin
    if strOSVer = OS_WIN95 then begin
        Result := 'Microsoft Windows 95';
    end else
    if strOSVer = OS_WIN98 then begin
        Result := 'Microsoft Windows 98';
    end else
    if strOSVer = OS_WINME then begin
        Result := 'Microsoft Windows ME';
    end else
    if strOSVer = OS_WINNT then begin
        Result := 'Microsoft Windows NT 4.0';
    end else
    if strOSVer = OS_WIN2K then begin
        Result := 'Microsoft Windows 2000';
    end else
    if strOSVer = OS_WINXP then begin
        Result := 'Microsoft Windows XP';
    end else
    if strOSVer = OS_WIN2K3 then begin
        Result := 'Microsoft Windows 2003';
    end else begin
        Result := strOSVer;
    end;
end;

function OSVersionToTLA : string;
var
    strOSVer : string;
begin
    strOSVer := GetOSVersion(True);
    if strOSVer = OS_WIN95 then begin
        Result := 'W95';
    end else
    if strOSVer = OS_WIN98 then begin
        Result := 'W98';
    end else
    if strOSVer = OS_WINME then begin
        Result := 'WME';
    end else
    if strOSVer = OS_WINNT then begin
        Result := 'WNT';
    end else
    if strOSVer = OS_WIN2K then begin
        Result := 'W2K';
    end else
    if strOSVer = OS_WINXP then begin
        Result := 'WXP';
    end else
    if strOSVer = OS_WIN2K3 then begin
        Result := 'WK3';
    end else begin
        Result := 'UKN';
    end;
end;

function Replace(Instring, SearchStr, NewStr : string) : string;
var
    place : Integer;
    s1 :    string;

begin
    s1 := Instring;
    repeat
        Place := pos(SearchStr, s1);
        if place > 0 then begin
            Delete(s1, Place, Length(SearchStr));
            Insert(NewStr, s1, Place);
        end;
    until place = 0;
    Result := s1;
end;


procedure RunBatchFileandWait(ExecuteFile, ParamString, StartInString : string);
var
    SEInfo :   TShellExecuteInfo;
    ExitCode : DWORD;
begin
    FillChar(SEInfo, SizeOf(SEInfo), 0);
    SEInfo.cbSize := SizeOf(TShellExecuteInfo);
    with SEInfo do begin
        fMask  := SEE_MASK_NOCLOSEPROCESS;
        Wnd    := Application.Handle;
        lpFile := PChar(ExecuteFile);
{
ParamString can contain the
application parameters.
}
        lpParameters := PChar(ParamString);
{
StartInString specifies the
name of the working directory.
If ommited, the current directory is used.
}
        lpDirectory := PChar(StartInString);
        nShow  := SW_HIDE;
    end;
    if ShellExecuteEx(@SEInfo) then begin
        repeat
            Application.ProcessMessages;
            GetExitCodeProcess(SEInfo.hProcess, ExitCode);
        until (ExitCode <> STILL_ACTIVE) or
            Application.Terminated;
    end;
end;

function GetDNSServer : string;
var
    strDNSServers : string;
    sl : TStringList;
begin
    sl := TStringList.Create;
    AppendToLogFile('Get DNS Server Address    : Checking OS support');
    if (IsDLLOnSystem('iphlpapi.dll')) and (GetOSVersion(True) <> 'WIN95') and (GetOSVersion(True) <> 'WINNT') then begin
        AppendToLogFile('Get DNS Server Address    : IPHLPAPI.DLL found using GetNetworkParams API');
        strDNSServers := GetDNSUsingGetNetworkParams;
    end else begin
        AppendToLogFile('Get DNS Server Address    : IPHLPAPI.DLL NOT found (or Win95/NT4) using alternative DNS address routine');
        strDNSServers := GetDNSUsingScreenScraping;
    end;
    DW_SPlit(strDNSServers, ';', TStrings(sl), qoNOBEGINEND or qoNOCRLF or qoPROCESS);
    AppendToLogFile('Get DNS Server Address    : Returned ' + strDNSServers);
    AppendToLogFile('Get DNS Server Address    : Primary is ' + sl[0]);
    Result := sl[0];
end;

function CreateTempFileName(aPrefix : string) : string;
var
    Buf :  array[0..MAX_PATH] of char;
    Temp : array[0..MAX_PATH] of char;
begin
    GetTempPath(MAX_PATH, Buf);
    GetTempFilename(Buf, PChar(aPrefix), 0, Temp);
    Result := string(Temp);
end;

function GetDNSUsingScreenScraping : string;
var
    OSVersion, strTempDirectory, strTempFile, strPathtoIPConfig, strCmdLine,
    strPathtoComSpec, strLineofText : string;
    blnGotOne : boolean;
    intPos : Integer;
    f : textfile;
begin
    Result      := '';
    blnGotOne   := False;
    OSVersion   := GetOSVersion(False);
    strTempDirectory := GetTempDirectory;
    strTempFile := CreateTempFileName('IPC');

    if FileExists(strTempFile) then begin
        DeleteFile(strTempFile);
    end;

    if OSVersion = 'WIN9X' then begin
        strPathtoIPConfig := FindPathToFile('WINIPCFG.EXE');
        strCmdLine := '/ALL /BATCH ' + strTempFile;
        strPathtoComSpec := FindPathToFile('command.com');
        RunBatchFileandWait(strPathtoIPConfig, strCmdLine, strTempDirectory);
    end else begin
        strPathtoIPConfig := FindPathToFile('IPCONFIG.EXE');
        strCmdLine := strPathtoIPConfig + ' /ALL > ' + strTempFile;
        strPathtoComSpec := FindPathToFile('cmd.exe');
        RunBatchFileandWait(strPathtoComSpec, '/c ' + strCmdLine, strTempDirectory);
    end;
    assignfile(f, strTempFile);
    reset(f);
    repeat
        ReadLn(f, strLineofText);
        strLineofText := Trim(strLineofText);
        intPos := Pos(':', strLineofText);
        if (Pos(UpperCase('DNS Servers'), UpperCase(strLineofText)) <> 0) and (intPos <> 0) then begin
            blnGotOne := True;
            Result    := Result + Trim(Copy(strLineofText, intPos + 1, length(strLineofText) - intPos + 1)) + ';';
        end else
        if (intPos = 0) and (blnGotOne = True) then begin
            if IsValidIPAddress(strLineofText) = True then begin
                Result := Result + strLineofText + ';';
            end;
        end else begin
            blnGotOne := False;
        end;
    until EOF(f);
    Close(f);
    if FileExists(strTempFile) then begin
        DeleteFile(strTempFile);
    end;
end;


function GetDNSUsingGetNetworkParams : string;
type
    Type_GetNetworkParams = function(FI : PFixedInfo; var BufLen : Integer) : Integer; stdcall;
var
    FI :   PFixedInfo;
    Size : Integer;
    Res :  Integer;
    //I                 : Integer;
    intResultCode : Integer;
    DNS :  PIPAddrString;
    _GetNetworkParams : Type_GetNetworkParams;

begin
    Result := '';
    //Result:= TStringList.Create;
    Size   := 1024;
    GetMem(FI, Size);
    intResultCode := LoadLibrary(PChar('iphlpapi.dll'));
    @_GetNetworkParams := GetProcAddress(intResultCode, PChar('GetNetworkParams'));
    Res := _GetNetworkParams(FI, Size);
    FreeLibrary(intResultCode);
    if (Res <> ERROR_SUCCESS) then begin
        SetLastError(Res);
        RaiseLastWin32Error;
    end;
    //Result.Add('Host name: '+FI^.HostName);
    //Result.Add('Domain name: '+FI^.DomainName);
    //If (FI^.CurrentDNSServer <> nil) Then
    //Result.Add('Current DNS Server: '+FI^.CurrentDNSServer^.IPAddress)
    //Else Result.Add('Current DNS Server: (none)');
    //I := 1;
    DNS := @FI^.DNSServerList;
    repeat
        //Result.Add('DNS '+IntToStr(I)+': '+DNS^.IPAddress);
        Result := Result + DNS^.IPAddress + ';';
        //Inc(I);
        DNS    := DNS^.Next;
    until (DNS = nil);

    //Result.Add('Scope ID: '+FI^.ScopeId);
    //Result.Add('Routing: '+IntToStr(FI^.EnableRouting));
    //Result.Add('Proxy: '+IntToStr(FI^.EnableProxy));
    //Result.Add('DNS: '+IntToStr(FI^.EnableDNS));
    FreeMem(FI);
end;

function GetAdapterInformation : TStringList;
type
    Type_GetAdaptersInfo = function(AI : PIPAdapterInfo; var BufLen : Integer) : Integer stdcall;

var
    AI, Work : PIPAdapterInfo;
    Size : Integer;
    Res : Integer;
    I : Integer;
    intResultCode : Integer;
    _GetAdaptersInfo : Type_GetAdaptersInfo;

    function MACToStr(ByteArr : PByte; Len : Integer) : string;
    begin
        Result := '';
        while (Len > 0) do begin
            Result  := Result + IntToHex(ByteArr^, 2); //+'-';
            ByteArr := Pointer(Integer(ByteArr) + SizeOf(byte));
            Dec(Len);
        end;
        //SetLength(Result,Length(Result)-1); { remove last dash }
    end;

    function GetAddrString(Addr : PIPAddrString) : string;
    begin
        Result := '';
        while (Addr <> nil) do begin
            Result := Result + 'A: ' + Addr^.IPAddress + ' M: ' + Addr^.IPMask + #13;
            Addr   := Addr^.Next;
        end;
    end;

    function TimeTToDateTimeStr(TimeT : Integer) : string;
    const
        UnixDateDelta = 25569; { days between 12/31/1899 and 1/1/1970 }
    var
        DT :  TDateTime;
        TZ :  TTimeZoneInformation;
        Res : DWord;

    begin
        if (TimeT = 0) then begin
            Result := '';
        end else begin
            { Unix TIME_T is secs since 1/1/1970 }
            DT  := UnixDateDelta + (TimeT / (24 * 60 * 60)); { in UTC }
            { calculate bias }
            Res := GetTimeZoneInformation(TZ);
            if (Res = TIME_ZONE_ID_INVALID) then begin
                RaiseLastWin32Error;
            end;
            if (Res = TIME_ZONE_ID_STANDARD) then begin
                DT     := DT - ((TZ.Bias + TZ.StandardBias) / (24 * 60));
                Result := DateTimeToStr(DT) + ' ' + WideCharToString(TZ.StandardName);
            end else begin { daylight saving time }
                DT     := DT - ((TZ.Bias + TZ.DaylightBias) / (24 * 60));
                Result := DateTimeToStr(DT) + ' ' + WideCharToString(TZ.DaylightName);
            end;
        end;
    end;

begin
    Result := TStringList.Create;
    Size   := 5120;
    GetMem(AI, Size);

    intResultCode := LoadLibrary(PChar('iphlpapi.dll'));
    @_GetAdaptersInfo := GetProcAddress(intResultCode, PChar('GetAdaptersInfo'));
    Res := _GetAdaptersInfo(AI, Size);
    FreeLibrary(intResultCode);

    if (Res <> ERROR_SUCCESS) then begin
        SetLastError(Res);
        RaiseLastWin32Error;
    end;
    Work := AI;
    I    := 1;
    repeat
        //Adapter Number;ComboIndex;Adapter name;Description;Adapter address; Index; Type; DHCP;
        //Current IP; IP addresses; Gateways; DHCP servers; Has WINS; Primary WINS; Secondary WINS;
        //Lease obtained; Lease expires
        Result.Add(IntToStr(I) + ';' + IntToStr(Work^.ComboIndex) + ';' + Work^.AdapterName + ';' +
            Work^.Description + ';' + MACToStr(@Work^.Address, Work^.AddressLength) + ';' +
            IntToStr(Work^.Index) + ';' + IntToStr(Work^._Type) + ';' + IntToStr(Work^.DHCPEnabled) +
            ';' + GetAddrString(Work^.CurrentIPAddress) + ';' + GetAddrString(@Work^.IPAddressList) +
            ';' + GetAddrString(@Work^.GatewayList) + ';' + GetAddrString(@Work^.DHCPServer) +
            ';' + IntToStr(Integer(Work^.HaveWINS)) + ';' + GetAddrString(@Work^.PrimaryWINSServer) +
            ';' + GetAddrString(@Work^.SecondaryWINSServer) + ';' + TimeTToDateTimeStr(Work^.LeaseObtained) +
            ';' + TimeTToDateTimeStr(Work^.LeaseExpires));

        Inc(I);
        Work := Work^.Next;
    until (Work = nil);
    FreeMem(AI);
end;

 // Split a given string into TStrings with given delimiter character
 // Author:       xpcoder
 // Version:      1.10
 // Date:         5.Mar.2002
 // Parameter:
 //   aValue => aDelimiter separated string
 //   aDelimiter => a character to split the string apart
 //   Result => a provided TStrings to store split string,
 //             remember to typecast to TStrings(x) if x
 //             derivative type of TStrings (e.g. TStringList)
 //             Will be created if one is not assigned
 //   Flag =>
 //        qoPROCESS.....Process quoted string
 //        qoNOBEGINEND..Remove heading and trailing quote
 //        qoNOCRLF......Remove carriage return and line feed characters
 // Limitation:   No unicode support
 //               one and only one character delimiter
 // Usage:
 //   DW_Split( txtInput.Text, ',', TStrings(sl), qoNOBEGINEND or qoNOCRLF or qoPROCESS );

procedure DW_Split(aValue : string; aDelimiter : char; var Result : TStrings; Flag : Integer = $0001);
var
    i :      Integer;
    S, sIn : string;
    q :      boolean;
    canadd : boolean;
    l :      Integer;
    c, qc :  char;
    beqc :   char;
begin
    sIn := trim(aValue);
    l   := Length(sIn);
    if (l < 1) then begin
        exit;
    end;
    if (not Assigned(Result)) then begin
        Result := TStringList.Create;
    end;
    Result.Clear;
    S    := '';
    q    := False;
    qc   := #00;
    beqc := #00;
    i    := 1;
    if ((pos(sIn[1], #34#39) <> 0)) then begin
        beqc := sIn[1];
    end;

    while (i <= l) do begin
        canadd := True;
        c      := sIn[i];
        if ((c <> aDelimiter) or (q)) then begin
            if ((Flag and qoPROCESS) = qoPROCESS) then begin
                if ((pos(c, #34#39) <> 0) and (not q)) then begin
                    qc := c;
                end;
            end;

            if ((Flag and qoNOBEGINEND) = qoNOBEGINEND) then begin
                if ((c = beqc) and ((i = 1) or (i = l))) then begin
                    canadd := False;
                end;
            end;

            if ((Flag and qoNOCRLF) = qoNOCRLF) then begin
                if ((c = #13) or (c = #10)) then begin
                    canadd := False;
                end;
            end;

            if (canadd) then begin
                S := S + c;
            end;

            if (c = qc) then begin
                if (i < l) then begin
                    if (sIn[i + 1] = qc) then begin
                        Inc(i, 2);
                        continue;
                    end;
                end;
                q := not q;
            end;
        end else begin
            Result.Add(S);
            S := '';
        end;
        Inc(i);
    end;
    if S <> '' then begin
        Result.Add(S);
    end;
end;

function ExtractFromGetAdapterInformation(tlAdaperInfo : TStringList; intAdapterIndex, intDataIndex : Integer) : string;
var
    intI : Integer;
    slSL : TStringList;
begin
    Result := '';
    for intI := 0 to tlAdaperInfo.Count - 1 do begin
        //showmessage(tlAdaperInfo[intI]);
        if intI = intAdapterIndex then begin
            slSL := TStringList.Create;
            DW_Split(tlAdaperInfo[intAdapterIndex], ';', TStrings(slSL), qoNOCRLF);
            Result := slSL[intDataIndex];
            slSL.Free;
            Exit;
        end;
    end;
end;


function GetMACAddressLegacy(AdapterNumber : Integer) : string;
type
    TNBLanaResources = (lrAlloc, lrFree);
    PMACAddress      = ^TMACAddress;
    TMACAddress      = array[0..5] of byte;

var
    LanaNum :    byte;
    MACAddress : PMACAddress;
    retCode :    byte;
    ResetNCB, StatNCB : PNCB;
    AdapterStatus : PAdapterStatus;

begin
    LanaNum := 0;
    retcode := 0;

    // ------------------ Reset Procedure ------------------
    New(ResetNCB);
    ZeroMemory(ResetNCB, SizeOf(TNCB));
    try
        with ResetNCB^ do begin
            ncb_lana_num := char(LanaNum);             // Set Lana_Num
            ncb_lsn      := char(lrAlloc);             // Allocation of new resources
            ncb_callname[0] := char(0);                // Query of max sessions
            ncb_callname[1] := #0;                     // Query of max NCBs (default)
            ncb_callname[2] := char(0);                // Query of max names
            ncb_callname[3] := #0;                     // Query of use NAME_NUMBER_1
            ncb_command  := char(NCBRESET);
            NetBios(ResetNCB);
            if byte(ncb_cmd_cplt) <> NRC_GOODRET then begin
                Beep;
                ////////////////////AppendToLogFile('MAC Address             : Reset Error! RetCode = $' + IntToHex(RetCode, 2));
            end;
        end;
    finally
        Dispose(ResetNCB);
    end;
    // ----------------------------------------------

    New(MACAddress);
    try
        New(StatNCB);
        ZeroMemory(StatNCB, SizeOf(TNCB));
        StatNCB.ncb_length := SizeOf(TAdapterStatus) + 255 * SizeOf(TNameBuffer);
        GetMem(AdapterStatus, StatNCB.ncb_length);
        try
            with StatNCB^ do begin
                ZeroMemory(MACAddress, SizeOf(TMACAddress));
                ncb_buffer   := PChar(AdapterStatus);
                ncb_callname := '*              ' + #0;
                ncb_lana_num := char(LanaNum);
                ncb_command  := char(NCBASTAT);
                NetBios(StatNCB);
                retcode := byte(ncb_cmd_cplt);
                if retcode = NRC_GOODRET then begin
                    MoveMemory(MACAddress, AdapterStatus, SizeOf(TMACAddress));
                end;
            end;
        finally
            FreeMem(AdapterStatus);
            Dispose(StatNCB);
        end;

        if RetCode = NRC_GOODRET then begin
            Result := Format('%2.2x%2.2x%2.2x%2.2x%2.2x%2.2x',
                [MACAddress[0], MACAddress[1], MACAddress[2], MACAddress[3], MACAddress[4], MACAddress[5]]);
        end else begin
            Beep;
            Result := 'Error';
            //////////////////AppendToLogFile('MAC Address             : Error Reading Address! RetCode = $' + IntToHex(RetCode, 2));
        end;
    finally
        Dispose(MACAddress);
    end;
end;

// ---------------------------------------------------------------------------

function GetAdapterInformationII : TStringList;
var
    OSVersion, strCmdLine, strTempFile, strPathtoIPConfig, strTempDirectory, strLineofText, strPathtoComSpec,
    strMACAddress, strDescription, strDCHPEnabled, strIPAddress, strSubNetMask, strDefaultGateway, strDHCPServer, strTEMP,
    strDHCPLeaseObtained, strDHCPLeaseExpires, strPrimaryWINSServer, strSecondaryWINSServer, strPrimaryDNSServer,
    strSecondaryDNSServer : string;
    f :      textfile;
    intPos : Integer;
begin
    Result      := TStringList.Create;
    OSVersion   := GetOSVersion(False);
    strTempDirectory := GetTempDirectory;
    strTempFile := CreateTempFileName('IPC');

    if FileExists(strTempFile) then begin
        DeleteFile(strTempFile);
    end;

    if OSVersion = 'WIN9X' then begin
        strPathtoIPConfig := FindPathToFile('WINIPCFG.EXE');
        strCmdLine := '/ALL /BATCH ' + strTempFile;
        strPathtoComSpec := FindPathToFile('command.com');
        RunBatchFileandWait(strPathtoIPConfig, strCmdLine, strTempDirectory);
    end else begin
        strPathtoIPConfig := FindPathToFile('IPCONFIG.EXE');
        strCmdLine := strPathtoIPConfig + ' /ALL > ' + strTempFile;
        strPathtoComSpec := FindPathToFile('cmd.exe');
        RunBatchFileandWait(strPathtoComSpec, '/c ' + strCmdLine, strTempDirectory);
    end;
    //if Not FileExists(strTempFile) then
    //Post Error Here
    assignfile(f, strTempFile);
    reset(f);
    strDescription    := '';
    strMACAddress     := '';
    strDCHPEnabled    := '';
    strIPAddress      := '';
    strSubNetMask     := '';
    strDefaultGateway := '';
    strDHCPServer     := '';
    strDHCPLeaseObtained := '';
    strDHCPLeaseExpires := '';
    strPrimaryWINSServer := '';
    strSecondaryWINSServer := '';
    strPrimaryDNSServer := '';
    strSecondaryDNSServer := '';
    repeat
        ReadLn(f, strLineofText);
        strLineofText := Trim(strLineofText);
        intPos := Pos(':', strLineofText);
        if intPos <> 0 then begin
            strTEMP := Trim(Copy(strLineofText, intPos + 1, length(strLineofText) - intPos + 1));
        end;
        if (Pos(UpperCase('Description'), UpperCase(strLineofText)) <> 0) then begin
            if strDescription <> '' then begin
                Result.Add('Adapter Number;ComboIndex;AdapterName;' + strDescription + ';' + strMACAddress +
                    ';Index;Type;' + strDCHPEnabled + ';CurrentIPAddress;' + strIPAddress + ';' + strSubNetMask + ';' +
                    strDefaultGateway + ';' + strDHCPServer + ';HaveWINS' + ';' + strPrimaryWINSServer + ';' +
                    strSecondaryWINSServer + ';' + strDHCPLeaseObtained + ';' + strDHCPLeaseExpires + ';' + strPrimaryDNSServer +
                    ';' + strSecondaryDNSServer);
                strMACAddress     := '';
                strDescription    := '';
                strDCHPEnabled    := '';
                strIPAddress      := '';
                strSubNetMask     := '';
                strDefaultGateway := '';
                strDHCPServer     := '';
                strDHCPLeaseObtained := '';
                strDHCPLeaseExpires := '';
                strPrimaryWINSServer := '';
                strSecondaryWINSServer := '';
                strPrimaryDNSServer := '';
                strSecondaryDNSServer := '';
            end;
            strDescription := strTEMP;
        end else
        if (Pos(UpperCase('Physical Address'), UpperCase(strLineofText)) <> 0) then begin
            strMACAddress := Replace(strTEMP, '-', '');
        end else
        if (Pos(UpperCase('Dhcp Enabled'), UpperCase(strLineofText)) <> 0) then begin
            strDCHPEnabled := strTEMP;
        end else
        if (Pos(UpperCase('IP Address'), UpperCase(strLineofText)) <> 0) then begin
            strIPAddress := strTEMP;
        end else
        if (Pos(UpperCase('Subnet Mask'), UpperCase(strLineofText)) <> 0) then begin
            strSubNetMask := strTEMP;
        end else
        if (Pos(UpperCase('Default Gateway'), UpperCase(strLineofText)) <> 0) then begin
            strDefaultGateway := strTEMP;
        end else
        if (Pos(UpperCase('DHCP Server'), UpperCase(strLineofText)) <> 0) then begin
            strDHCPServer := strTEMP;
        end else
        if (Pos(UpperCase('Lease Obtained'), UpperCase(strLineofText)) <> 0) then begin
            strDHCPLeaseObtained := strTEMP;
        end else
        if (Pos(UpperCase('Lease Expires'), UpperCase(strLineofText)) <> 0) then begin
            strDHCPLeaseExpires := strTEMP;
        end else
        if (Pos(UpperCase('Primary WINS Server'), UpperCase(strLineofText)) <> 0) then begin
            strPrimaryWINSServer := strTEMP;
        end else
        if (Pos(UpperCase('Secondary WINS Server'), UpperCase(strLineofText)) <> 0) then begin
            strSecondaryWINSServer := strTEMP;
        end else
        if (Pos(UpperCase('DNS Servers'), UpperCase(strLineofText)) <> 0) then begin
            strPrimaryDNSServer := strTEMP;
        end
    until EOF(f);
    if strDescription <> '' then begin
        Result.Add('Adapter Number;ComboIndex;AdapterName;' + strDescription + ';' + strMACAddress +
            ';Index;Type;' + strDCHPEnabled + ';CurrentIPAddress;' + strIPAddress + ';' + strSubNetMask + ';' +
            strDefaultGateway + ';' + strDHCPServer + ';HaveWINS' + ';' + strPrimaryWINSServer + ';' +
            strSecondaryWINSServer + ';' + strDHCPLeaseObtained + ';' + strDHCPLeaseExpires + ';' + strPrimaryDNSServer +
            ';' + strSecondaryDNSServer);
    end;
    closefile(f);
    if FileExists(strTempFile) then begin
        DeleteFile(strTempFile);
    end;
end;

// ---------------------------------------------------------------------------

function ReverseDNSLookup(strIPAddress, strDNSServer : string; intPTRTimeOut : Integer; out strResult : string) : boolean;
var
    frmPTRQuery : TForm;
    Inst : TInstance;
begin
    Inst := TInstance.Create;
    Inst.intPTRResult := -99;
    frmPTRQuery := TForm.Create(Application); // Create frmPTRQuery
    Inst.Timer1 := TTimer.Create(frmPTRQuery);
    Inst.DNSQuery1 := TDNSQuery.Create(frmPTRQuery);
    Inst.Timer1.Enabled := False;
    Inst.Timer1.Interval := intPTRTimeOut;
    Inst.Timer1.OnTimer := Inst.PTRQueryOnTimeOut;
    Inst.DnsQuery1.OnRequestDone := Inst.DnsQuery1RequestDone;
    Inst.DnsQuery1.Addr := strDNSServer; //DNS Server
    try
        Inst.DnsQuery1.PTRLookup(strIPAddress);
    except
        Inst.intPTRResult := -1;
    end;
    Inst.Timer1.Enabled := True;
    repeat
        Application.ProcessMessages;
    until Inst.intPTRResult <> -99;
    Inst.Timer1.Enabled := False;
    case Inst.intPTRResult of
        -1 : begin
            Result    := False;
            strResult := 'Reverse Lookup Failed. (IP Transport Failure)';
        end;
        0 : begin
            Result    := True;
            strResult := Inst.DnsQuery1.Hostname[0];
        end;
        1 : begin
            Result    := False;
            strResult := 'Reverse Lookup Failed. (DNS TimeOut)';
        end;
        else begin
            Result    := False;
            strResult := 'Reverse Lookup Failed. (error = ' + IntToStr(Inst.intPTRResult) + ')';
        end;

    end; //Case
    Inst.DNSQuery1.Free;
    Inst.Timer1.Free;
    Inst.Free;
    frmPTRQuery.Free;
end;

// ---------------------------------------------------------------------------

procedure TInstance.PTRQueryOnTimeOut(Sender : TObject);
begin
    intPTRResult := 1; //Time Out
end;

// ---------------------------------------------------------------------------

procedure TInstance.DnsQuery1RequestDone(Sender : TObject; Error : Word);
begin
    Timer1.Enabled := False;
    intPTRResult   := Error;
end;

/// ---------------------------------------------------------------------------

function MagicChango(strInput, sID, strReplacementString : string; iTruncateSide : Integer) : string;
var
    intI : Integer;
    strInputModified : string;
begin
    if ReplacementStringSizeSpecified(sID, strInput, intI, strInputModified) then begin
        if iTruncateSide = TRIM_LEFT then begin
            strReplacementString := Copy(strReplacementString, 1, intI);
        end   // Copy from Left
        else begin
            strReplacementString := Copy(strReplacementString, length(strReplacementString) - intI + 1, intI + 1);
        end;  // Copy from Right
        strInput := strInputModified;
    end;
    Result := StringReplace(strInput, sID, strReplacementString, [rfReplaceAll, rfIgnoreCase]);
end;

// ---------------------------------------------------------------------------

function ReplacementStringSizeSpecified(strMarker, strInput : string; out intStringSize : Integer;
    out strOutput : string) : boolean;
var
    intI, intJ : Integer;
    strScratch : string;
begin
    ReplacementStringSizeSpecified := False;
    intI := pos(strMarker, strInput) + Length(strMarker);
    if intI + 1 < length(strInput) then begin
        if strInput[IntI] = '[' then begin
            strScratch := Copy(strInput, intI, Length(strInput) - intI + 1);
            intJ := pos(']', strScratch);
            if intJ <> 0 then begin
                strScratch := Copy(strScratch, 2, intJ - 2);
                Delete(strInput, intI, intJ);
                intStringSize := MyStrtoInt(strScratch, True);
                strOutput     := strInput;
                ReplacementStringSizeSpecified := True;
            end;
        end;
    end;
end;

// ---------------------------------------------------------------------------

function PadIPAddress(strIPAddress : string) : string;
var
    IPOctet :    array[1..4] of string;
    strPad :     string;
    intI, intJ : Integer;
begin
    //Add test for valid IP address here!
    intI := pos('.', strIPAddress);
    IPOctet[1] := copy(strIPAddress, 1, intI - 1);
    Delete(strIPAddress, 1, intI);
    intI := pos('.', strIPAddress);
    IPOctet[2] := copy(strIPAddress, 1, intI - 1);
    Delete(strIPAddress, 1, intI);
    intI := pos('.', strIPAddress);
    IPOctet[3] := copy(strIPAddress, 1, intI - 1);
    Delete(strIPAddress, 1, intI);
    IPOctet[4] := strIPAddress;
    for intI := 1 to 4 do begin
        strPad := '';
        for intJ := Length(IPOctet[intI]) + 1 to 3 do begin
            strPad := strPad + '0';
        end;
        IPOctet[intI] := strPad + IPOctet[intI];
    end;
    Result := IPOctet[1] + '.' + IPOctet[2] + '.' + IPOctet[3] + '.' + IPOctet[4];
end;

// ---------------------------------------------------------------------------

function MyStrtoInt(x : string; blnStrict : boolean) : Integer;
var
    i : Integer;
    badchar : boolean;
begin
    badchar := False;
    for i := 1 to length(x) do begin
        if not (x[i] in ['0'..'9']) then begin
            badchar := True;
            Break;
        end;
    end;
    if badchar and not blnStrict then begin
        x := copy(x, 1, i - 1);
    end else
    if badchar and blnStrict then begin
        x := '0';
    end else
    if length(x) = 0 then begin
        x := '0';
    end;
    Result := StrToInt(x);
end;

// ---------------------------------------------------------------------------

end.
