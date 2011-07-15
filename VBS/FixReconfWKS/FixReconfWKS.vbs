'******* CONSTANTES *******
'DNS_SEDE_PREFIX = "TRE-PB.GOV.BR"
DNS_SEDE_PREFIX = "teste.vbs.GOV.BR"

'Var Globais
Dim WshShl, currentDomain

Set WshShl = WScript.CreateObject("WScript.Shell")
set Shell = WshShl.Environment("User")

currentDomain = Shell("USERDNSDOMAIN")

WScript.RegWrite "HKLM\System\CurrentControlSet\Services\TCPIP\Parameters\SearchList", DNS_SEDE_PREFIX & "," & currentDomain, "REG_SZ"

'Apresenta a saida do processamento total acima para o caso de erro
If globalRet <> 0 then
	WScript.Echo StrEcho
End If