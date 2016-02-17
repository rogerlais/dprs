clear
$credential=$null
$pc = "ZPB015WKS01.zne-pb001.gov.br"
#$pc = "pb025889"

if ($credential -eq $null) {
    $credential = Get-Credential zne-pb001\suporte
    #$credential = Get-Credential tre-pb\roger
}
#$result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StopService()
$result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StartService()
Write-Host (" - WinVNC: {0}" -f (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")} | Select-Object -ExpandProperty State))
