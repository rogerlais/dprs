{$IFDEF fuUserSwitcher}
          {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuUserSwitcher;

interface

uses
    Windows, SysUtils, AppLog, WinNetHnd, Contnrs;

const
    APP_NET_USER = 'download@tre-pb.gov.br';
    APP_NET_PWD  = 'pinico123';

type
    TUserData = class
    private
        FUserToken : THandle;
        FUsername :  string;
        FPassword :  string;
    public
        property Username : string read FUsername write FUsername;
        property Password : string read FPassword write FPassword;
        constructor Create(const AUsername, APwd : string);
        destructor Destroy; override;
    end;

    TFUUserSwitcher = class
    private
        FPrimaryUsername : string;
        FLocalStack :      TStack;
        FUserList :        TObjectList;
        function GetUserData(const UserName : string) : TUserData;
    public
        constructor Create(const APrimaryUsername : string);
        destructor Destroy; override;
        procedure SwitchTo(const UserName : string);
        procedure RevertToPrevious;
        procedure AddUserCrendentials(const AUsername, Pwd : string);
    end;


var
    GlobalSwitcher : TFUUserSwitcher;

implementation

uses
    WinHnd, APIHnd;

{ TFUUserSwitcher }

procedure TFUUserSwitcher.AddUserCrendentials(const AUsername, Pwd : string);
var
    ud : TUserData;
begin
    ud := TUserData.Create(AUsername, Pwd);
    Self.FUserList.Add(ud);
end;

constructor TFUUserSwitcher.Create(const APrimaryUsername : string);
begin
    Self.FPrimaryUsername := APrimaryUsername;
    Self.FLocalStack := TStack.Create;
    Self.FUserList := TObjectList.Create;
end;

destructor TFUUserSwitcher.Destroy;
begin
    {TODO -oroger -cdsg : Voltar para a conta primaria}
    Self.FUserList.Clear;
    Self.FUserList.Free;
    Self.FLocalStack.Free;
    inherited;
end;

function TFUUserSwitcher.GetUserData(const UserName : string) : TUserData;
var
    x :  Integer;
    ud : TUserData;
begin
    Result := nil;
    for x := 0 to Self.FUserList.Count - 1 do begin
        ud := TUserData(Self.FUserList.Items[x]);
        if (SameStr(UserName, ud.FUsername)) then begin
            Result := ud;
            Exit;
        end;
    end;
end;

procedure TFUUserSwitcher.SwitchTo(const UserName : string);
var
    ud : TUserData;
begin
    ud := Self.GetUserData(UserName);
    if (Assigned(ud)) then begin
        if (ud.FUserToken <> 0) then begin
            if ImpersonateLoggedOnUser(ud.FUserToken) then begin
                {TODO -oroger -cdsg : Incrementar a pilha}
                Self.FLocalStack.Push(ud);
            end else begin
                raise Exception.Create('Acesso a rede falhou' + SysErrorMessage(GetLastError()));
            end;
        end else begin
            raise Exception.Create('Conta de acesso a rede indefinida.');
        end;
    end else begin
        raise Exception.CreateFmt('Conta de usuário: %s não registrada para acesso no momento.', [Username]);
    end;
end;


procedure TFUUserSwitcher.RevertToPrevious();
var
    curUser, prevUser : TUserData;
begin
    if (Self.FLocalStack.Count > 1) then begin
        curUser  := Self.FLocalStack.Pop();
        prevUser := Self.FLocalStack.Peek();
        if (not SameText(curUser.Username, prevUser.username)) then begin
            {TODO -oroger -cdsg : alterar o usuário sem incrementar a lista}
            if not ImpersonateLoggedOnUser(prevUser.FUserToken) then begin
                raise Exception.CreateFmt('Falha voltando as crendencias anteriores de %s para %s.'#13'%s',
                    [curUser.Username, prevUser.Username, SysErrorMessage(GetLastError())]);
            end;
        end;
    end else begin
        if (Self.FLocalStack.Count > 0) then begin
            Self.FLocalStack.Pop(); //descarta unico elemento e libera ao criador
        end;
        if not (RevertToSelf()) then begin  //retornar ao criador original
            TAPIHnd.CheckAPI(GetLastError());
        end;
    end;
end;

{ TUserData }

constructor TUserData.Create(const AUsername, APwd : string);
var
    User, Pass : PChar;
begin
    Self.FUsername := AUsername;
    Self.FPassword := APwd;
    User := PChar(AUserName);
    Pass := PChar(APwd);
    if not LogonUser(User, nil, Pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, Self.FUserToken) then begin
        TAPIHnd.CheckAPI(GetLastError());
    end;
end;

destructor TUserData.Destroy;
begin
    {TODO -oroger -cdsg : liberar o token do usuário}
    inherited;
end;

end.
