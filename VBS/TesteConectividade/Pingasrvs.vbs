'Leitura do ip local para PrimaryIp
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")

 
'NET_PREFIX = "10.18"   ******* ALTERAR NA Producao
NET_PREFIX = "10.12"

PrimaryIp = ""
For Each IPConfig in IPConfigSet	
    If Not IsNull(IPConfig.IPAddress) Then 
        For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
            PrimaryIp = IPConfig.IPAddress(i)
            teste = Left(PrimaryIp, 5 )
			If ( teste = NET_PREFIX ) Then 
				Exit For				
			End If 
        Next
		If PrimaryIp <> "" Then 
			Exit For
		End if
    End If
Next


Gateway =  Left( PrimaryIp , InStrRev(PrimaryIp, "." ) ) & "70" 
strMachines = Gateway & ";pbdc01.tre-pb.gov.br;elo.tse.gov.br;intranet.tre-pb.gov.br"


' Pingar Vários Computadores
' ALTERE a primeira entrada do strMachines para o IP do VSAT/Router
aMachines = split(strMachines, ";")
 
For Each machine in aMachines
    Set objPing = GetObject("winmgmts:{impersonationLevel=impersonate}")._
        ExecQuery("select * from Win32_PingStatus where address = '"_
            & machine & "'")
    For Each objStatus in objPing
        If IsNull(objStatus.StatusCode) or objStatus.StatusCode<>0 Then 
            WScript.Echo("Servidor " & machine & " não acessível")
	Else
	    WScript.Echo("Servidor " & machine & " OK") 
        End If
    Next
Next



'WScript.Echo PrimaryIp & " teste= " & teste
