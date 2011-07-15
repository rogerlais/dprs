'******* CONSTANTES *******

DEST_NET = ".183."
PRIMARY_TRE_DNS = "10.12.1.5"
SECONDARY_TRE_DNS = "10.12.1.12"


'Var Globais
compIpAddress = Array("")
compGateway = Array("")
compMask = Array("255.255.255.0")
compGatewayMetric = Array(1)

strEcho = ""
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set IPConfigSet = objWMIService.ExecQuery _
    ("Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")


For Each IPConfig in IPConfigSet
    If Not IsNull(IPConfig.IPAddress) Then 
        For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)

			
			'Calcula Ip do adaptador
			compIpAddress(0) = IPConfig.IPAddress(i)
			'Teste do tipo da máquina baseado no nome
			ComputerName = IPConfig.DNSHostName
			If ( InstrRev( ComputerName, "PDC" ) <> 0 ) Then 
				'Servidor
				compDNS1 = "127.0.0.1"
				compDNS2 = PRIMARY_TRE_DNS 
				compDNS3 = SECONDARY_TRE_DNS
			Else
				If( InstrRev(ComputerName, "WKS" ) <> 0 ) Then 
					'Estação dominio				
					compDNS1 = Left( compIpAddress(0) , InStrRev(compIpAddress(0), "." ) ) & "130" 	
					compDNS2 = PRIMARY_TRE_DNS 
					compDNS3 = SECONDARY_TRE_DNS
				Else 
					'Estacao STD
					compDNS1 = PRIMARY_TRE_DNS 
					compDNS2 = SECONDARY_TRE_DNS
					compDNS3 = Null
				End If
			End If

			strEcho = "Novo DNS1 = " & compDNS1 & vbCrLF & _
					"Novo DNS2 = " & compDNS2 & vbCrLF & _
					"Novo DNS3 = " & compDNS3 & vbCrLF & _
					"Nome Host = " & IPConfig.DNSHostName & vbCrLF 
					
			'Ajusta erro global
			globalRet = 0
			'Aplica as alteracoes montadas acima
			globalRet = IPConfig.SetDNSServerSearchOrder( DNSServers )
			strEcho = strEcho & "DNSs alterados retorno = "& globalRet & vbCrLf
        Next
    End If
Next

'Apresenta a saida do processamento total acima para o caso de erro
If globalRet <> 0 then
	WScript.Echo "Falha na operação." & vbCrLf & StrEcho & vbCrLf & "Código de erro:" & globalRet
End If