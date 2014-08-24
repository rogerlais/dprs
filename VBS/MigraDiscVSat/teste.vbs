vsatIpAddress = Array("")
vsatGateway = Array("")

strEcho = ""
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")
For Each IPConfig in IPConfigSet
    If Not IsNull(IPConfig.IPAddress) Then 
        For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
			oldIpAddress = IPConfig.IPAddress(i)
			vsatIpAddress(0) = Replace( oldIpAddress, ".183.",  ".187." )
			vsatGateway(0) =  Left( vsatIpAddress(0) , InStrRev(vsatIpAddress(0), "." ) ) & "70" 
            strEcho = "Novo IP = " & vsatIpAddress(0) & vbCrLF & _
					  "Novo Gateway = " & vsatGateway(0) & vbCrLF 
			WScript.Echo StrEcho
			If StrComp( vsatIpAddress(0), oldIpAddress, vbTextCompare ) <> 0 Then 
			IPConfig.EnableStatic( Array(vsatIpAddress), Array(vsatGateway) )
			strEcho = strEcho & " endereco alterado" & vbCrLf
			End If
			 
			'IPConfig.IPSubnet(i) & vbCrLf & vbCrLf & _
			'IPConfig.DNSServerSearchOrder(i) & vbCrLf & vbCrLf & _
            'IPConfig.DefaultIPGateway(i)[0]    
        Next
    End If
Next




strComputer = "." 
set oldipadress="." 
set oldgateway ="."

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2") 
Set colNetAdapters = objWMIService.ExecQuery _ 
("Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE") 
strIPAddress = Array("10.187.55.140") 
strSubnetMask = Array("255.255.255.0") 
strGateway = Array("10.187.55.70") 
strGatewayMetric = Array(1) 

For Each objNetAdapter in colNetAdapters 
	'Varre as config IPs de todos adapatadores
	For i=LBound(objNetAdapter.IPAddress) to UBound(objNetAdapter.IPAddress)
		'Leitura dos valores atuais e troca da cadeia ".183. por ".187.	
		strGateway = objNetAdapter.strDefaultIPGateway
		strGateway = RepStr( ".183.", strGateway )
		strGateway = objNetAdapter.

		errEnable = objNetAdapter.EnableStatic(strIPAddress, strSubnetMask) 
		errGateways = objNetAdapter.SetGateways(strGateway, strGatewaymetric) 
		If errEnable = 0 Then 
			WScript.Echo "O endereco IP foi alterado com sucesso!" 
		Else 
			WScript.Echo "Ocorreu um erro! O endereco IP não foi alterado..." 
		End If 
	Next
Next 





strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")
For Each IPConfig in IPConfigSet
    If Not IsNull(IPConfig.IPAddress) Then 
        For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
            WScript.Echo _
				  "Nome do Host: " & IPConfig.DNSHostName(i) & vbCrLf & vbCrLf & _
                  "Endereço IP: " & IPConfig.IPAddress(i) & vbCrLf & vbCrLf & _
				  "Sub-rede: " & IPConfig.IPSubnet(i) & vbCrLf & vbCrLf & _
			      "DNS: " & IPConfig.DNSServerSearchOrder(i) & vbCrLf & vbCrLf & _
                  "Gateway Padrão: " & IPConfig.DefaultIPGateway(i)[0]    
        Next
    End If
Next

