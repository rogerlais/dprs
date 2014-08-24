REM Author: Roger
REM 20130227

cls 
@echo off


set conta=ponto
set conta_pwd=12345678

:step1

rem ***********************************************************
rem 1 - criar conta de usuário para autologon
net user | find /i "%conta%" || goto account_create
goto step2

:account_create
net user %conta% %conta_pwd% /ADD /comment:"exclusiva para uso ponto" /expires:never /passwordchg:no
if not errorlevel 0 ( 
		set emsg=Falha criando conta
		goto show_error
	) else (
		echo conta criada com sucesso
		goto step2
	)

rem ***********************************************************


rem 2 - ajustar conta como admim do computador
:step2
echo adcionando ao admin local
net localgroup "Administradores" "%conta%" /add
pause

rem 3 - rodar setup_user com a credencial da conta de operação
:step3
echo informe a senha da conta para uso restrito
runas /user:%conta% ""%cd%\setup_user.bat" %cd%"


rem 4 - remover conta do grupo admim local
net localgroup "Administradores" "%conta%" /delete

rem 5 - Ajustar o auto logon
regedit /v Mesclar_Computador.reg

rem 6 - copiar atalho de desintalação para desktop comum
-----Criar atalho !!!!!! ao invés de copiar
copy Prompt_Comando.* C:\DOCUME~1\ALLUSE~1\Desktop /y

rem 7 - copia batch "chama_ponto.bat" de chamada do ponto para inicializar comum
copy chama_ponto.bat C:\DOCUME~1\ALLUSE~1\MENUIN~1\Programas\INICIA~1 /y

:show_error
echo emsg
pause

:fim