unit kcDemo1Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, CheckLst, Buttons;

type
  TForm1 = class(TForm)
    btnReadUsers: TBitBtn;
    chklstLoggedUsers: TCheckListBox;
    procedure btnReadUsersClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation


uses
   JediWinAPI;


{$R *.dfm}

procedure GetActiveUserNames(var slUserList : TStringList);
var
   Count: cardinal;
   List: PLUID;
   sessionData: PSECURITY_LOGON_SESSION_DATA;
   i1: integer;
   SizeNeeded, SizeNeeded2: DWORD;
   OwnerName, DomainName: PChar;
   OwnerType: SID_NAME_USE;
   pBuffer: Pointer;
   pBytesreturned: DWord;
   sUser : string;
begin
   //result:= '';
   //Listing LogOnSessions
   i1:= lsaNtStatusToWinError(LsaEnumerateLogonSessions(@Count, @List));
   try
      if i1 = 0 then
      begin
          i1:= -1;
          if Count > 0 then
          begin
              repeat
                inc(i1);
                LsaGetLogonSessionData(List, sessionData);
                //Checks if it is an interactive session
                sUser := sessionData.UserName.Buffer;
                if (sessionData.LogonType = Interactive)
                  or (sessionData.LogonType = RemoteInteractive)
                  or (sessionData.LogonType = CachedInteractive)
                  or (sessionData.LogonType = CachedRemoteInteractive) then
                begin
                    //
                    SizeNeeded := MAX_PATH;
                    SizeNeeded2:= MAX_PATH;
                    GetMem(OwnerName, MAX_PATH);
                    GetMem(DomainName, MAX_PATH);
                    try
                    if LookupAccountSID(nil, sessionData.SID, OwnerName,
                                       SizeNeeded, DomainName,SizeNeeded2,
                                       OwnerType) then
                    begin
                      if OwnerType = 1 then  //This is a USER account SID (SidTypeUser=1)
                      begin
                        sUser := AnsiUpperCase(sessionData.LogonDomain.Buffer);
                        sUser := sUser + '\';
                        sUser := sUser + AnsiUpperCase(sessionData.UserName.Buffer);
                        slUserList.Add(sUser);
//                          if sessionData.Session = WTSGetActiveConsoleSessionId then
//                          begin
//                            //Wenn Benutzer aktiv
//                            try
//                                if WTSQuerySessionInformationA
//                                   (WTS_CURRENT_SERVER_HANDLE,
//                                    sessionData.Session, WTSConnectState,
//                                    pBuffer,
//                                    pBytesreturned) then
//                                begin
//                                    if WTS_CONNECTSTATE_CLASS(pBuffer^) = WTSActive then
//                                    begin
//                                      //result:= sessionData.UserName.Buffer;
//                                      slUserList.Add(sessionData.UserName.Buffer);
//                                    end;
//                                end;
//                            finally
//                              LSAFreeReturnBuffer(pBuffer);
//                            end;
                          //end;
                      end;
                    end;
                    finally
                    FreeMem(OwnerName);
                    FreeMem(DomainName);
                    end;
                end;
                inc(List);
                try
                    LSAFreeReturnBuffer(sessionData);
                except
                end;
            until (i1 = Count-1);// or (result <> '');
          end;
      end;
   finally
      LSAFreeReturnBuffer(List);
   end;
end;

procedure TForm1.btnReadUsersClick(Sender: TObject);
var
  slUsers : TStringList;
begin
  slUsers := TStringList.Create;
  slUsers.Duplicates := dupIgnore;
  slUsers.Sorted := True;
  try
    GetActiveUserNames(slUsers);
    Memo1.Lines.AddStrings(slUsers);
  finally
    FreeAndNil(slUsers)
  end;
end;

end.
