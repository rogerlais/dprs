'******* CONSTANTES *******
SOURCE_NET = ".187."
DEST_NET = ".183."
PRIMARY_TRE_DNS = "10.12.1.12"
SECONDARY_TRE_DNS = "10.12.1.0"

'Var Globais
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

			'Troca cadeia do IP SOURCE_NET para DEST_NET
			oldIpAddress = IPConfig.IPAddress(i)
			vsatIpAddress(0) = Replace( oldIpAddress, SOURCE_NET, DEST_NET )
			vsatGateway(0) =  Left( vsatIpAddress(0) , InStrRev(vsatIpAddress(0), "." ) ) & "70" 

			'Teste do tipo da máquina baseado no nome
			ComputerName = IPConfig.DNSHostName
			If ( InstrRev( ComputerName, "PDC" ) <> 0 ) Then 
				'Servidor
				vsatDNS1 = "127.0.0.1"
				vsatDNS2 = PRIMARY_TRE_DNS 
				vsatDNS3 = SECONDARY_TRE_DNS
			Else
				If( InstrRev(ComputerName, "WKS" ) <> 0 ) Then 
					'Estação dominio					
					vsatDNS1 = Left( vsatIpAddress(0) , InStrRev(vsatIpAddress(0), "." ) ) & "130" 
					vsatDNS2 = PRIMARY_TRE_DNS 
					vsatDNS3 = SECONDARY_TRE_DNS
				Else 
					'Estacao STD
					vsatDNS1 = PRIMARY_TRE_DNS 
					vsatDNS2 = SECONDARY_TRE_DNS
					vsatDNS3 = Null
				End If
			End If

			strEcho = "IP antigo = " & oldIpAddress & vbCrLF & _
					"Novo IP = " & vsatIpAddress(0) & vbCrLF & _
					"Novo Gateway = " & vsatGateway(0) & vbCrLF & _
					"Novo DNS1 = " & vsatDNS1 & vbCrLF & _
					"Novo DNS2 = " & vsatDNS2 & vbCrLF & _
					"Novo DNS3 = " & vsatDNS3 & vbCrLF & _
					"Nome Host = " & IPConfig.DNSHostName & vbCrLF 
			'Ajusta erro global
			globalRet = 0
			'Aplica as alteracoes montadas acima
			If StrComp( vsatIpAddress(0), oldIpAddress, vbTextCompare ) <> 0 Then 	
				'Muda Ip do adaptador
				ret = IPConfig.EnableStatic( vsatIpAddress, vsatMask )
				globalRet = globalRet Or ret
				strEcho = strEcho & "endereco alterado retorno = "& ret & vbCrLf
				'Muda Gateway do adapatador
				ret = IPConfig.SetGateways( vsatGateway, vsatGatewayMetric ) 'Vetor vazio = metricas automaticas
				globalRet = globalRet Or ret
				strEcho = strEcho & "gateway alterado retorno = "& ret & vbCrLf
				'Muda DNS do adaptador
				If ( IsNull(vsatDNS3) ) Then 
					DNSServers = Array(vsatDNS1, vsatDNS2)
				Else
					DNSServers = Array(vsatDNS1, vsatDNS2, vsatDNS3)
				End If 
				
				ret = IPConfig.SetDNSServerSearchOrder( DNSServers )
				globalRet = globalRet Or ret

				'Reiniciar servico "VNC Server"
				Set colServiceList = objWMIService.ExecQuery("Select * from Win32_Service where Name='VNC Server'")
				For Each objService in colServiceList
					'Para servico
					retSvc = objService.stopService
					WScript.Sleep 3000
					If retSvc = 0 Then 						
						strEcho = strEcho & "VNC parado = " & retSvc & vbCrLf
					End if					
					'Inicia servico
					retSvc = objService.startService
					If retSvc = 0 Then
						strEcho = strEcho & "VNC iniciado = " & retSvc & vbCrLf
						WScript.Sleep 1000
					End if
				Next
				strEcho = strEcho & "DNSs alterados retorno = "& ret & vbCrLf
			End If
			 
			 
			'IPConfig.IPSubnet(i) & vbCrLf & vbCrLf & _
			'IPConfig.DNSServerSearchOrder(i) & vbCrLf & vbCrLf & _
            'IPConfig.DefaultIPGateway(i)[0]    
        Next
    End If
Next

'Apresenta a saida do processamento total acima para o caso de erro
If globalRet <> 0 then
	WScript.Echo StrEcho
End If