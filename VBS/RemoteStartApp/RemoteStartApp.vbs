'protocolo net 907130571702587

'*********************************************************
'*********** FLAG DE DEPURAÇÃO ABAIXO  *******************
const DBG = FALSE
'*********************************************************
'*********** DECLARAÇÃO DE CONSTANTES  *******************
Const SVCLOADER_LAST_VERSION = "2.02"   ''****Versao atual
Const THRESHOLD_DATE_PASSWORD = "20131016" 'Registro da alteração desta GPO
'constantes funcionais
Const HKEY_CURRENT_USER = &H80000001
Const HKEY_LOCAL_MACHINE = &H80000002
Const KEYPATH = "SOFTWARE\SESOP\Patches\AppliedDates"
Const PWD_LAST_SET_VALUE_NAME = "BioWksForcePwd"
Const SVCLOADER_KEYPATH = "SOFTWARE\Sistemas Eleitorais\SvcLoader"
Const TMP_PKG_FOLDER = "D:\Comum\InstSeg"
Const TMP_PKG_FILE = "GPO2VPN.exe"
Const PKG_URL = "http://arquivos/setores/instal/Aplicacoes_Seguras/Biometria/Suporte/SVCLoader/202.sfx"
Const EXPECT_FILE_HASH = "00000000000000000000000000000000000"
Const EXPECTED_FILESIZE = 881250 'Valor negativo -> qq coisa vale
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
	ret = False
	strLastSet = GetPasswordLastSet()
	if ( IsNull(strLastSet) or (strLastSet < THRESHOLD_DATE_PASSWORD) ) Then 
		ret = ForcePasswords()
		if ( ret ) then 
			ret = SetPasswordLastSet()
		end if
	else
		ret = True 'Libera a atualização
	End If	
	
	'Inicia processo de atualização do servico SESOP
	if (ret) then 'Atualizaçao do servico
		ret = InstallLastSVCLoader()
		if ( ret ) then 
			SetAppSegSignature() 'Grava no resgistro as entradas de aplicação segura instalada
		end if
	end if
End Sub

function SetAppSegSignature() 
	ret = 0
	SetAppSegSignature = False
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	ret = oReg.CreateKey( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"versao",SVCLOADER_LAST_VERSION )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"Nome", "Carregador de Serviços SESOP" )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"DataUltimoUpgrade", "30/08/2013" )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"DataGeracao", "29/08/2013" )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"DataInstalacao" , "30/08/2013" )
	ret = ret + oReg.SetStringValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"Nome Curto" , "SvcLoader" )
	ret = ret + oReg.SetDWORDValue( HKEY_LOCAL_MACHINE,SVCLOADER_KEYPATH,"Numero", 12213) ' 12213 equivale = dword:00002fb5	
	Set oReg = Nothing
	SetAppSegSignature = ( ret = 0 )
end function

Function InstallLastSVCLoader()
	InstallLastSVCLoader = False
	strReturn = ""
	if CheckNeedUpdate() then
		if GetURL( TMP_PKG_FOLDER ,TMP_PKG_FILE,PKG_URL ) then 
			IF dbg Then
				intShow = 1
			else
				intShow = 0
			end if			
			ret = Run_CommandOutput( TMP_PKG_FOLDER & "\" & TMP_PKG_FILE & " e -o" & TMP_PKG_FOLDER & " -y", 1, intShow, TMP_PKG_FOLDER & "\GPO2VPN.log", 0, 1, strReturn )
			if ( ret = 0 ) then 
				ret = Run_CommandOutput( TMP_PKG_FOLDER & "\install.vbs", 1, intShow, TMP_PKG_FOLDER & "\GPO2VPN.log", 0, 1, strReturn )
				InstallLastSVCLoader = ( ret = 0 )				
			end if
		end if
	end if
end Function

Function Run_CommandOutput(Command, Wait, Show, OutToFile, DeleteOutput, NoQuotes, ByRef strOutput )
'Run Command similar to the command prompt, for Wait use 1 or 0. Output returned and
'stored in a file.
'Command = The command line instruction you wish to run.
'Wait = 1/0; 1 will wait for the command to finish before continuing.
'Show = 1/0; 1 will show for the command window.
'OutToFile = The file you wish to have the output recorded to.
'DeleteOutput = 1/0; 1 deletes the output file. Output is still returned to variable.
'NoQuotes = 1/0; 1 will skip wrapping the command with quotes, some commands wont work
'                if you wrap them in quotes.
'----------------------------------------------------------------------------------------
	On Error Resume Next
	'On Error Goto 0
    Set f_objShell = CreateObject("Wscript.Shell")
    Set f_objFso = CreateObject("Scripting.FileSystemObject")
    Const ForReading = 1, ForWriting = 2, ForAppending = 8
    'VARIABLES
    If OutToFile = "" Then OutToFile = "TEMP.TXT"
    tCommand = Command
    If Left(Command,1)<>"""" And NoQuotes <> 1 Then tCommand = """" & Command & """"
    tOutToFile = OutToFile
    If Left(OutToFile,1)<>"""" Then tOutToFile = """" & OutToFile & """"
    If Wait = 1 Then tWait = True
    If Wait <> 1 Then tWait = False
    If Show = 1 Then tShow = 1
    If Show <> 1 Then tShow = 0
    'RUN PROGRAM
    Run_CommandOutput = f_objShell.Run( tCommand & " > " & tOutToFile, tShow, tWait)
    'READ OUTPUT FOR RETURN
	if f_objFso.FileExists(OutToFile) then
		Set f_objFile = f_objFso.OpenTextFile(OutToFile, 1)
		tMyOutput = f_objFile.ReadAll
		f_objFile.Close
		Set f_objFile = Nothing
		If DeleteOutput = 1 Then
			Set f_objFile = f_objFso.GetFile(OutToFile)
			f_objFile.Delete			    
		End If			
	else
		tMyOutput = ""
    end if
	Set f_objFile = Nothing
	'DELETE FILE AND FINISH FUNCTION
	strReturn = tMyOutput
	If Err.Number <> 0 Then strReturn = "<0>"
	Err.Clear
	On Error Goto 0
	Set f_objFile = Nothing
	Set f_objShell = Nothing
End Function

function CheckHash( sFilename, strValidHash, intFileSize )
	CheckHash = False
	Set objFSO = Createobject("Scripting.FileSystemObject")
	if objFSO.FileExists( sFilename ) then	
		Set objFile = objFSO.GetFile( sFilename )
		if ( objFile.Size = intFileSize ) then 
			CheckHash = True
		else
			CheckHash = ( intFileSize < 0 ) 'Caso negativo -> não checar
		end if
	end if	
end function

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
		'Valida arquivo
		GetURL = CheckHash( strFileName, EXPECT_FILE_HASH, EXPECTED_FILESIZE )
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
	SetPasswordLastSet = False
	dt = Now()
	strTimeStamp =  Year(dt) & Right("0" & Month(dt),2) & Right("0" & Day(dt),2)
	Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\default:StdRegProv")
	ret = oReg.CreateKey( HKEY_LOCAL_MACHINE,KEYPATH)
	If (ret = 0) And (Err.Number = 0) Then   
		ret = oReg.SetStringValue( HKEY_LOCAL_MACHINE,KEYPATH,PWD_LAST_SET_VALUE_NAME,strTimeStamp )
	end if		
	SetPasswordLastSet = ( ret = 0 )
End Function

public function ChangePwd( objUser, strNewPwd )
	ChangePwd = 1
	objUserFlags = objUser.Get("UserFlags")
	objPasswordExpirationFlag = objUserFlags OR ADS_UF_DONT_EXPIRE_PASSWD
	objUser.Put "userFlags", objPasswordExpirationFlag 
	objUser.SetPassword strNewPwd
	ChangePwd = objUser.SetInfo
end function

public function ForcePasswords()
	ForcePasswords = False
	Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000
	Set WshNetwork = WScript.CreateObject("WScript.Network")
	strComputer = WshNetwork.ComputerName
	if DBG then
		strUsername1 = "vncacesso"
		strUsername2 = "vncacesso"
	else 
		strUsername1 = "suporte"
		strUsername2 = "vncacesso"
	end if
	Set objUser = GetObject("WinNT://" & strComputer & "/" & strUsername1 & ", user")
	ret1 = ChangePwd( objUser, "355aagonia" )
	Set objUser = GetObject("WinNT://" & strComputer & "/" & strUsername2 & ", user")
	ret2 = ChangePwd( objUser, "3uforia!" )	
	ForcePasswords = ( IsEmpty(ret1) and IsEmpty(ret2) )
end function

Sub BuildPath(ByVal Path, fso )
  If Not fso.FolderExists(Path) Then
    BuildPath fso.GetParentFolderName(Path), fso
    fso.CreateFolder Path
  End If
End Sub