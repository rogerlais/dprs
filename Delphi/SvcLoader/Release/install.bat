cls
@echo off

rem *****
echo on


REM Area de definicoes
set source=D:\Comum\InstSeg\SvcLoader.exe
set sesop_home=D:\AplicTRE\Suporte
set dest=%sesop_home%\Scripts

REM Area de operacoes
net start | find "BioFilesService"
if errorlevel 0 goto install
REM para e desinstala
net stop BioFilesService
%dest%\SvcLoader.exe /uninstall /silent

:install
move %source% %dest% /y
if not errorlevel 0 goto copy_error

%dest%\SvcLoader.exe /install /silent
if not errorlevel 0 goto service_error
goto final

REM Areas de Erros
:service_error
@echo on
echo "Falha iniciando o servico"
pause 6
goto final

:copy_error
@echo on
echo "Falha copiando runtime do servico"
pause 7
goto final


:final
