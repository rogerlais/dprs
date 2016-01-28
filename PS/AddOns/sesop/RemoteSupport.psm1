<#
 # RemoteSupport.psm1
 # Author: Rogerlais Andrade e Silva
 # Agrega rotinas para suporte remoto das estações de trabalho
#>


<#
.Synopsis
   Inicia o serviço VNC na estação especificada
.DESCRIPTION
   Recebe nome do computador e credenciais para ativar o serviço VNC na estação especificada
#>
function Set-VNCState{
    <#
    [CmdletBinding()]
    [OutputType([int])]
    Param(
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)] [string] $pc,
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1, )] [boolean] $state,
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true, Position=2)] [System.Management.Automation.PSCredential] $credential
    )

    Begin{
        if (!$credential) {
            $credential = Get-Credential zne-pb001\suporte  #! alterar para carregar outro módulo com global (lastCredential - por exemplo)
        }
    }
    Process{        
        if( $state ){
            $result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StartService()
        }else{
            $result = (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")}).StopService()
        }
        Write-Host (" - WinVNC: {0}" -f (Get-WmiObject Win32_Service -ComputerName $pc -Credential $credential -Filter {(name = "WinVNC")} | Select-Object -ExpandProperty State))
    }
    End {
        return $result
    }

    #>
}

#export-modulemember -function * -Alias *