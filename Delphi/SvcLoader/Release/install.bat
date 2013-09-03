cls
@echo off

rem *****
echo on


REM Area de definicoes
set source=D:\Comum\InstSeg\SvcLoader.*
set sesop_home=D:\AplicTRE\Suporte
set dest=%sesop_home%\Scripts
set svcname=BioFilesService
set svcdisplay=SESOP TransBio Replicator

rem parar servico
net stop %svcname%
rem desinstalar anterior
%dest%\SvcLoader.exe /uninstall /silent
rem copia do local temp para destino(arquivo antes poderia estar aberto)
move /y %source% %dest%
if not errorlevel 0 goto copy_error

:install
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
echo: Instalacao finalizada
