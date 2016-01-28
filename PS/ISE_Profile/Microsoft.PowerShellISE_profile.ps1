<#
.Synopsis
   Caminho do script corrente
.DESCRIPTION
   Nome do script ao qual esta rotina est� inserida(n� pode ser deslocada para nenhum m�dulo, sob pena de retornar o caminho do m�dulo
#>
function scriptFile{
    return $MyInvocation.ScriptName
}


<#
 # Vari�veis Globais
#>
$LIB_HOME = "C:\Sw\WorkDir\dprs\PS\AddOns\"


<#
 ==================================================================================================================================
 In�cio do m�dulo
 ==================================================================================================================================
#>
Clear
#Ajusta o caminho dos m�dulos para a serss�o do ISE
if( ! $env:PSModulePath.Contains($LIB_HOME) ){
    $env:PSModulePath+=";$LIB_HOME"
}

Write-Host "Novo ambiente configurado:" -ForegroundColor DarkYellow
Write-host "`$env:PSModulePath=" -ForegroundColor Yellow -NoNewline
Write-Host "$env:PSModulePath" -ForegroundColor DarkYellow
Write-Host "Extens�es carregadas do perfil do usu�rio a partir de: " -ForegroundColor DarkYellow -NoNewline
Write-Host $(scriptFile)  -ForegroundColor Yellow

#Carga dos m�dulos da biblioteca
Remove-Module PSLog -ErrorAction SilentlyContinue
Unblock-File -Path "$LIB_HOME\PSLog\PSLog.psm1"  #! tentar levar isso para o PSD1/PS1 ou o PSM1 mesmo
Import-Module ( Join-Path $LIB_HOME -ChildPath "PSLog" )
Remove-Module sesop -ErrorAction SilentlyContinue
Import-Module ( Join-Path $LIB_HOME -ChildPath "sesop" )

$Host.UI.WriteWarningLine( "M�dulos carregados pelo perfil do operador:" )
Get-Module
