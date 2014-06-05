echo "USRINIT - 1.0.2014(PDC,STD,WKS,CAE)"
REM DEBUG remover abaixo
@echo on


goto scr

REM ****************** Mapeamento da unidade de rede ***********************
REM * JOGA O NUMERO DA ZONA 999 EM zona
set zona=%computername:~3,3%
net use /persistent:no
net use u: /delete
net use u: \\ZNE%zona%\Documentos
REM *************** Final mapeamento da unidade de rede ********************

REM ********************* Execução dos scripts extras ***********************
rem scripts da máquina permanentes
:scr
for /f %%a in ('dir /b .\run') do (
	echo "executando...." .\run\%%a 
	cmd /c .\run\%%a
)
rem scripts da máquina unica execução
for /f %%a in ('dir /b .\runonce') do (
	echo "executando...." .\runonce\%%a 
	cmd /c exit 0
	cmd /c ".\runonce\%%a && set ret=0 || set ret=1"
	pause %ret% "valor retornado"
	if %ret% equ 0 (
		del .\runonce\%%a		 
		pause "script apagado"
	)
)
pause


goto fim

REM **** Local para adcionar comandos extras  *****


D:\AplicTRE\Suporte\Utilitarios\SysinternalsSuite\Bginfo.exe D:\AplicTRE\Suporte\Scripts\InfoSystem.bgi /NOLICPROMPT /SILENT /TIMER:0


:FIM

