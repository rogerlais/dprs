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
        function SetPassword(const ADomain : string) : NET_API_STATUS;
    end;

    TZEUserList = class
    private
        _FDomain : string;
        FUsers :   TObjectList<TZEUser>;
        function GetCount : Integer;
        function GetItems(index : Integer) : TZEUser;
        function GetIsDomain : boolean;
        function LookupStationDomain(const CurUser : string) : string;
        function GetDomain : string;
    public
        constructor Create;
				destructor Destroy; override;
				property Domain : string read GetDomain;
				property Count : Integer read GetCount;
				property Items[index : Integer] : TZEUser read GetItems;
				property isDomain : boolean read GetIsDomain;
				function Add(NewUser : TZEUser) : Integer;
				function SetPasswords() : string;
				//function SetDomainPasswords() : string;
    end;

implementation

uses
    APIHnd, WinNetHnd, StrHnd;

const
{$IFDEF DEBUG}
	HOOK_USER_ACCOUNT = 'roger'; //Conta usada para recuperar o dominio da máquina
{$ELSE}
    HOOK_USER_ACCOUNT = '000000010191'; //Conta usada para recuperar o dominio da máquina
{$ENDIF}


procedure StrResetLength(var S : string);
var
    I : Integer;
begin
    for I := 0 to Length(S) - 1 do begin
        if S[I + 1] = #0 then begin
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

function TZEUser.SetPassword(const ADomain : string) : NET_API_STATUS;
var
    userInfo :   TUserInfo1003;
    PError :     DWORD;
    PDomain, PUsername : PWideChar;
    tokenIndex : Integer;
begin
    tokenIndex := Pos('\', Self.FUserName);
		if tokenIndex <> 0 then begin //conta de dominio
				PDomain   := StrNew(PWideChar(Copy(Self.UserName, 1, tokenIndex)));
				PUsername := StrNew(PWideChar(Copy(Self.FUserName, tokenIndex+1, Length(Self.UserName))));
		end else begin
				PDomain   := nil;
				PUsername := StrNew(PWideChar(Self.FUserName));
    end;
    userInfo.usri1003_password := StrNew(PWideChar(Self.FPassword));
    try
        Result := NetUserSetInfo(PDomain, PUserName, 1003, @userInfo, @PError);
    finally
        StrDispose(PUsername);
        StrDispose(PDomain);
        StrDispose(userInfo.usri1003_password);
    end;
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

function TZEUserList.Add(NewUser : TZEUser) : Integer;
begin
    Result := Self.FUsers.Add(NewUser);
end;

constructor TZEUserList.Create;
var
    x : Integer;
begin
    inherited;
		Self.FUsers := TObjectList<TZEUser>.Create();
		Self.FUsers.OwnsObjects := True;
		//Adiciona a lista de usuários conhecida
		{$IFDEF DEBUG}
		Self.FUsers.Add( TZEUser.Create('ghost', 'esmeralda' ) );
		{$ELSE}
		Self.FUsers.Add(TZEUser.Create('suporte', 'admin<1>str<2>d<3>'));
		Self.FUsers.Add(TZEUser.Create('vncacesso', 'admin<1>str<2>d<3>'));
		Self.FUsers.Add(TZEUser.Create('instalador', 's<1>nst<2>l<3>'));
		Self.FUsers.Add(TZEUser.Create('desinstalador', 'des<1>nst<2>l<3>'));
		Self.FUsers.Add(TZEUser.Create('supervisor', 'autor<1>z<2>d<3>'));
		Self.FUsers.Add(TZEUser.Create('oficial', 'ass<1>n<2>d<3>'));
		Self.FUsers.Add(TZEUser.Create('000000010191', 'util<1>z<2>d<3>'));
		{$ENDIF}

		{TODO -oroger -curgente : duplicar contas de usuários para o caso de haver domínio}

		//habilita todos os usuarios
    for x := 0 to Self.FUsers.Count - 1 do begin
        Self.Items[x].Checked := True;
    end;
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

function TZEUserList.GetDomain : string;
begin
    if Self._FDomain = EmptyStr then begin
        Self._FDomain := Self.LookupStationDomain(HOOK_USER_ACCOUNT);
    end;
    Result := Self._FDomain;
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
    {TODO -oroger -cfuture : Melhorar forma de recuperar dominio sem as gambiarras}
    //Usa-se conta pertinente exclusivamente ao dominio(não podemos ter outra de mesmo nome na máquina) para pegar o dominio vinculado
    Result := UpperCase(Self.Domain) <> cName;
    Result := Result or TStrHnd.Contains('WKS', cName) or TStrHnd.Contains('PDC', cName);
end;

function TZEUserList.GetItems(index : Integer) : TZEUser;
begin
    Result := Self.FUsers.Items[index];
end;

function TZEUserList.LookupStationDomain(const CurUser : string) : string;
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
        if LookUpAccountName(nil, PChar(CurUser), Sd, Count1, PChar(Result), Count2, Snu) then begin
            StrResetLength(Result);
        end else begin
            Result := EmptyStr;
        end;
    finally
        FreeMem(Sd);
    end;
end;

{
function TZEUserList.SetDomainPasswords : string;
var
    User : TZEUser;
    ret :  NET_API_STATUS;
    x :    Integer;
begin
    Result := EmptyStr;
    for x := 0 to Self.FUsers.Count - 1 do begin
        User := Self.FUsers.Items[x];
        if User.Checked then begin
            try
                try
                    ret := User.SetPassword(Self.Domain);
                    TAPIHnd.CheckAPI(ret);
                finally
                    User.Free;
                end;
            except
                on E : Exception do begin
                    Result := Result + #13 + E.Message;
                end;
            end;
        end;
    end;
end;

}

function TZEUserList.SetPasswords : string;
var
		User : TZEUser;
		ret :  NET_API_STATUS;
		x :    Integer;
begin
		Result := EmptyStr;
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
                    Result := Result + #13 + E.Message;
                end;
            end;
        end;
    end;
end;

initialization
    begin
        {TODO -oroger -cdsg : Inicializar COM de modo a evitar GPF finais}
    end;

finalization
    begin
        {TODO -oroger -cdsg : finalizar COM de modo a evitar GPF finais}
    end;

end.
