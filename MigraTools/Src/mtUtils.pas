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
  public
    constructor Create(const AName: string); virtual;
    property UserName: string read FUserName;
    /// <summary>
    /// Troca a senha da conta deste usuário de zona no computador local
    /// </summary>
    /// <param name="NewPass">Nova senha a ser atribuida</param>
    /// <returns>Código de erro da operação</returns>
    function SetLocalPassword(const NewPass: string): NET_API_STATUS;
  end;

implementation

constructor TZEUser.Create(const AName: string);
begin
  Self.FUserName := AName;
end;

function TZEUser.SetLocalPassword(const NewPass: string): NET_API_STATUS;
var
  userInfo: TUserInfo1003;
  PError: DWORD;
begin
  userInfo.usri1003_password := PWideChar(NewPass);
  Result := NetUserSetInfo(nil, PWideChar(Self.FUserName), 1003, @userInfo, @PError);
end;

end.
