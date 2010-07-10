{$IFDEF mtUtils}
{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}
unit mtUtils;

interface

uses
    SysUtils, Windows, Classes, WinReg32, JclWin32, LmAccess, Generics.Collections;

type
    TZEUser = class
    private
        FUserName : string;
        FPassword : string;
        FChecked :  boolean;
    public
        constructor Create(const AName, APassword : string); virtual;
        property UserName : string read FUserName;
        property Password : string read FPassword write FPassword;
        property Checked : boolean read FChecked write FChecked;
        /// <summary>
        /// Troca a senha da conta deste usuário de zona no computador local
        /// </summary>
        /// <param name="NewPass">Nova senha a ser atribuida</param>
        /// <returns>Código de erro da operação</returns>
        function SetLocalPassword() : NET_API_STATUS;
    end;

    TZEUserList = class
    private
        FUsers : TObjectList<TZEUser>;
        function GetCount : Integer;
        function GetItems(index : Integer) : TZEUser;
        function GetIsDomain : boolean;
        function GetStationDomain(const CurUser : string) : string;
    public
        constructor Create;
        destructor Destroy; override;
        property Count : Integer read GetCount;
        property Items[index : Integer] : TZEUser read GetItems;
        property isDomain : boolean read GetIsDomain;
        function SetLocalPasswords() : string;
        function SetDomainPasswords() : string;
    end;

implementation

uses
    APIHnd, WinNetHnd, StrHnd;


procedure StrResetLength(var S : string);
var
    I : Integer;
begin
    for I := 0 to Length(S) - 1 do begin
        if S[I + 1] = #0 then    begin
            SetLength(S, I);
            Exit;
        end;
    end;
end;

constructor TZEUser.Create(const AName, APassword : string);
begin
    Self.FUserName := AName;
    Self.FPassword := APassword;
end;

function TZEUser.SetLocalPassword() : NET_API_STATUS;
var
    userInfo : TUserInfo1003;
    PError :   DWORD;
begin
    userInfo.usri1003_password := PWideChar(Self.FPassword);
    Result := NetUserSetInfo(nil, PWideChar(Self.FUserName), 1003, @userInfo, @PError);
end;

{ TZEUserList }

constructor TZEUserList.Create;
begin
    inherited;
    Self.FUsers := TObjectList<TZEUser>.Create();
    Self.FUsers.OwnsObjects := True;
	  //Adiciona a lista de usuários conhecida
		{$IFDEF DEBUG}
		Self.FUsers.Add( TZEUser.Create('ghost', 'esmeralda' ) );
		{$ELSE}
		Self.FUsers.Add(TZEUser.Create('suporte', 'administr%d%'));
		Self.FUsers.Add(TZEUser.Create('vncacesso', 'administr%d%'));
		Self.FUsers.Add(TZEUser.Create('instalador', 'sinst%l%'));
		Self.FUsers.Add(TZEUser.Create('desinstalador', 'desinst%l%'));
		Self.FUsers.Add(TZEUser.Create('supervisor', 'autoriz%d%'));
		Self.FUsers.Add(TZEUser.Create('oficial', 'assin%d%'));
    Self.FUsers.Add(TZEUser.Create('000000010191', 'utiliz%d%'));
    {$ENDIF}
end;

destructor TZEUserList.Destroy;
begin
	Self.FUsers.Free;
	inherited;
end;

function TZEUserList.GetCount : Integer;
begin
    Result := Self.FUsers.Count;
end;

 /// <summary>
 /// Determina se a estação pertence a um domínio
 /// </summary>
 /// <returns>Condição da estação</returns>
function TZEUserList.GetIsDomain : boolean;
var
    cName : string;
begin
    cName  := UpperCase(GetComputerName());
    Result := Self.GetStationDomain('PB025391') <> EmptyStr;
    Result := TStrHnd.Contains('WKS', cName) or TStrHnd.Contains('PDC', cName);
end;

function TZEUserList.GetItems(index : Integer) : TZEUser;
begin
    Result := Self.FUsers.Items[index];
end;

function TZEUserList.GetStationDomain(const CurUser : string) : string;
var
    Count1, Count2 : DWORD;
    Sd :  PSID; // PSecurityDescriptor; // FPC requires PSID
    Snu : SID_Name_Use;
begin
    Count1 := 0;
    Count2 := 0;
    Sd     := nil;
    Snu    := SIDTypeUser;
    Result := '';
    LookUpAccountName(nil, PChar(CurUser), Sd, Count1, PChar(Result), Count2, Snu);
    // set buffer size to Count2 + 2 characters for safety
    SetLength(Result, Count2 + 1);
    Sd := AllocMem(Count1);
    try
        if LookUpAccountName(nil, PChar(CurUser), Sd, Count1, PChar(Result), Count2, Snu) then    begin
            StrResetLength(Result);
        end else begin
            Result := EmptyStr;
        end;
    finally
        FreeMem(Sd);
    end;
end;

function TZEUserList.SetDomainPasswords : string;
begin

end;

function TZEUserList.SetLocalPasswords : string;
var
    User : TZEUser;
    ret :  NET_API_STATUS;
    x :    Integer;
    log :  string;
begin
    log := EmptyStr;
    for x := 0 to Self.FUsers.Count - 1 do begin
        User := Self.FUsers.Items[x];
        if User.Checked then begin
            try
                try
                    ret := User.SetLocalPassword();
                    TAPIHnd.CheckAPI(ret);
                finally
                    User.Free;
                end;
            except
                on E : Exception do begin
                    log := log + #13 + E.Message;
                end;
            end;
        end;
    end;
    if log <> EmptyStr then begin
        {TODO -oroger -cdsg : repassar para a camada GUI}
    end;
end;

end.
