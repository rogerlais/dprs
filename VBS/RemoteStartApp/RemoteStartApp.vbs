'protocolo net 907130571702587

'*********************************************************
'*********** FLAG DE DEPURAÇÃO ABAIXO  *******************
const DBG = TRUE
'*********************************************************
'*********** DECLARAÇÃO DE CONSTANTES  *******************
Const SVCLOADER_LAST_VERSION = "2.02"   ''****Versao atual
Const THRESHOLD_DATE_PASSWORD = "20131016" 'Registro da alteração desta GPO
'constantes funcionais
Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const KEYPATH = "SOFTWARE\SESOP\Patches\AppliedDates"
Const PWD_LAST_SET_VALUE_NAME = "BioWksForcePwd"
Const SVCLOADER_KEYPATH = "SOFTWARE\Modulo\Sistemas Eleitorais\SvcLoader"
Const TMP_PKG_FOLDER = "D:\Comum\InstSeg\Suporte"
Const TMP_PKG_FILE = "GPO2VPN.exe"
Const PKG_URL = "http://arquivos/setores/instal/Aplicacoes_Seguras/Biometria/Suporte/SVCLoader/GPO2VPN.exe"
'*********************************************************


'*********************************************************
'****************  ROTINA PRIMÁRIA  *********************
On Error Resume Next
Err.Clear
Err.Number = 0
Main()
If Err.Number <> 0 Then
  WScript.Echo "Instalação falhou!" & vbCrLf & Err.Description
  WScript.Quit(8666) 'Informa ao preinst do erro  
End If

Sub Main()
	strLastSet = GetPasswordLastSet()
	if ( (strLastSet = NULL) or (strLastSet < THRESHOLD_DATE_PASSWORD) ) Then 
		ret = ForcePasswords()
		if ( ret = 0 ) then 
			ret = SetPasswordLastSet()
		end if
	else
		ret = 0 'Libera a atualização
	End If	
	
	'Inicia processo de atualização do servico SESOP
	if (ret = 0 ) then 'Atualizaçao do servico
		ret = InstallLastSVCLoader()
	end if
End Sub

Function InstallLastSVCLoader()
	InstallLastSVCLoader = 0
	if CheckNeedUpdate() then
		if GetURL( TMP_PKG_FOLDER ,TMP_PKG_FILE,PKG_URL ) then 
		
		end if
	end if
end Function

Public Function MD5Hash(sFileName)
  'This script is provided under the Creative Commons license located
  'at http://creativecommons.org/licenses/by-nc/2.5/ . It may not
  'be used for commercial purposes with out the expressed written consent
  'of NateRice.com

  Const OpenAsDefault = -2
  Const FailIfNotExist = 0
  Const ForReading = 1
 
  Dim oMD5CmdShell, oMD5CmdFSO, sTemp, sTempFile, fMD5CmdFile, sPath
  Dim fResultsFile, sResults

  Set oMD5CmdShell = CreateObject("WScript.Shell")
  Set oMD5CmdFSO = CreateObject("Scripting.FileSystemObject")
  sTemp = oMD5CmdShell.ExpandEnvironmentStrings("%TEMP%")
  sTempFile = sTemp & "\" & oMD5CmdFSO.GetTempName
 
  '------Verify Input File Existance-----
  If Not oMD5CmdFSO.FileExists(sFileName) Then
    MD5Hash = "Failed: Invalid Input File."
  Else
    Set fMD5CmdFile = oMD5CmdFSO.GetFile(sFileName)
    sPath = fMD5CmdFile.ShortPath
    sFileName = sPath
    Set fMD5CmdFile = Nothing
  End If
  '--------------------------------------
 
  oMD5CmdShell.Run "%comspec% /c md5.exe -n " & sFileName & _
  " > " & sTempFile, 0, True

  Set fResultsFile = _
  oMD5CmdFSO.OpenTextFile(sTempFile, ForReading, FailIfNotExist, OpenAsDefault)
  sResults = fResultsFile.ReadAll
  sResults = trim(Replace(sResults, vbCRLF,""))
  fResultsFile.Close
  oMD5CmdFSO.DeleteFile sTempFile
 
  If len(sResults) = 32 And IsHex(sResults) Then
    MD5Hash = sResults
  Else
    MD5Hash = "Failed."
  End If
 
  Set oMD5CmdShell = Nothing
  Set oMD5CmdFSO = Nothing
End Function

Private Function IsHex(sHexCheck)
  'This script is provided under the Creative Commons license located
  'at http://creativecommons.org/licenses/by-nc/2.5/ . It may not
  'be used for commercial purposes with out the expressed written consent
  'of NateRice.com

  Dim sX, bCharCheck, sHexValue, sHexValues, aHexValues
  sHexCheck = UCase(sHexCheck)
  sHexValues = "0,1,2,3,4,5,6,7,8,9,A,B,C,D,E,F"
  aHexValues = Split(sHexValues, ",")

  For sX = 1 To Len(sHexCheck)
    bCharCheck = False
    For Each sHexValue In aHexValues
      If UCase(Mid(sHexCheck,sX,1)) = sHexValue Then
        bCharCheck = True
        Exit For
      End If
    Next
   
    If bCharCheck <> True Then
      IsHex = False
      Exit Function
    End If
  Next
 
  IsHex = True
End Function

function GetURL( strDestFolder, strDestFile , strURL )
	'Busca arquivo via http
	Set objXMLHTTP = CreateObject("MSXML2.XMLHTTP")
	objXMLHTTP.open "GET", strURL, false
	objXMLHTTP.send()

	'Checa resposta
	If objXMLHTTP.Status = 200 Then 
		Set objADOStream = CreateObject("ADODB.Stream")
		objADOStream.Open
		objADOStream.Type = 1 'adTypeBinary

		objADOStream.Write objXMLHTTP.ResponseBody
		objADOStream.Position = 0    'inicio do stream

		Set objFSO = Createobject("Scripting.FileSystemObject")		
		BuildPath strDestFolder, objFSO 
		strFileName = strDestFolder & "\" & strDestFile
		If objFSO.Fileexists(strFileName) Then objFSO.DeleteFile strFileName		
		objADOStream.SaveToFile strFileName
		objADOStream.Close
		Set objFile = objFSO.GetFile( strFileName )
		strHash = MD5Hash( strFileName )
		
		Set objFSO = Nothing
		Set objADOStream = Nothing
	End if
	Set objXMLHTTP = Nothing

End Function


Function CheckNeedUpdate()
	CheckNeedUpdate = FALSE
	strValue = ""
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	oReg.GetStringValue HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"versao",strValue
	if strValue <> NULL then 
		CheckNeedUpdate = ( strValue < SVCLOADER_LAST_VERSION)
	else 
		CheckNeedUpdate = TRUE
	end if		
end Function

Function GetPasswordLastSet()
	'Retorna data gravada no registro da alteração das senhas
	strValue = ""
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	oReg.GetStringValue HKEY_LOCAL_MACHINE,KEYPATH,PWD_LAST_SET_VALUE_NAME,strValue
	Err.Clear
	GetPasswordLastSet = strValue	
End Function


function  SetPasswordLastSet()
	dt = Now()
	strTimeStamp =  Year(dt) & Right("0" & Month(dt),2) & Right("0" & Day(dt),2)
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	ret = oReg.CreateKey( HKEY_LOCAL_MACHINE,KEYPATH)
	If (ret = 0) And (Err.Number = 0) Then   
		oReg.SetStringValue HKEY_LOCAL_MACHINE,KEYPATH,PWD_LAST_SET_VALUE_NAME,strTimeStamp
	else
		SetPasswordLastSet = ret
	end if		
End Function

public function ForcePasswords()
	ForcePasswords = 1
	Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000
	Set WshNetwork = WScript.CreateObject("WScript.Network")
	strComputer = WshNetwork.ComputerName
	if DBG then
		strUsername = "vncacesso"
	else 
		strUsername = "suporte"
	end if
	Set objUser = GetObject("WinNT://" & strComputer & "/" & strUsername & ", user")
	objUserFlags = objUser.Get("UserFlags")
	objPasswordExpirationFlag = objUserFlags OR ADS_UF_DONT_EXPIRE_PASSWD
	objUser.Put "userFlags", objPasswordExpirationFlag 

	objUser.SetPassword "355aagonia"
	ret = objUser.SetInfo
	if ( ret = NULL ) then 
		ForcePasswords = ret
	else 
		ForcePasswords = 0
	end if
end function

Sub BuildPath(ByVal Path, fso )
  If Not fso.FolderExists(Path) Then
    BuildPath fso.GetParentFolderName(Path), fso
    fso.CreateFolder Path
  End If
End Sub