clear
#$pc = "ZPB062WKS05.zne-pb001.gov.br"
$pc = "10.183.201.151"

if ($credential -eq $null) {
    $credential = Get-Credential zne-pb001\suporte
}
#$result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StopService()
$result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StartService()
Write-Host (" - WinVNC: {0}" -f (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")} | Select-Object -ExpandProperty State))
