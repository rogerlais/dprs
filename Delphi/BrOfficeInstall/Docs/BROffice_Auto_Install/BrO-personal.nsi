;ESTE PROGRAMA FOI COMPILADO NO NSIS <http://nsis.sourceforge.net/>
;OBJETIVOS:
	;1. INSTALAR AS SEGUINTES EXTENSÕES QUE FICARÃO DISPONÍVEIS PARA O USUÁRIO QUE LOGOU NA ESTAÇÃO
		;- VERIFICADOR ORTOGRÁFICO
		;- VERIFICADOR GRAMATICAL
		;- MODELOS DE DOCUMENTOS
	;2. FAZ O LOAD DOS DICIONÁRIOS INSTALADOS
;CARACTERÍSTICAS DO INSTALADOR: INSTALAÇÃO FORÇADA DESASSISTIDA
;AUTOR: KRAUCER FERNANDES MAZUCO (<kraucer@bb.com.br) em 07/11/2008
;LICENÇA: GPL <http://www.fsf.org/licensing/licenses/gpl.html>

Name "Personalizador do BrOffice.org"
OutFile "bro-personal.exe"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WinMessages.nsh"
RequestExecutionLevel user ;apenas para o Windows Vista + UAC
ShowInstDetails Nevershow
Var LOCALDATA
Var USERNAME
Var SISOP

Function .onInit
		SetSilent Silent
FunctionEnd

Section "Início"
		;IREI LER O SISTEMA OPERACIONAL DEVIDO A ALGUMAS ESPECIFICIDADES ENTRE XP E VISTA
		ReadRegStr $SISOP HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" ProductName
		
		;BUSCO O NOME DO USUÁRIO LOGADO NO MOMENTO DA INSTALAÇÃO
		UserInfo::GetName
		Pop $USERNAME
		
		;POR NÃO CONSEGUIR TRATAR CORRETAMENTE A CONSTANTE $LOCALAPPDATA, IREI VERIFICÁ-LA CONFORME O SISTEMA OPERACIONAL
		ReadRegStr $SISOP HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" ProductName
		StrCpy $LOCALDATA "C:\Documents and Settings\$USERNAME\dados de aplicativos"
		${If} $SISOP == 'Microsoft Windows XP'
			StrCpy $LOCALDATA "C:\Documents and Settings\$USERNAME\dados de aplicativos"
		${ElseIf} $SISOP == 'Windows Vista (TM) Business'
			StrCpy $LOCALDATA "C:\Users\$USERNAME\AppData\Roaming"
		${EndIf}
		
		;O CONTROLE DA EXISTÊNCIA OU NÃO DAS DO BROFFICE.ORG NÃO ESTÁ MAIS NO LOGIN SCRIPT. POR ESSE MOTIVO, IREI VERIFICAR AGORA SUA
		;EXISTÊNCIA. CASO AS PERSONALIZAÇÕES JÁ EXISTIREM,  NÃO IREI EXECUTAR.
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Setup.xcu" 0 +2
			Quit
			
		;INSTALAÇÕES PERSONALIZADAS E EXCLUSIVAS PARA O WINDOWS XP (VISTA NÃO PERMITE DEVIDO AO CONTROLE DO UAC)
		;INSTALANDO A EXTENSÃO DO VERIFICADOR ORTOGRÁFICO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extensões\Vero_pt_BR_V200AOC.oxt"

		;INSTALANDO A EXTENSÃO DO CORRETOR GRAMATICAL COGROO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extensões\CoGrOO-AddOn-3.0.1-bin.oxt"

		;INSTALANDO A EXTENSÃO DO MODELO DE DOCUMENTOS
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extensões\Modelos_BrOffice-BB-v01.oxt"			

		;INSTALANDO A EXTENSÃO QUE POSSIBILITA A IMPORTAÇÃO DE ARQUIVOS PDF NO DRAW
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe add H:\BrOffice-v30\Extensões\pdfimport.oxt"
		
		;INSTALANDO DICIONÁRIOS TEMÁTICOS DE INFORMÁTICA E JURÍDICO APENAS PARA O USUÁRIO QUE INSTALOU O BROFFICE.ORG POIS NÃO
		;CONSIGO ESCREVER NO C:\PROGRAM FILES DO VISTA DEVIDO AO UAC
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\wordbook\DicInfo.dic" +6 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo2.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicInfo3.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
			CopyFiles H:\BrOffice-v30\dict\DicJuridico.dic "$LOCALDATA\BrOffice.org\3\user\wordbook"
		
		;SE O ARQUIVO SETUP.XCU NÃO EXISTIR NO PROFILE DO USUÁRIO, FAREI A CÓPIA PARA EVITAR TELA DE ERRO NA INICIALIZAÇÃO
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Setup.xcu" +3 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice"
			CopyFiles H:\BrOffice-v30\register\Setup.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice"
		
		;SE O ARQUIVO COMMON.XCU NÃO EXISTIR NO PROFILE DO USUÁRIO, FAREI A CÓPIA PARA EVITAR TELA DE ERRO NA INICIALIZAÇÃO
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office\Common.xcu" +3 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office"
			CopyFiles H:\BrOffice-v30\register\Common.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office\Common.xcu"
		
		;SE O ARQUIVO  SCRIPT.XLC NÃO EXISTIR NO PROFILE DO USUÁRIO, FAREI A CÓPIA PARA EVITAR TELA DE ERRO NA INICIALIZAÇÃO
		IfFileExists "$LOCALDATA\BrOffice.org\3\user\basic\script.xlc" +8 0
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\basic"
			CopyFiles H:\BrOffice-v30\register\script.xlc "$LOCALDATA\BrOffice.org\3\user\basic"
			CopyFiles H:\BrOffice-v30\register\dialog.xlc "$LOCALDATA\BrOffice.org\3\user\basic"
			CreateDirectory "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\script.xlb "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\dialog.xlb "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			CopyFiles H:\BrOffice-v30\register\Module1.xba "$LOCALDATA\BrOffice.org\3\user\basic\Standard"
			
		;ATIVA O LOAD DE TODOS OS DICIONÁRIOS IMPLANTADOS
		CopyFiles H:\BrOffice-v30\dict\Linguistic.xcu "$LOCALDATA\BrOffice.org\3\user\registry\data\org\openoffice\Office"
		Quit
SectionEnd