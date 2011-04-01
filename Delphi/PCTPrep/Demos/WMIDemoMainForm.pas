unit WMIDemoMainForm;

interface

uses
    Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
    Dialogs, StdCtrls;

type
    TForm1 = class(TForm)
        btnUsers : TButton;
        lstUsers : TListBox;
        btnTest2 : TButton;
        procedure btnUsersClick(Sender : TObject);
        procedure btnTest2Click(Sender : TObject);
    private
        { Private declarations }
        procedure TesteWMI2;
    public
        { Public declarations }
    end;

var
    Form1 : TForm1;

implementation

{$R *.dfm}

uses
    WbemScripting_TLB, ActiveX, ComObj, UrlMon, ActiveDs_TLB, wmiUtils;

procedure TForm1.btnTest2Click(Sender : TObject);
var
	 Usr : IADsUser;
begin
    try
        //Usr := GetObject('WinNT://[computername]/ [acccoutname],user') as IADsUser;
        Usr := wmiUtils.WMIGetObject('WinNT://./vncacesso,user') as IADsUser;
		 //Usr.Put('UserFlags', Usr.Get('UserFlags') xor 65536);
		 //Usr.AccountDisabled:=True;
		 Usr.AccountExpirationDate:= Now() + 30;
        Usr.SetInfo;
    except
        on E : EOleException do begin
            ShowMessage(E.Message);
        end;
    end;
end;

procedure TForm1.btnUsersClick(Sender : TObject);
begin
    Self.TesteWMI2;
end;

procedure TForm1.TesteWMI2;
var
    strComputer : string;
    UserEntries : olevariant;
    oBindObj : IDispatch;
    UserIntf, oWMIService : olevariant;
    i, iValue : longword;
    oEnum :    IEnumvariant;
    oCtx :     IBindCtx;
    oMk :      IMoniker;
    sFileObj : WideString;

begin
    strComputer := '.'; //computador local = '.'
    sFileObj    := 'winmgmts:\\' + strComputer + '\root\cimv2';

    // Connect to WMI - Emulate API GetObject()
    OleCheck(CreateBindCtx(0, oCtx));
    OleCheck(MkParseDisplayNameEx(oCtx, PWideChar(sFileObj), i, oMk));
    OleCheck(oMk.BindToObject(oCtx, nil, IUnknown, oBindObj));
    oWMIService := oBindObj;

    //UserEntries := oWMIService.ExecQuery('Select * from Win32_NetworkLoginProfile');
    //UserEntries := oWMIService.ExecQuery('Select * from Win32_UserAccount where name = "TRE-PB\ROGER" ');
    //UserEntries := oWMIService.ExecQuery('Select * from Win32_UserAccount where name = "teste_roger"');
    UserEntries := oWMIService.ExecQuery('Select * from Win32_UserAccount where LocalAccount = True');


    oEnum := IUnknown(UserEntries._NewEnum) as IEnumVariant;

    while oEnum.Next(1, UserIntf, iValue) = 0 do begin
        Self.lstUsers.Items.Add(UserIntf.Name);
        if SameText(UserIntf.Name, 'vncacesso') then begin
            UserIntf.Disabled := True;
        end;
        UserIntf.SetInfo;
        {
        Wscript.Echo "AccountExpires: " & objItem.AccountExpires
        Wscript.Echo "AuthorizationFlags: " & objItem.AuthorizationFlags
        Wscript.Echo "BadPasswordCount: " & objItem.BadPasswordCount
        Wscript.Echo "Caption: " & objItem.Caption
        Wscript.Echo "CodePage: " & objItem.CodePage
        Wscript.Echo "Comment: " & objItem.Comment
        Wscript.Echo "CountryCode: " & objItem.CountryCode
        Wscript.Echo "Description: " & objItem.Description
        Wscript.Echo "Flags: " & objItem.Flags
        Wscript.Echo "FullName: " & objItem.FullName
        Wscript.Echo "HomeDirectory: " & objItem.HomeDirectory
        Wscript.Echo "HomeDirectoryDrive: " & objItem.HomeDirectoryDrive
        Wscript.Echo "LastLogoff: " & objItem.LastLogoff
        Wscript.Echo "LastLogon: " & objItem.LastLogon
        Wscript.Echo "LogonHours: " & objItem.LogonHours
        Wscript.Echo "LogonServer: " & objItem.LogonServer
        Wscript.Echo "MaximumStorage: " & objItem.MaximumStorage
        Wscript.Echo "Name: " & objItem.Name
        Wscript.Echo "NumberOfLogons: " & objItem.NumberOfLogons
        Wscript.Echo "Parameters: " & objItem.Parameters
        Wscript.Echo "PasswordAge: " & objItem.PasswordAge
        Wscript.Echo "PasswordExpires: " & objItem.PasswordExpires
        Wscript.Echo "PrimaryGroupId: " & objItem.PrimaryGroupId
        Wscript.Echo "Privileges: " & objItem.Privileges
        Wscript.Echo "Profile: " & objItem.Profile
        Wscript.Echo "ScriptPath: " & objItem.ScriptPath
        Wscript.Echo "SettingID: " & objItem.SettingID
        Wscript.Echo "UnitsPerWeek: " & objItem.UnitsPerWeek
        Wscript.Echo "UserComment: " & objItem.UserComment
        Wscript.Echo "UserId: " & objItem.UserId
        Wscript.Echo "UserType: " & objItem.UserType
        Wscript.Echo "Workstations: " & objItem.Workstations
         }
    end;
end;

end.
