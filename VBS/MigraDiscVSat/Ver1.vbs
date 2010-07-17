vsatIpAddress = Array("")
vsatGateway = Array("")
vsatMask = Array("255.255.255.0")
vsatGatewayMetric = Array(1)


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
            strEcho = "IP antigo = " & oldIpAddress & vbCrLF & _
					"Novo IP = " & vsatIpAddress(0) & vbCrLF & _
					"Novo Gateway = " & vsatGateway(0) & vbCrLF 
			If StrComp( vsatIpAddress(0), oldIpAddress, vbTextCompare ) <> 0 Then 
				ret = IPConfig.EnableStatic( vsatIpAddress, vsatMask )
				strEcho = strEcho & "endereco alterado retorno = "& ret & vbCrLf
				ret = IPConfig.SetGateways( vsatGateway, vsatGatewayMetric )
				strEcho = strEcho & "gateway alterado retorno = "& ret & vbCrLf
			End If
			 
			'IPConfig.IPSubnet(i) & vbCrLf & vbCrLf & _
			'IPConfig.DNSServerSearchOrder(i) & vbCrLf & vbCrLf & _
            'IPConfig.DefaultIPGateway(i)[0]    
        Next
    End If
Next
WScript.Echo StrEcho