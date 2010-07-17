strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")
 
For Each IPConfig in IPConfigSet
    If Not IsNull(IPConfig.IPAddress) Then 
        For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
            WScript.Echo "Nome do Host: " & IPConfig.DNSHostName & vbCrLf & vbCrLf & _
	    		 "Endereço IP: " & IPConfig.IPAddress(i) & vbCrLf & vbCrLf & _
	    		 "Sub-rede: " & IPConfig.IPSubnet(i) & vbCrLf & vbCrLf & _
			 "DNS: " & IPConfig.DNSServerSearchOrder(i) & vbCrLf & vbCrLf & _
			 "Gateway Padrão: " & IPConfig.DefaultIPGateway(i)			 
        Next
    End If
Next
