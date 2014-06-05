cls
@echo "USRINIT - 1.0.2014(PDC,STD,WKS,CAE)"
@echo off

REM ****************** Mapeamento da unidade de rede ***********************
REM * JOGA O NUMERO DA ZONA 999 EM zona
set zona=%computername:~3,3%
net use /persistent:no
net use u: /delete
@echo mapeando ZNE%zona%\Documentos
net use u: \\ZNE%zona%\Documentos
REM *************** Final mapeamento da unidade de rede ********************


REM ********************* Execução dos scripts extras ***********************
rem scripts da máquina permanentes
:scr
for /f %%a in ('dir /b .\run') do (
	echo executando.... .\run\%%a 
	cmd /c .\run\%%a
)
rem scripts da máquina unica execução
for /f %%a in ('dir /b .\runonce') do (
	echo executando.... .\runonce\%%a
	rem zera erro anterior
	cmd /c exit 0
	rem script chamado deve ter "cmd /c exit <n>" em sua ultima linha para informar o erro
	cmd /c .\runonce\%%a
	rem testa qualquer retorno > 0 
	if not ERRORLEVEL 1 (
		echo "apagando..." .\runonce\%%a
		del .\runonce\%%a		 
	) else (
		echo "falha rodando: " .\runonce\%%a
	)
)
REM ***************** Final execução dos scripts extras *********************



REM *************************** Chamada BGInfo *******************************
REM **** Local para adcionar comandos extras  *****
D:\AplicTRE\Suporte\Utilitarios\SysinternalsSuite\Bginfo.exe D:\AplicTRE\Suporte\Scripts\InfoSystem.bgi /NOLICPROMPT /SILENT /TIMER:0


:FIM

