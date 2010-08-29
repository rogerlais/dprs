unit pctprepUtils;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    StdCtrls, Registry, ShellApi, ExtCtrls, FileCtrl, NB30,
    WinSvc;

const
    OS_WIN95: string         = 'WIN95';
    OS_WIN98: string         = 'WIN98';
    OS_WINME: string         = 'WINME';
    OS_WINNT: string         = 'WINNT';
    OS_WIN2K: string         = 'WIN2K';
    OS_WINXP: string         = 'WINXP';
    OS_WIN2K3: string        = 'WIN2K3';


function RenameComputer(newname : string; UnRegisterFromNDS, RebootOnCompletion : boolean) : integer;

implementation

uses
   APIHnd, WinNetHnd;

function GetOSVersionStr(blnDetailed : boolean) : string;
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


procedure CheckValidityofCompterName(const ComputerNametoCheck : string);
const
    VALIDCHARS = ['a'..'z', 'A'..'Z', '0'..'9', '!', '@', '#', '$', '%', '^', '&', '(', ')', '-', '_', '''', '{', '}', '~'];
    //removed '.'
var
    i : Integer;
    blnAllNumeric : boolean;
begin
    if (GetOSVersionStr(False) = OS_WINNT) and (GetOSVersionStr(True) <> OS_WINNT) then begin
        // Only want to check for numeric names on Windows 2000 or above
        blnAllNumeric := True;
        for i := 1 to length(ComputerNametoCheck) do begin
            if not (ComputerNametoCheck[i] in ['0'..'9']) then begin
                blnAllNumeric := False;
                Break;
            end;
        end;
        if blnAllNumeric then begin
            raise Exception.CreateFmt('Apenas números não permitidos para plataforma %s', [GetOSVersionStr(True)]);
        end;
    end;
    if length(ComputerNametoCheck) > MAX_COMPUTERNAME_LENGTH then begin
        raise Exception.CreateFmt('Nome do computador muito longo: "%s"', [ComputerNametoCheck]);
    end;
    if ComputerNametoCheck[1] = '-' then begin
        raise Exception.CreateFmt('Nome do computador inicia com caracter inválido: "%s"', [ComputerNametoCheck]);
    end;
    for i := 1 to length(ComputerNametoCheck) do begin
        if not (ComputerNametoCheck[i] in VALIDCHARS) then begin
            raise Exception.CreateFmt('Nome do computador possui um ou mais caracteres inválidos: "%s" [%s]',
                [ComputerNametoCheck, ComputerNametoCheck[i]]);
        end;
    end;
end;



function RenameComputer(newname : string; UnRegisterFromNDS, RebootOnCompletion : boolean) : integer;
var
    tmpstr, OSVer, LocalComputerName : string;
    res : boolean;
begin
    OSVer := GetOSVersionStr(True);
    try
        CheckValidityofCompterName(newname)
    except
        on E : Exception do begin
            {TODO -oroger -cdsg : Ação de registro de erro}
        end;
    end;
    LocalComputerName:=WinNetHnd.GetComputerName();
    if SameText(LocalComputerName, newName) then begin
        Result := ERROR_XP_ALREADY_DONE;
        Exit;
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

end.
