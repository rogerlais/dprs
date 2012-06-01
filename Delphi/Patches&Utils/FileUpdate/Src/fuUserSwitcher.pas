{$IFDEF fuUserSwitcher}
          {$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I FileUpdate.inc}

unit fuUserSwitcher;

interface

uses
	 Windows, SysUtils, AppLog, WinNetHnd, Contnrs;

type
	TUserData = class
	private
		FHandle : THandle;
	public
	 	constructor Create( const AUsername, Pwd : string );
	end;

	 TFUUserSwitcher = class
	 private
		FPrimaryUsername : string;
		FLocalStack : TStack;
		FUserList : TObjectList;
	 public
		 constructor Create(const APrimaryUsername : string );
		 destructor Destroy; override;
		 procedure GetNetAccess;
		 procedure ReleaseNetAcess;
		 procedure PushUser( const Username : string );
		 procedure PopUser();
		 procedure AddUserCrendentials( const AUsername, Pwd : string );
	 end;

implementation

uses
  WinHnd, APIHnd;

{ TFUUserSwitcher }

procedure TFUUserSwitcher.AddUserCrendentials(const AUsername, Pwd: string);
var
	ud : TUserData;
begin
	ud:=TUserData.Create( AUsername, Pwd );

end;

constructor TFUUserSwitcher.Create( const APrimaryUsername : string );
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

procedure TFUUserSwitcher.GetNetAccess();
begin
	 if (Self.FUserToken <> 0) then begin
		 if not ImpersonateLoggedOnUser(Self.FUserToken) then begin
			 raise Exception.Create('Acesso a rede falhou' + SysErrorMessage(GetLastError()));
		 end else begin
			 Inc(Self.FNetAccessCount);
		 end;
	 end else begin
		 raise Exception.Create('Conta de acesso a rede indefinida.');
	 end;
end;

procedure TFUUserSwitcher.PopUser;
begin

end;

procedure TFUUserSwitcher.PushUser(const Username: string);
begin

end;

procedure TFUUserSwitcher.ReleaseNetAcess;
begin
	 Dec(Self.FNetAccessCount);
    if (Self.FNetAccessCount <= 0) then begin
        RevertToSelf();
    end;
end;


{ TUserData }

constructor TUserData.Create(const AUsername, APwd: string);
var
	 User, Pass : PChar;
begin
	 User   := PChar(AUserName);
	 Pass   := PChar(APwd);
	 if not LogonUser(User, nil, Pass, LOGON32_LOGON_INTERACTIVE, LOGON32_PROVIDER_DEFAULT, Self.FNetToken) then begin
		 TAPIHnd.CheckAPI( GetLastError() );
	 end;
end;

end.
