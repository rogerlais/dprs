;ESTE PROGRAMA FOI COMPILADO NO NSIS <http://nsis.sourceforge.net/>
;OBJETIVOS:
	;1. INSTALAR O BROFFICE.ORG 3.0 VIA LOGIN SCRIPT EM REDES WINDOWS
	;2. INSTALAR AS SEGUINTES EXTENSÕES QUE FICARÃO DISPONÍVEIS APENAS PARA O USUÁRIO QUE INSTALOU O PRODUTO
		;- VERIFICADOR ORTOGRÁFICO
		;- VERIFICADOR GRAMATICAL
		;- MODELOS DE DOCUMENTOS
		;* A DISPONIBILIZAÇÃO DAS EXTENSÕES PARA OS DEMAIS PROFILES É CONTROLADA POR OUTRO PROGRAMA (bro-personal.exe)
;CARACTERÍSTICAS DO INSTALADOR: INSTALAÇÃO FORÇADA DESASSISTIDA; FAZ NOVA TENTATIVA DE INSTALAÇÃO A CADA 10 MINUTOS
;AUTOR: KRAUCER FERNANDES MAZUCO (<kraucer@bb.com.br) em 07/11/2008
;LICENÇA: GPL <http://www.fsf.org/licensing/licenses/gpl.html>

Name "Instalador do BrOffice.org 3.0"
OutFile "instalar.exe"
!include "FileFunc.nsh"
!insertmacro DriveSpace
!include "LogicLib.nsh"
!insertmacro GetTime
!include "WinMessages.nsh"
RequestExecutionLevel user ;exigido pelo UAC do Windows Vista
ShowInstDetails Nevershow
Var VAL		;valor sequencial da instalação
Var LIM		;valor limite de instalações simultâneas
Var TEN		;número de tentativas
Var ATU
Var ATT
Var dat1
Var dat2
Var dat3
Var dat4
Var dat5
Var dat6
Var dat7
Var hor1
Var hor2
Var min1
Var min2
Var intermin
Var LOCALDATA
Var USERNAME
Var SISOP

Function .onInit
		SetSilent Silent
		;O CONTROLE DA EXISTÊNCIA OU NÃO DO BROFFICE.ORG NÃO ESTÁ MAIS NO LOGIN SCRIPT. POR ESSE MOTIVO, IREI VERIFICAR AGORA SUA
		;EXISTÊNCIA. CASO ESTEJA INSTALADO, NÃO IREI EXECUTAR O INSTALADOR
		IfFileExists "$PROGRAMFILES\BrOffice.org 3\program\soffice.exe" 0 +2
			Quit
			
		;PROCEDIMENTO VERIFICA SE O ARQUIVO CONTADOR FICOU MAIS DE 30 MINUTOS SEM ALTERAÇÕES
		;SE FICOU, PROVAVELMENTE O MESMO TRAVOU O VALOR DO CONTADOR NO VALOR MÁXIMO, IMPEDINDO NOVAS INSTALAÇÕES
		;NESTE CASO, O SISTEMA IRÁ RETORNAR O VALOR DO CONTADOR AO VALOR INICIAL DE ZERO (0)
		${GetTime} "P:\OpenOffice\contador.txt" "m" $dat1 $dat2 $dat3 $dat4 $dat5 $dat6 $dat7
		; $dat1="01"      day
		; $dat2="04"      month
		; $dat3="2005"    year
		; $dat4="Friday"  day of week name
		; $dat5="16"      hour
		; $dat6="05"      minute
		; $dat7="50"      seconds
		IntOp $hor1 $dat5 * 60
		IntOp $min1 $dat6 + $hor1
		${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
		; $0="01"      day
		; $1="04"      month
		; $2="2005"    year
		; $3="Friday"  day of week name
		; $4="16"      hour
		; $5="05"      minute
		; $6="50"      seconds
		IntOp $hor2 $4 * 60
		IntOp $min2 $5 + $hor2
		IntOp $intermin $min2 - $min1
			
		${If} $0 != $dat1
			CopyFiles H:\BrOffice-v30\contador.txt "P:\OpenOffice\contador.txt"
		${ElseIf} $0 = $dat1
			${If} $intermin > '30'
				CopyFiles H:\BrOffice-v30\contador.txt "P:\OpenOffice\contador.txt"
			${EndIf}
		${EndIf}
		
		;VERIFICA SE EXISTE O ARQUIVO contador.txt. SE NÃO EXISTIR, ELE É CRIADO A PARTIR DE UMA CÓPIA DO DRIVE H:
		ClearErrors
		${DriveSpace} "p:\openoffice\contador.txt" "/D=F /S=M" $R2
		IfErrors 0 +2
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		
		;ABRE O ARQUIVO contador.txt PARA LER O NÚMERO DE INSTALAÇÕES SIMULTÂNEAS ONLINE
Nova_tentativa:	ClearErrors
		IntOP $TEN $TEN + 1
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_Open
		FileRead $0 $1
		IntOp $VAL $1 + 1
		FileClose $0
		
		;ABRE O ARQUIVO LIMITE.TXT PARA LER A VARIÁVEL QUE CONTÉM O NÚMERO LIMITE DE INSTALAÇÕES SIMULTÂNEAS
		ClearErrors
		FileOpen $0 H:\BrOffice-v30\limite.txt r
            FileRead $0 $LIM
		FileClose $0

		;SE O NÚMERO DE INSTALAÇÕES SIMULTÂNEAS FOR ATINGIDO, FINALIZA O PROGRAMA
		${If} $VAL > $LIM
		  	; FAREI NOVA TENTATIVA DE INSTALAÇÃO APÓS 10 MINUTOS
			sleep 600000
			call .onInit
		${EndIf}	

		;INCREMENTA O CONTADOR DE INSTALAÇÕES SIMULTÂNEAS
Reabre:	ClearErrors
		IntOP $ATU $ATU + 1
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_atual		
		FileWrite $0 $VAL
            FileClose $0
		Goto +16

Wait_Open:	${If} $TEN >= '10'
			Quit
		${ElseIf} $TEN < '10'
			Sleep 2000
			Goto Nova_tentativa
		${EndIf}		
		Quit

Wait_atual:	${If} $ATU >= '10'
			Quit
		${Elseif} $ATU < '10'
			Sleep 500
			Goto Reabre
		${Endif}
		Quit
FunctionEnd

Section "Início"
	;ROTINA VERIFICA SE O ESPAÇO EM DISCO É SUFICIENTE PARA A INSTALAÇÃO
	${DriveSpace} "C:\" "/D=F /S=M" $R0
	${If} $R0 >= '400'

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
		
		;EXECUTA A INSTALAÇÃO DO BROFFICE.ORG EM MODO QUIET
		MessageBox MB_OK|MB_ICONEXCLAMATION "O BrOffice.org de sua estação será atualizado para a versão 3.0 e suas versões antigas serão removidas. Favor não utilizar o aplicativo BrOffice até que o processo seja concluído. Você será notificado sobre o término do mesmo em no máximo 10 minutos. Clique em OK para continuar."
		DetailPrint "Instalando o BrOffice.org 3.0...aguarde!!!"
		
		;SÓ IREI MOSTRAR A MENSAGEM ABAIXO SE O SISTEMA OPERACIONAL FOR WINDOWS VISTA
		StrCmp $SISOP "Windows Vista (TM) Business" 0 +2
		MessageBox MB_OK|MB_ICONEXCLAMATION "ATENÇÃO USUÁRIOS DO WINDOWS VISTA: Na próxima tela, clique na opção 'PERMITIR' para que a instalação possa prosseguir."
		
		ExecWait "msiexec /passive /norestart /i H:\BrOffice-v30\brofficeorg30.msi ADDLOCAL=ALL REMOVE=gm_o_Quickstart ALLUSERS=1"

		;DESINSTALA VERSÃO ANTIGA DO VERIFICADOR ORTOGRÁFICO
		ExecWait "$PROGRAMFILES\BrOffice.org 3\program\unopkg.exe remove --shared dict-pt.oxt"
				
		;APLICA AS PERSONALIZAÇÕES DO BROFFICE.ORG PARA O USUÁRIO ATUAL
		ExecWait "H:\BrOffice-v30\personal\bro-personal.exe"
		
		;LÊ O ARQUIVO contador.txt E DECREMENTA O CONTADOR DE INSTALAÇÕES SIMULTÂNEAS NO FINAL DA INSTALAÇÃO
		DetailPrint "Abrindo arquivo de contagem..."
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		FileRead $0 $1
		IntOp $VAL $1 - 1
		FileClose $0

		;ATUALIZA O VALOR DO CONTADOR DE INSTALAÇÕES SIMULTÂNEAS
		DetailPrint "Decrementando número de instalações simultâneas..."
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		FileWrite $0 $VAL
            FileClose $0
		${If} $VAL < 0
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		${Endif}
		${If} $VAL > $LIM
			CopyFiles H:\BrOffice-v30\contador.txt "p:\openoffice\contador.txt"
		${Endif}
		IfFileExists "$PROGRAMFILES\BrOffice.org 3\program\soffice.exe" +3 0
			MessageBox MB_OK|MB_ICONEXCLAMATION "A instalação do BrOffice.org foi cancelada. Será realizada nova tentativa no próximo logon."
			Quit
		MessageBox MB_OK|MB_ICONEXCLAMATION "O BrOffice.org 3.0 e as seguintes extensões foram instaladas com sucesso: dicionários temáticos de informática e jurídico, modelos de documentos, corretor ortográfico e gramatical, importador e editor de PDF´s."
		Quit
		
	${ElseIf} $R0 < '400'
		;CANCELA O PROCESSO DE INSTALAÇÃO DEVIDO AO ESPAÇO INSUFICIENTE NO DISCO
		;DECREMENTA O VALOR DO CONTADOR DE INSTALAÇÕES SIMULTÂNEAS
		DetailPrint "Decrementando número de instalações simultâneas..."
Re_open:	IntOP $ATT $ATT + 1
		ClearErrors
		FileOpen $0 p:\openoffice\contador.txt a
		IfErrors 0 +2
			Goto Wait_att
		FileWrite $0 $1
        FileClose $0
		MessageBox MB_OK|MB_ICONEXCLAMATION "A instalação automática do BrOffice.org foi cancelada. É necessário um espaço mínimo de 400 MegaBytes livres no disco rígido. Clique no botão OK para finalizar."
	    Quit
    ${EndIf}

Wait_att:	${If} $ATT >= '10'
			Quit
		${Elseif} $ATT < '10'
			Sleep 500
			Goto Re_open
		${Endif}
		Quit
SectionEnd