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
        objFSO.CopyFile "\\pbdc00\netlogon\tnsnames\tnsnames.ora" , strValue & "\network\admin\" , OverwriteExisting
        'Wscript.Echo "copiando de " & "\\pbdc00\netlogon\tnsnames\tnsnames.ora\" & " para " & strValue & "\network\admin\"
        objFSO.CopyFile "\\pbdc00\netlogon\tnsnames\sqlnet.ora" , strValue & "\network\admin\" , OverwriteExisting
        'Wscript.Echo "copiando de " & "\\pbdc00\netlogon\tnsnames\sqlnet.ora\" & " para " & strValue & "\network\admin\"
End If