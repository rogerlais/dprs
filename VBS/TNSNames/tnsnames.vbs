	Const HKEY_CURRENT_USER = &H80000001
	Const HKEY_LOCAL_MACHINE = &H80000002
	
	strComputer = "."
	strValue = ""

	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")

	strKeyPath = "SOFTWARE\ORACLE"

	strValueName = "ORACLE_HOME"


	'oReg.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue

	intRet = oReg.GetStringValue(HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue)

	strValue = "" & strValue
	If (strValue = "") Or ( intRet <> 0 ) Then

	        arrSubKeys = null

	        oReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys

	        REM  Enumerate the array and display the Name
	        For Each strSubk In arrSubKeys
	            ssk = strKeyPath & "\" & strSubk
	            sskName = strValueName
	            intRet = oReg.GetStringValue(HKEY_LOCAL_MACHINE, ssk, sskName ,strValue)
	            If (strValue <> "") And (intRet = 0) Then
	                REM strvalue wil be the value your ORACLE_home
	                'Wscript.Echo ssk & "\" & sskName & " = " & strValue
	                Exit For
	            End If
	        Next

	End If


	'Teste final de caminho encontrado
	If (strValue <> "") Then
	        'Wscript.Echo "passo teste final"
	        Const OverwriteExisting = TRUE
	        Set objFSO = CreateObject("Scripting.FileSystemObject")
			
			'Chamada mais segura para atualizar os arquivos
			call UpdateFile( objFSO, "\\pbdc00\netlogon\tnsnames\", strValue & "\network\admin\", "tnsnames.ora" )
			call UpdateFile( objFSO, "\\pbdc00\netlogon\tnsnames\", strValue & "\network\admin\", "sqlnet.ora" )
			
	        '---objFSO.CopyFile "\\pbdc00\netlogon\tnsnames\tnsnames.ora" , strValue & "\network\admin\" , OverwriteExisting
	        'Wscript.Echo "copiando de " & "\\pbdc00\netlogon\tnsnames\tnsnames.ora\" & " para " & strValue & "\network\admin\"
	        '---objFSO.CopyFile "\\pbdc00\netlogon\tnsnames\sqlnet.ora" , strValue & "\network\admin\" , OverwriteExisting
	        'Wscript.Echo "copiando de " & "\\pbdc00\netlogon\tnsnames\sqlnet.ora\" & " para " & strValue & "\network\admin\"
	End If


REM Atualiza o arquivo passado preservando o original
Sub UpdateFile( ByRef objFSO, ByRef SrcDir, ByVal DestDir, ByRef DestFilename)
	'Verifica versao previa
	On Error Resume Next
	Dim bakName, fullDestName, fullSourceName
	Dim fOldFile	
	fullDestName = DestDir & DestFilename
	if ( objFSO.FileExists( fullDestName ) ) then 'Monta backup imediato
		bakName = DestDir & DestFilename & ".old"
		
		if ( objFSO.FileExists( bakName ) ) then
			objFSO.DeleteFile( bakName )
		end if
		objFSO.CopyFile fullDestName, bakName, True
	end If		
	fullSourceName = SrcDir & DestFilename	
	objFSO.CopyFile fullSourceName, fullDestName, True
	If Err.Number <> 0 then
		Set fOldFile = objFSO.GetFile( bakName )
		fOldFile.Move( fullDestName )
	Else
		objFSO.DeleteFile( bakName )
	end if
End Sub