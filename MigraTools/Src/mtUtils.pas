{$IFDEF mtUtils}
		{$DEFINE DEBUG_UNIT}
{$ENDIF}
{$I MigraTools.inc}

unit mtUtils;

interface

uses
	SysUtils, Windows, Classes, WinReg32, JclWin32, LmAccess;


type
	TZEUser = class
  private
    FUserName: string;
  published

	public
		constructor Create( const AName : string ); virtual;
		property UserName:  string read FUserName;
		function SetPassword( const NewPass : string ) : NET_API_STATUS;
	end;
implementation

constructor TZEUser.Create(const AName: string);
begin
	Self.FUserName := AName;
end;

function TZEUser.SetPassword(const NewPass: string): NET_API_STATUS;
var
	userInfo : TUserInfo1003;
	PError : DWORD;
begin
	userInfo.usri1003_password := PWideChar(NewPass);
	Result := NetUserSetInfo(nil, Self.FUserName, 1003 , @userInfo, @PError);
end;

end.
