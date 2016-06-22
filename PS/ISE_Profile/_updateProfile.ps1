<#
Instala/Atualiza o perfil PS para o usuário apenas

#>

function scriptRoot{ 

    [OutputType([String])] 
    param()
    
    return [string] (Split-Path $MyInvocation.ScriptName -Parent)
}

function Get-DestProfiles(){
    Write-Host "Escolha quais Perfis serão atualizados(separados por ',':<ENTER = Todos>"
    Write-Host "1 - %windir%\system32\WindowsPowerShell\v1.0\profile.ps1 -> This profile applies to all users and all shells"
    Write-Host "2 - %windir%\system32\WindowsPowerShell\v1.0\ Microsoft.PowerShell_profile.ps1 -> This profile applies to all users, but only to the Microsoft.PowerShell shell."
    Write-Host "3 - %UserProfile%\Documentos\WindowsPowerShell\profile.ps1 -> This profile applies only to the current user, but affects all shells."
    Write-Host "4 - %UserProfile%\Documentos\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 -> This profile applies only to the current user and the Microsoft.PowerShell shell."
    $ret = Read-Host "Opções"
    if( $ret.Equals("") ){
        $ret = "1,2,3,4"
    }
    $ret = $ret.Split(",")
    $retNumber = @(0,0,0,0)
    foreach ($item in $ret) {        
        try {
            [string] $strTemp = ([string]$item)
            [integer] $idx = $strTemp.ToInt16($null) - 1
            if( $idx ){

            }
        }
        catch {
            #Write-Host "Exceção de divisão por zero"
        }
    }
}


$optList = Get-DestProfiles

#Copiar script de incialização do ISE para o perfil do usuário
<#
[string] $src = "$(scriptRoot)\Microsoft.PowerShellISE_profile.ps1"
[string] $dest = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
New-Item -ItemTyp File -Force -Path $dest -Confirm | out-null
Copy-Item -Path $src -Destination $dest -Force | out-null
#>