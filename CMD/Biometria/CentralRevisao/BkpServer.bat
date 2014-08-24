Versão 1.2
@echo off
REM Montagem de string no formato aaaammdd
set data=%date%
set dia=%data:~4,2%
set mes=%data:~7,2%
set ano=%data:~10,4%
set pasta=D:\Comum\BioBackup\%ano%%mes%%dia%

REM IMPORTANTE:
REM Devido as permissoes restrigirem listar, cada pasta DEVE ser tratada separadamente
REM Criacao da pasta com nome da string
mkdir %pasta%
mkdir %pasta%\Bio
mkdir %pasta%\Trans
mkdir %pasta%\Retrans
mkdir %pasta%\Erro


REM Copia de todos os arquivos(cada pasta separadamente)
xcopy D:\Aplic\TransBio\Files\Erro\*.* %pasta%\Erro\*.* /c /e /R /Y >NULL
xcopy D:\Aplic\TransBio\Files\Retrans\*.* %pasta%\Retrans\*.* /c /e /R /Y >NULL
xcopy D:\Aplic\TransBio\Files\Bio\*.* %pasta%\Bio\*.* /c /e /R /Y >NULL
xcopy D:\Aplic\TransBio\Files\Trans\*.* %pasta%\Trans\*.* /c /e /R /Y >NULL

REM Compara todos os arquivos copiados da pasta Trans
comp  D:\Aplic\TransBio\Files\Trans\*.* %pasta%\Trans\*.* <n.txt >NULL

REM Verifica se houve erro na copia
REM comparacao

IF %ERRORLEVEL% EQU 0 GOTO APAGA

Echo Verifique a copia dos arquivos, pois foi identificada diferenca entre os arquivos copiados!!!!!
Echo Pode ter havido uma execucao anterior no dia de hoje???
pause > null
GOTO FIM

:APAGA
Del D:\Aplic\TransBio\Files\Trans\*.* /F /Q
cls
echo.
Echo Backup finalizado com SUCESSO!!!!
echo.
echo Pressione qualquer tecla para finalizar...
pause >NULL

:FIM
echo.
