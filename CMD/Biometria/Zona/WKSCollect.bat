REM Versão 1.0 - 20100414 - Autor: Roger
cd /d D:\Comum\BioTransf
if %errorlevel% neq 0 goto error

REM Alterar o nome da maquina para refletir a zona
move /y *.* \\ZPBzzzSTDnn\transbio\files\bio
goto fim

:error
REM tratamento do erro 

:fim
exit
