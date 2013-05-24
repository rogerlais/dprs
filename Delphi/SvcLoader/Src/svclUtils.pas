{$IFDEF svclUtils}
     {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I SvcLoader.inc}

unit svclUtils;

interface


uses
    Classes, SysUtils, AppLog, JwaWindows;
// todas as units ao lado são agrupadas na JwaWindows JwaWinNT, JwaWinType, JwaNtStatus, JwaNtSecApi, JwaLmCons;

type
    ESVCLException = class(ELoggedException);

function LogonAsServiceToAccount(AAccountName : string) : DWORD;
function AddPrivilegeToAccount(AAccountName, APrivilege : string) : DWORD;

function MD5(const fileName : string) : string; overload;
function MD5(const strm : TStream) : string; overload;   {TODO -oroger -clib : deslocar ambas para biblioteca comum}


implementation

uses IdHashMessageDigest, idHash;


function MD5(const fileName : string) : string;
var
    fs : TFileStream;
begin
    fs := TFileStream.Create(fileName, fmOpenRead or fmShareDenyWrite);
    try
        Result := MD5(fs);
    finally
        fs.Free;
    end;
end;

function MD5(const strm : TStream) : string;
var
	 idmd5 : TIdHashMessageDigest5;
begin
	 strm.Seek( 0, soBeginning );
	 idmd5 := TIdHashMessageDigest5.Create;
	 try
		 Result := idmd5.HashStreamAsHex(strm);
    finally
        idmd5.Free;
    end;
end;

function AddPrivilegeToAccount(AAccountName, APrivilege : string) : DWORD;
var
    lStatus : TNTStatus;
    lObjectAttributes : TLsaObjectAttributes;
    lPolicyHandle : TLsaHandle;
    lPrivilege : TLsaUnicodeString;
    lSid :    PSID;
    lSidLen : DWORD;
    lTmpDomain : string;
    lTmpDomainLen : DWORD;
    lTmpSidNameUse : TSidNameUse;
{$IFDEF UNICODE}
    lPrivilegeWStr : string;
{$ELSE}
    lPrivilegeWStr : WideString;
{$ENDIF}
begin
    ZeroMemory(@lObjectAttributes, SizeOf(lObjectAttributes));
    lStatus := LsaOpenPolicy(nil, lObjectAttributes, POLICY_LOOKUP_NAMES, lPolicyHandle);

    if lStatus <> STATUS_SUCCESS then begin
        Result := LsaNtStatusToWinError(lStatus);
        Exit;
    end;

    try
        lTmpDomainLen := JwaWindows.DNLEN; // In 'clear code' this should be get by LookupAccountName
        //lTmpDomainLen := JwaLmCons.DNLEN; // In 'clear code' this should be get by LookupAccountName
        SetLength(lTmpDomain, lTmpDomainLen);

        lSidLen := SECURITY_MAX_SID_SIZE;
        GetMem(lSid, lSidLen);
        try
            if LookupAccountName(nil, PChar(AAccountName), lSid, lSidLen, PChar(lTmpDomain),
                lTmpDomainLen, lTmpSidNameUse) then begin
                lPrivilegeWStr := APrivilege;

                lPrivilege.Buffer := PWideChar(lPrivilegeWStr);
                lPrivilege.Length := Length(lPrivilegeWStr) * SizeOf(char);
                lPrivilege.MaximumLength := lPrivilege.Length;

                lStatus := LsaAddAccountRights(lPolicyHandle, lSid, @lPrivilege, 1);
                Result  := LsaNtStatusToWinError(lStatus);
            end else begin
                Result := GetLastError;
            end;
        finally
            FreeMem(lSid);
        end;
    finally
        LsaClose(lPolicyHandle);
    end;
end;

function LogonAsServiceToAccount(AAccountName : string) : DWORD;
begin
    Result := AddPrivilegeToAccount(AAccountName {or any account/group name}, SE_SERVICE_LOGON_NAME);
end;

end.
