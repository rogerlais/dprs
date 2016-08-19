<#
# Filename: MapMirror.ps1
# Author: Roger
# Finalidade: Mapeia unidade espelho como R: para conta <domain>\instalador
# Justificativa: Facilitar acesso direto aos pacotes disponibilizados de forma automática nos compartilhamentos existentes localmente nos cartórios.
# History:
# 20160621 - Versão inicial
# 20160728 - Direcionado aos computadores perfil zona com LAN id >= 200 para o NAS da SESOP/Zonas/Espelho
# Melhorias:
# 1 - Passar rotinas Use-NetworkDrive e Get-LANId para a biblioteca comum após aplicar padrão de projeto
#>


function Use-NetworkDrive{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param(
        # Nome do computador a ser resolvido
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true, Position=0)]
        [string] $UNCPrefix,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true, Position=1)]
        [string] $ShareName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true, Position=2)]
        [string] $MapLetter,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true, Position=3)]
        [string] $Username,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true, Position=4)]
        [string] $Pwd
    )

    write-host $MapLetter, $UNCPrefix , $ShareName
    $Force = $true  ##Flag de desconexão forçada
    $UNCName = ($UNCPrefix + $ShareName)
    $net = $(New-Object -comobject WScript.Network)
    $MapLetter = $MapLetter + ":"  #Chamada pede os ":"
    $CheckDrive = $net.EnumNetworkDrives()
    if($net.EnumNetworkDrives() -contains $MapLetter){
        try {
            $net.RemoveNetworkDrive($MapLetter,$true,$False)
        }catch{
            Write-Error -Exception $_.Exception.InnerException -Message "Error removing '$MapLetter'
               $($_.Exception.InnerException.InnerException.Message)"
        }            
    } 
    if ($Username){
        $net.MapNetworkDrive($MapLetter.ToString() , $UNCName, $False, $Username, $Pwd ) 
    }else{
        $net.MapNetworkDrive($MapLetter.ToString() , $UNCName, $False )    
    }	
}


<#
.Synopsis
   Traduz a rede vinculada ao nome do computador passado
.DESCRIPTION
   Retorna o valor inteiro da rede vinculada ao nome do computador passado
.EXAMPLE
   CPB003WKSnn -> 28
   ZPB044WKSnn -> 44
#>
function Get-LANId
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param(
        # Nome do computador a ser resolvido
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true, Position=0)]
        [string] $Computername
    )
    $strLAN = $Computername.Substring(3, 3)
    try{
        if ($Computername.StartsWith("Z")){  #Computador vinculado a uma zona
            return ( [int] $strLAN )
        }else{
            switch ($strLan) {
                '001' { return 1  }
                '002' { return 16 }
                '003' { return 28 }
                '004' { return 42 }
                '005' { return 68 }
                Default { return 0 } 
            }
        }    
    }catch{
        return 0
    }
}

<# *********************************************************************************
 # Ponto de entrada do script
************************************************************************************#>

# -------------------------- Constantes e globais  ----------------------------
$DEBUGING = $True  ####!!!!!!!!!!!!!!! ALERTA - alterar para false na produção
$SERVER_PREFIX = "ZPB"
$FORUM_JPA_FILESERVER = "pbfs01.zne-pb001.gov.br"
# -----------------------------------------------------------------------------

if ($DEBUGING){
    #$compName = "CPB003WKS00"
    $compName = "ZPB077WKS00"
    $MapUser = $null
    $MapPassword = $null
}else{
    $compName = $env:COMPUTERNAME    
}

Write-Host "Host em execução: $compName"
$LANId = Get-LANId( $compName )
Write-Host "Rede local identificada como: $LANId"
if( $LANId -gt 77 ){
    if( $LANId -le 200 ){
        Write-Host "Mapeando NAS da SESOP"
        $DeviceName = "\\NAS035292\Zonas\"  #Compartilhamento do NAS da SESOP
        $MapUser = "instalador"
        $MapPassword = "12345678"
    }else{
        #Todo: Adequar para NATUs posteriormente
        Write-Host "Mapeando unidade de teste"
        $DeviceName = "\\PB037677\"  #maquina de roger
    }
    Use-NetworkDrive -UNCPrefix $DeviceName -ShareName "Espelho" -MapLetter 'R' -Username $Mapuser -Pwd $MapPassword #Alterado de "M:" para "R:"  devido aos dispositivos móveis
}else{
    switch ($LANId)
    {
        #'value1' {}
        {$_ -in 1, 64, 70, 76, 77 } {
            $DeviceName = "\\" + $FORUM_JPA_FILESERVER + "\"  #Servidor das zonas da capital
        }
       Default {
            $DeviceName = "\\" + $SERVER_PREFIX + $LANId.ToString("000") + "NAS01\"  #!Amarrado para dispositivo 01 apenas
        }
    }
    Write-Host "Mapeando unidade da rede local"    
    Use-NetworkDrive -UNCPrefix $DeviceName -ShareName "ESPELHO" -MapLetter 'R' #Alterado de "M:" para "R:"  devido aos dispositivos móveis
}