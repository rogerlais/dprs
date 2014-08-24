{$IFDEF pctprepUtils}
	 {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I PCTPrep.inc}

unit pctprepUtils;

interface

uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    StdCtrls, Registry, ShellApi, ExtCtrls, FileCtrl, NB30,
	 WinSvc, Contnrs, AppLog;

const
    OS_WIN95: ansistring  = 'WIN95';
    OS_WIN98: ansistring  = 'WIN98';
    OS_WINME: ansistring  = 'WINME';
    OS_WINNT: ansistring  = 'WINNT';
    OS_WIN2K: ansistring  = 'WIN2K';
    OS_WINXP: ansistring  = 'WINXP';
    OS_WIN2K3: ansistring = 'WIN2K3';

type
    TTREPct = class;

    TTREPctZone = class(TStringList)
    private
        FId : Integer;
    public
        constructor Create(AZoneId : Integer);
        destructor Destroy; override;
        property Id : Integer read FId;
        function Add(PCT : TTREPct) : Integer; reintroduce; overload;
    end;


    TTREPct = class
    private
        FName :        string;
        FIp :          string;
        FSubNet :      string;
        FDescription : string;
        FId :          Integer;
    public
        constructor Create(APCTId : Integer; const AName, AIp, ASubNet, ADescription : string); virtual;
        procedure Prepare;
        property Id : Integer read FId;
        property Computername : string read FName;
        property Subnet : string read FSubNet;
        property Ip : string read FIp;
    end;

    TTREPctZoneList = class(TStringList)
    private
        function AddPct(const sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN, sDescription : ansistring) : Integer;
    public
        constructor Create;
        destructor Destroy; override;
        procedure LoadFromCSV(const Filename : string);
    end;

	 ETREPctException = class( ELoggedException );

function RenameComputer(newname, CompDescription : ansistring) : Integer;
function GetComputerDomain() : ansistring;
function SetIpConfig(const NewIpAddr : string; const NewGateWay : string = ''; const NewSubnet : string = '') : Integer;

implementation

uses
	 APIHnd, StrHnd, WinNetHnd, WinReg32, LmCons, LmErr, LmWksta, LmJoin, Variants, ComObj, ActiveX, UrlMon, TREUtils;

 // ====================================================
 // Set DNS Servers
 // Instead of Primary and Alternate you may wish
 // to rewrite this using array of string as the
 // parameters as SetDNSServerSearchOrder will take
 // a list of many DNS addresses. I only have use for
 // Primary and Alternate.
 // ====================================================

function SetDnsServers(const APrimaryDNS : string;
    const AAlternateDNS : string = '') : Integer;
var
	 Retvar :   Integer;
	 oBindObj : IDispatch;
	 oNetAdapters, oNetAdapter, oDnsAddr, oWMIService : olevariant;
	 i, iValue, iSize : longword;
	 oEnum :    IEnumvariant;
	 oCtx :     IBindCtx;
	 oMk :      IMoniker;
	 sFileObj : WideString;
begin
	 Retvar   := 0;
	 sFileObj := 'winmgmts:\\.\root\cimv2';
	 iSize    := 0;
	 if APrimaryDNS <> '' then begin
		 Inc(iSize);
	 end;
	 if AAlternateDNS <> '' then begin
		 Inc(iSize);
	 end;

	 // Create OLE [IN} Parameters
	 if iSize > 0 then begin
		 oDnsAddr    := VarArrayCreate([1, iSize], varOleStr);
		 oDnsAddr[1] := APrimaryDNS;
		 if iSize > 1 then begin
			 oDnsAddr[2] := AAlternateDNS;
		 end;
	 end;

	 // Connect to WMI - Emulate API GetObject()
	 OleCheck(CreateBindCtx(0, oCtx));
	 OleCheck(MkParseDisplayNameEx(oCtx, PWideChar(sFileObj), i, oMk));
    OleCheck(oMk.BindToObject(oCtx, nil, IUnknown, oBindObj));
    oWMIService := oBindObj;

    oNetAdapters := oWMIService.ExecQuery('Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE');
    oEnum := IUnknown(oNetAdapters._NewEnum) as IEnumVariant;

    while oEnum.Next(1, oNetAdapter, iValue) = 0 do begin
        try
            if iSize > 0 then begin
                Retvar := oNetAdapter.SetDNSServerSearchOrder(oDnsAddr);
            end else begin
                Retvar := oNetAdapter.SetDNSServerSearchOrder();
            end;
        except
            Retvar := -1;
        end;

        oNetAdapter := Unassigned;
    end;

    oDnsAddr := Unassigned;
    oNetAdapters := Unassigned;
    oWMIService := Unassigned;
    Result := Retvar;
end;


function SetIpConfig(const NewIpAddr : string; const NewGateWay : string = ''; const NewSubnet : string = '') : Integer;
var
    Retvar :   Integer;
    objBind :  IDispatch;
    objAllAdapters, objNetAdapter, oIpAddress, oGateWay, oWMIService, oSubnetMask, oDNSSet : olevariant;
    i, iValue : longword;
    oEnum :    IEnumvariant;
    oCtx :     IBindCtx;
    oMk :      IMoniker;
    sFileObj : WideString;
begin
    Retvar   := 0;
    sFileObj := 'winmgmts:\\.\root\cimv2';

    // Criação dos parametros OLE de entrada
    oIpAddress    := VarArrayCreate([1, 1], varOleStr);
    oIpAddress[1] := NewIpAddr;
    oGateWay      := VarArrayCreate([1, 1], varOleStr);
    oGateWay[1]   := NewGateway;
    oSubnetMask   := VarArrayCreate([1, 1], varOleStr);
    if NewSubnet = '' then begin
        oSubnetMask[1] := '255.255.255.0';
    end else begin
        oSubnetMask[1] := NewSubnet;
    end;
    //Ajusta os DNS hardcoded
    oDNSSet    := VarArrayCreate([1, 2], varOleStr);
    oDNSSet[1] := '10.12.1.12';
    oDNSSet[2] := '10.12.1.0';


    // Connect to WMI - Emulate API GetObject()
    OleCheck(CreateBindCtx(0, oCtx));
    OleCheck(MkParseDisplayNameEx(oCtx, PWideChar(sFileObj), i, oMk));
    OleCheck(oMk.BindToObject(oCtx, nil, IUnknown, objBind));
    oWMIService := objBind;

    //Monta consulta para todos os adaptadores ativos(cabo de rede conectado)
    objAllAdapters := oWMIService.ExecQuery('Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE');
    oEnum := IUnknown(objAllAdapters._NewEnum) as IEnumVariant;

    while oEnum.Next(1, objNetAdapter, iValue) = 0 do begin //Varre todos os adaptadores
        try
            if (NewIpAddr = EmptyStr) or SameText(NewIpAddr, 'DHCP') then begin
                Retvar := objNetAdapter.EnableDHCP; //desnecessário ajustar o gateway neste caso
            end else begin
                // ajustar IP de forma estática
                Retvar := objNetAdapter.EnableStatic(oIpAddress, oSubnetMask);
                if (Retvar = 0) and (NewGateway <> '') then begin // troca de gateway
                    Retvar := objNetAdapter.SetGateways(oGateway);
                    if (Retvar = 0) then begin // troca DNS
                        Retvar := objNetAdapter.SetDNSServerSearchOrder(oDNSSet);
                    end;
                end;
                {TODO -oroger -clib : Local para colocar quaisquer limpezas de caches e regitro de dns externo, etc}
            end;
        except
            Retvar := -1;
        end;

        objNetAdapter := Unassigned; //liberar as instancias
    end;

    //liberar as instancias
    oDNSSet     := Unassigned;
    oGateWay    := Unassigned;
    oSubnetMask := Unassigned;
    oIpAddress  := Unassigned;
    objAllAdapters := Unassigned;
    oWMIService := Unassigned;
    Result      := Retvar;
end;

function RenameComputerInWorkGroup(CompName : ansistring) : NET_API_STATUS;
type
    ProtoSetComputerNameEx = function(nType : TComputerNameFormat; NewName : PAnsiChar) : boolean stdcall;
    ProtoNetJoinDomain = function(lpServer, lpDomain, lpAccountOU, lpAccount, lpPassword : LPCWSTR; fJoinOptions :
            DWORD) : NET_API_STATUS; stdcall;
var
    FuncSetComputerNameEx : ProtoSetComputerNameEx;
    FuncJoinDomain : ProtoNetJoinDomain;
    MHandle, NHandle : longint;
    grp :    string;
    zoneId : Integer;
begin
    zoneId  := TTREUtils.GetComputerZone(CompName);
    MHandle := LoadLibrary('kernel32.dll');
    NHandle := LoadLibrary('netapi32.dll');
    try
        //Grupo de trabalho
        @FuncJoinDomain := GetProcAddress(NHandle, 'NetJoinDomain');
        grp    := 'ZNE-PB' + Format('%3.3d', [zoneId]);    { TODO -oroger -cdsg : Resolver como ajustar o novo grupo de trabalho deste computador }
        Result := FuncJoinDomain(nil, PWideChar(grp), nil, nil, nil, 0);
        if Result = NERR_Success then begin

            //Nome do computador
            @FuncSetComputerNameEx := GetProcAddress(MHandle, 'SetComputerNameExA');
            if not FuncSetComputerNameEx(ComputerNamePhysicalDnsHostname, PAnsiChar(CompName)) then begin
                Result := GetLastError();
            end else begin
                Result := NERR_Success;
            end;
        end;
    finally
        FreeLibrary(MHandle);
        FreeLibrary(NHandle);
    end;
end;

function RenameComputerInDomain(strTargetComputer, CompName, strUserID, strPassword : string) : NET_API_STATUS;
var
    pwcNewComputerName, pwcUserID, pwcPassword,
    pwcTargetComputer : PWideChar;
begin
    pwcNewComputerName := nil;
    pwcUserID   := nil;
    pwcPassword := nil;
    pwcTargetComputer := nil;
    try
        GetMem(pwcNewComputerName, 2 * Length(CompName) + 2);
        GetMem(pwcUserID, 2 * Length(strUserID) + 2);
        GetMem(pwcPassword, 2 * Length(strPassword) + 2);
        GetMem(pwcTargetComputer, 2 * Length(strTargetComputer) + 2);
        StringToWideChar(CompName, pwcNewComputerName, Length(CompName) + 2);
        StringToWideChar(strUserID, pwcUserID, Length(strUserID) + 2);
        StringToWideChar(strPassword, pwcPassword, Length(strPassword) + 2);
        StringToWideChar(strTargetComputer, pwcTargetComputer, Length(strTargetComputer) + 2);
        Result := NetRenameMachineInDomain(pwcTargetComputer, pwcNewComputerName, pwcUserID, pwcPassword, 2);
    finally
        FreeMem(pwcNewComputerName);
        FreeMem(pwcUserID);
        FreeMem(pwcPassword);
        FreeMem(pwcTargetComputer);
    end;
end;

function GetComputerDomain() : ansistring;
var
    PBuf : PWkstaInfo100;
    Res :  longint;
begin
    {TODO -oroger -clib : Portar para library}
    Result := EmptyAnsiStr;
    Res    := NetRenameMachineInDomain(nil, nil, nil, nil, 0);
    if Res <> NERR_SetupNotJoined then begin //Computador não pertence a nenhum dominio
        Res := NetWkstaGetInfo(nil, 100, @PBuf);
        if Res = NERR_Success then begin
            Result := ansistring(PBuf^.wki100_langroup);
        end;
    end;
end;

procedure SetComputerDescription(ACompDescription : string);
const
    WinNTComputerDescriptionKey: string =
        'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\parameters\srvcomment';
var
    Reg : TRegistryNT;
begin
    Reg := TRegistryNT.Create;
    try
        if ACompDescription <> EmptyStr then begin
            if Length(ACompDescription) > 256 then begin //trunca descrição ao limite máximo
                ACompDescription := Copy(ACompDescription, 1, 256);
            end;
            Reg.WriteFullString(WinNTComputerDescriptionKey, ACompDescription, True);
        end else begin
            Reg.DeleteFullValue(WinNTComputerDescriptionKey);
        end;
    finally
        Reg.Free;
    end;
end;

function GetOSVersionStr(blnDetailed : boolean) : ansistring;
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

procedure SetLocalLogOnTo(NewName : ansistring);
const
    DEFAULT_LOCAL_LOGON_NAME = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\DefaultDomainName';
var
    Reg : TRegistryNT;
begin
    if GetOSVersionStr(False) = OS_WINNT then begin
        Reg := TRegistryNT.Create;
        try
            Reg.WriteFullString(DEFAULT_LOCAL_LOGON_NAME, NewName, True);
        finally
            Reg.Free;
        end;
    end else begin
        raise Exception.Create('Ajuste de logon local não suportado para esta plataforma');
    end;
end;

procedure CheckValidityofCompterName(const ComputerNametoCheck : ansistring);
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
            if not CharInSet(ComputerNametoCheck[i], ['0'..'9']) then begin
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
        if not CharInSet(ComputerNametoCheck[i], VALIDCHARS) then begin
            raise Exception.CreateFmt('Nome do computador possui um ou mais caracteres inválidos: "%s" [%s]',
                [ComputerNametoCheck, ComputerNametoCheck[i]]);
        end;
    end;
end;

function RenameComputer(newname, CompDescription : ansistring) : Integer;
var
    OSVer, DomainName, LocalComputerName : ansistring;
begin
    OSVer := GetOSVersionStr(True);
    try
        CheckValidityofCompterName(newname)
    except
        on E : Exception do begin
            raise ETREPctException.Create( 'Validação do novo nome do computador falhou'#13 + E.Message  );
        end;
    end;
    LocalComputerName := AnsiString( WinNetHnd.GetComputerName() );
    if SameText(LocalComputerName, newName) then begin
        Result := ERROR_XP_ALREADY_DONE;
        Exit;
    end;
    DomainName := GetComputerDomain();
    if DomainName = EmptyAnsiStr then begin
        Result := RenameComputerInWorkGroup(newname);     //SetComputerNameEx - W2K and XP only
        if Result = NERR_Success then begin
            //Logon local dirigido para o mesmo nome do computador sempre
            SetLocalLogOnTo(newname);
        end;

    end else begin
		 Result := E_NOTIMPL;
        //Result := RenameComputerInDomain('', newname, 'LOGIN_ADM', 'PWD_ADM');
        //NetRenameMachineInDomain - W2K and XP only
    end;

    if Result = NERR_Success then begin

        if CompDescription <> EmptyStr then begin
            SetComputerDescription(CompDescription);
        end;

        //Local para rotinas de ajustes do registro de DNS
         (*
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
             if not WinExit(EWX_REBOOT or EWX_FORCE) then begin
                 APIHnd.TAPIHnd.CheckAPI( GetLastError() );
             end;
         end;
         *)
    end;

end;

function TTREPctZone.Add(PCT : TTREPct) : Integer;
var
    idx :    Integer;
    pctKey : string;
begin
    pctKey := Format('%2.2d', [PCT.Id]);
    idx    := Self.IndexOf(pctKey);
    if idx >= 0 then begin
        raise Exception.CreateFmt('Redundância para par (zona, pct) = (%d, %d )', [Self.Id, PCT.Id]);
    end else begin
        Result := Self.AddObject(pctKey, PCT);
    end;
end;

constructor TTREPctZone.Create(AZoneId : Integer);
begin
    inherited Create;
    Self.Sorted := True;
    Self.FId    := AZoneId;
end;

destructor TTREPctZone.Destroy;
var
    x : Integer;
begin
    for x := 0 to Self.Count - 1 do begin
        Self.Objects[x].Free;
    end;
    inherited;
end;

constructor TTREPct.Create(APCTId : Integer; const AName, AIp, ASubNet, ADescription : string);
begin
    Self.FId     := APCTId;
    Self.FName   := AName;
    Self.FIp     := AIp;
    Self.FSubNet := ASubNet;
    Self.FDescription := ADescription;
end;

function TTREPCTZoneList.AddPct(const sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN, sDescription : ansistring) : Integer;
var
    zone : TTREPctZone;
    zoneId, PctId, idx : Integer;
    zoneKey, pctKey : string;
    pct :  TTREPct;
begin
	//insere lista dupla de zonas e pcts por zonas}
    zoneid  := StrToInt(sZone);
	 zoneKey := Format('%3.3d', [zoneId]);
	 idx     := Self.IndexOf(zoneKey);
	 if idx >= 0 then begin
        zone := TTREPctZone(Self.Objects[idx]);
    end else begin
        zone := TTREPctZone.Create(zoneId);
        Self.AddObject(zoneKey, zone);
    end;

    //Zona carregada localizar o pct
    PctId  := StrToInt(sPctId);
    pctKey := Format('%2.2d', [pctId]);
    idx    := zone.IndexOf(pctKey);
    if idx >= 0 then begin
        raise Exception.CreateFmt('Duplicidade de informações para o par(%s, %s)', [zoneKey, pctKey]);
    end else begin
        pct := TTREPct.Create(PctId, sPctName, sPctIP, '255.255.255.0', sDescription);
    end;
    Result := zone.Add(pct);
end;

constructor TTREPctZoneList.Create;
begin
    inherited;
    Self.Sorted := True;
end;

destructor TTREPctZoneList.Destroy;
var
    x : Integer;
begin
    for x := 0 to Self.Count - 1 do begin
        Self.Objects[x].Free;
    end;
    inherited;
end;

procedure TTREPCTZoneList.LoadFromCSV(const Filename : string);
const
    DELIMS: TSysCharSet = [';', #13, #10];
var
    parser :  TBufferedStringStream;
    fs :      TFileStream;
    sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN : ansistring;
    lineIdx : Integer;
begin
    fs := TFileStream.Create(Filename, fmOpenRead + fmShareDenyWrite);
    try
        parser := TBufferedStringStream.Create(fs);
        try
            parser.SetWordDelimiters(@DELIMS);
            parser.Reset;
            parser.ReadLine; //ignora 1a linha
            lineIdx := 2;
            try
                while not parser.EoS do begin
                    sZone    := parser.ReadStringWord;
                    sCity    := parser.ReadStringWord;
                    sPctId   := parser.ReadStringWord;
                    sPctName := parser.ReadStringWord;
                    sPctIP   := parser.ReadStringWord;
                    sPctWAN  := parser.ReadStringWord;
                    parser.ReadStringWord;
                    //parser.ReadLine; //descarta demais informações da linha
                    Self.AddPct(sZone, sCity, sPctId, sPctName, sPctIP, sPctWAN, sCity);
                    Inc(lineIdx);
                end;
            except
                on E : Exception do begin
                    raise Exception.CreateFmt('Erro lendo arquivo na linha %d'#13'%s', [lineIdx, E.Message]);
                end;
            end;
        finally
            parser.Free;
        end;
    finally
        fs.Free;
    end;
end;

procedure TTREPct.Prepare;
const
    SIS_DELIVERY = 'HKEY_LOCAL_MACHINE\SOFTWARE\Modulo\SISDELIVERY\PDC';
var
    ret : Integer;
    reg : TRegistryNT;
begin
    try
         {$IFDEF SKIP_IPCHANGE}
		 ret := ERROR_SUCCESS;
		 {$ELSE}
        ret := SetIpConfig(Self.Ip, '', Self.Subnet);
         {$ENDIF}
        if (ret <> ERROR_SUCCESS) then begin
            raise Exception.CreateFmt('Erro ajustando o ip deste computador:'#13'%s', [TAPIHnd.SysErrorMessageEx(ret)]);
        end;
        ret := RenameComputer(AnsiString(Self.Computername), AnsiString(Self.FDescription));
        if (ret <> ERROR_SUCCESS) then begin
            raise Exception.CreateFmt('Erro ajustando o ip deste computador:'#13'%s', [TAPIHnd.SysErrorMessageEx(ret)]);
        end else begin
            //Alterar o nome da maquina primaria para este computador
            reg := TRegistryNT.Create;
            try
                //Apaga entrada, significa que este computador é o primário para ele mesmo
                //reg.WriteFullString(SIS_DELIVERY, Self.Computername, True);
                if reg.FullValueExists(SIS_DELIVERY) then begin
                    if not reg.DeleteFullValue(SIS_DELIVERY) then begin
						 raise Exception.Create('Erro de acesso ativando máquina como primária');
					 end;
                end;
            finally
                reg.Free;
            end;
        end;
    except
        on E : Exception do begin
            Applog.AppFatalError(E.Message, 1, True);
        end;
    end;
end;

end.
