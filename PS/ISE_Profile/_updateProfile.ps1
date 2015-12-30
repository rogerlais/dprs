function scriptRoot{ 

    [OutputType([String])] 
    param()
    
    return [string] (Split-Path $MyInvocation.ScriptName -Parent)
}

#Copiar script de incialização do ISE para o perfil do usuário
[string] $src = "$(scriptRoot)\Microsoft.PowerShellISE_profile.ps1"
[string] $dest = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1"
New-Item -ItemTyp File -Force -Path $dest -Confirm | out-null
Copy-Item -Path $src -Destination $dest -Force | out-null
