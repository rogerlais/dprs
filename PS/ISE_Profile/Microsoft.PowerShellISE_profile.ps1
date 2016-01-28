<#
.Synopsis
   Caminho do script corrente
.DESCRIPTION
   Nome do script ao qual esta rotina está inserida(nõ pode ser deslocada para nenhum módulo, sob pena de retornar o caminho do módulo
#>
function scriptFile{
    return $MyInvocation.ScriptName
}


<#
 # Variáveis Globais
#>
$LIB_HOME = "C:\Sw\WorkDir\dprs\PS\AddOns\"


<#
 ==================================================================================================================================
 Início do módulo
 ==================================================================================================================================
#>
Clear
#Ajusta o caminho dos módulos para a serssão do ISE
if( ! $env:PSModulePath.Contains($LIB_HOME) ){
    $env:PSModulePath+=";$LIB_HOME"
}

Write-Host "Novo ambiente configurado:" -ForegroundColor DarkYellow
Write-host "`$env:PSModulePath=" -ForegroundColor Yellow -NoNewline
Write-Host "$env:PSModulePath" -ForegroundColor DarkYellow
Write-Host "Extensões carregadas do perfil do usuário a partir de: " -ForegroundColor DarkYellow -NoNewline
Write-Host $(scriptFile)  -ForegroundColor Yellow

#Carga dos módulos da biblioteca
Remove-Module PSLog -ErrorAction SilentlyContinue
Unblock-File -Path "$LIB_HOME\PSLog\PSLog.psm1"  #! tentar levar isso para o PSD1/PS1 ou o PSM1 mesmo
Import-Module ( Join-Path $LIB_HOME -ChildPath "PSLog" )
Remove-Module sesop -ErrorAction SilentlyContinue
Import-Module ( Join-Path $LIB_HOME -ChildPath "sesop" )

$Host.UI.WriteWarningLine( "Módulos carregados pelo perfil do operador:" )
Get-Module
