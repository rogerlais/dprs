echo %ERRORLEVEL%
rem cmd /c filho.bat && set errorlevel=%errorlevel%
cmd /c filho.bat
echo %ERRORLEVEL%
IF ERRORLEVEL 5 ECHO An error occurred!
