unit vvsFileMonitor;

interface

uses
	 SysUtils, Classes,
	 JwaWindows,
	 JwsclToken,
	 JwsclUtils,
    JwsclTypes,
    XPThreads;

type
    TFileMonitorThread = class(TXPNamedThread)
	 private
		 _dwBufLen :     DWORD;
		 _dwRead :       DWORD;
		 _pWork :        Pointer;
		 _sFileName :    WideString;
		 _dwWaitStatus : DWORD;
		 _hNotifity,
		 _FhFile :       HANDLE;
		 FParentThread : TXPBaseThread;
		 FLastModification : TDateTime;
		 FPath :         string;
		 FRecursive :    boolean;
		 _Token :        TJwSecurityToken;
		 FModifiedFilename: string;
    FOnChange: TNotifyEvent;
		 procedure SetPath(const Value : string);
		 procedure SetRecursive(const Value : boolean);
	 public
		 property ParentThread : TXPBaseThread read FParentThread write FParentThread;
		 property LastModification : TDateTime read FLastModification;
		 property ModifiedFilename : string read FModifiedFilename;
		 property OnChange : TNotifyEvent read FOnChange write FOnChange;
		 property Path : string read FPath write SetPath;
		 property Recursive : boolean read FRecursive write SetRecursive;
		 procedure Execute; override;
	 end;

implementation



{ TFileMonitorThread }

procedure TFileMonitorThread.Execute;
var
	_pBuf :         Pointer;
	_FNI :          PFILE_NOTIFY_INFORMATION absolute _pBuf;
begin
	 inherited;
	 begin
			if ( not JwEnablePrivilege(SE_CHANGE_NOTIFY_NAME, pst_Disable) ) then begin
				raise Exception.Create('Privilégio não pode ser ajustado: ' + SysErrorMessage( GetLastError() ) );
			end;
        _FhFile := CreateFile(PChar(Self.FPath),
            FILE_LIST_DIRECTORY or GENERIC_READ,
            FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE, nil,
            OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);

        _hNotifity := FindFirstChangeNotification(PChar(Self.FPath),                    //Verzeichnis
            cardinal(False),                               //unterverzeichnisse überwachen
            FILE_NOTIFY_CHANGE_FILE_NAME or
            FILE_NOTIFY_CHANGE_LAST_WRITE or
            FILE_NOTIFY_CHANGE_SIZE or
            FILE_ACTION_ADDED or
            FILE_ACTION_REMOVED or
			 FILE_ACTION_MODIFIED);
		 if (_FhFile = INVALID_HANDLE_VALUE) or (_FhFile = 0) then begin
			 RaiseLastWin32Error;
		 end;
		 if (_hNotifity = INVALID_HANDLE_VALUE) then begin
			 RaiseLastWin32Error;
		 end;

		 _dwBufLen := 65536;
		 _pBuf     := AllocMem(_dwBufLen);
		 try
			 while ((FindNextChangeNotification(_hNotifity))) do begin
				 _dwWaitStatus := WaitForSingleObject(_hNotifity, INFINITE);
				 if (_dwWaitStatus = WAIT_FAILED) then begin
					 RaiseLastWin32Error;
				 end;
				 //if (dwWaitStatus = WAIT_OBJECT_0) then
				 begin
					 ReadDirectoryChangesW(_FhFile, _pBuf, _dwBufLen, True,
						 FILE_NOTIFY_CHANGE_FILE_NAME or
						 FILE_NOTIFY_CHANGE_DIR_NAME or
						 FILE_NOTIFY_CHANGE_ATTRIBUTES or
						 FILE_NOTIFY_CHANGE_SIZE or
						 FILE_NOTIFY_CHANGE_LAST_WRITE or
						 FILE_NOTIFY_CHANGE_CREATION or
						 FILE_ACTION_ADDED or
						 FILE_ACTION_REMOVED or
						 FILE_ACTION_MODIFIED,
						 @_dwRead, nil, nil);
					 _pWork := _pBuf;
					 repeat
						Self.FModifiedFilename :=WideCharToString(_FNI.FileName);
						if ( Assigned( Self.FOnChange ) ) then begin
							Self.FOnChange( Self );
						end;
						 //writeln(_FNI.Action, ' : ', string(WideCharToString(_FNI.FileName)));
						 Inc(Integer(_pBuf), _FNI.NextEntryOffset);
                    until _FNI.NextEntryOffset = 0;
                end;
            end;
        finally
            FreeMem(_pBuf, _dwBufLen);
        end;
    end;
end;

procedure TFileMonitorThread.SetPath(const Value : string);
begin
    {TODO -oroger -cdsg : Caso em monitoração deve-se recomeçar}
    FPath := Value;
end;

procedure TFileMonitorThread.SetRecursive(const Value : boolean);
begin
    {TODO -oroger -cdsg : Caso em monitoração deve-se recomeçar}
    FRecursive := Value;
end;

end.
