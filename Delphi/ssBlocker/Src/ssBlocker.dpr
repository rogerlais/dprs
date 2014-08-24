program ssBlocker;


// For reference purposes



uses
    Windows,
    SysUtils,
    Forms,
    Dialogs,
    FileHnd,
    WinReg32,
    Settings in 'Settings.pas' {FormSettings},
    Main in 'Main.pas' {FormMain};

// Compiled output has the .scr extension instead of .exe
{$E .scr}

var
    Option : string;


{$R *.res}
    // In addition to the standard stuff, .res holds the value that will show up in
    // the Display Settings Screen Saver tab.
    // Set value for ID 1 in the StringTable of Description.res
    // (You may need to find a Resource Editor if you don't already have one.)
    // The value can be a maximum of 25 characters.
    // In order for this to work properly, the project name should be  eight or less
    // characters and all lowercase.

    procedure ShowSettings;
    begin
        Application.CreateForm(TFormSettings, FormSettings);
    end;

    procedure ShowPreview;
    begin
        // This doesn't refer to the Preview button that is seen in the
        // Display Settings Screen Saver tab. Instead, it refers to the
        // Monitor image shown in the Display Settings Screen Saver tab.
    end;


    procedure ShowScreenSaver;
    var
        I : Integer;
    begin
        for I := 0 to Screen.MonitorCount - 1 do begin
            Application.CreateForm(TFormMain, FormMain);
            FormMain.Left := Screen.Monitors[I].Left;
            FormMain.WindowState := wsMaximized;
        end;
    end;

    procedure ShowInstall;
    var
        SrcFile, DestFile : string;
        reg : TRegistryNT;
    begin
        if MessageBoxW(0,
            'Deseja instalar esta proteção de tela com os parâmetros padrão?',
            PWideChar(Application.Title), MB_YESNO + MB_ICONQUESTION + MB_TOPMOST) = idYes then begin
            srcFile  := ParamStr(0);
            DestFile := TFileHnd.ConcatPath([EvalPathName('%WINDIR%'), 'System32', ExtractFileName(srcFile)]);
            //Sempre tenta sobreescrever para atualizar se for o caso
			 if (
				( not SameText( SrcFile, DestFile )) and
				(not CopyFile(PWideChar(srcFile), PWideChar(DestFile), False))
			 ) then begin
                MessageBoxW(0,
                    PWideChar(Format('Erro copiando arquivo para "%s", %s', [DestFile, SysErrorMessage(GetLastError())])),
                    PWideChar(Application.Title), MB_OK + MB_ICONSTOP + MB_TOPMOST);
                Exit;
            end;
            reg := TRegistryNT.Create;
            try
				 reg.WriteFullString('HKEY_CURRENT_USER\Control Panel\Desktop\SCRNSAVE.EXE', FileShortName(DestFile), True);
				 reg.WriteFullString('HKEY_CURRENT_USER\Control Panel\Desktop\ScreenSaveTimeOut', '300', True);
				 reg.WriteFullString('HKEY_CURRENT_USER\Control Panel\Desktop\ScreenSaveActive', '1', True);
            finally
                reg.Free;
			 end;
			 MessageBoxW(0, 'Proteção de tela instalada com sucesso!', PWideChar(Application.Title), MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
        end;
    end;

begin

    // Using the CreateMutex() to insure that the main body of the application
    // only executes if this is the only instance of the application.

    // This application going to rely on the OS to clean up the mutex.
    // Snippet for Windows SDK help:
    //   Use the CloseHandle function to close the handle. The system closes the
    //   handle automatically when the process terminates. The mutex object is
    //   destroyed when its last handle has been closed.
    Windows.CreateMutex(nil, True, 'scrnsave');
    if (Windows.GetLastError <> Windows.ERROR_ALREADY_EXISTS) then begin
        Application.Initialize;
        if ParamCount > 0 then begin

            // only check the first two characters, in case windows decides to add
            // extra stuff
            Option := LowerCase(Copy(ParamStr(1), 1, 2));
            if Option = '/c' then begin
                ShowSettings;
            end else
            if Option = '/p' then begin
                ShowPreview;
            end else
            if Option = '/i' then begin
                ShowInstall;
            end else
            if Option = '/s' then begin
                ShowScreenSaver;
            end else begin
                ShowMessage('ParamStr(1)=' + ParamStr(1));
            end;
            // ShowSettings;
        end else begin
            ShowSettings;
        end;

        Application.Run;
    end;
end.
