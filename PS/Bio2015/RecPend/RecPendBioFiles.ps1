﻿<#
RecPendBioFiles.ps1
Recupera os aruqivos pendentes de envio para as estações que fazem uso do EDIClient como cliente de envio.
A entrada deste script é o relatório emitido em PDF convertido em texto e salvo com o nome do arquivo <pendencias.txt>, localizado no mesmo local onde se encontra este script
#>


<#
.Synopsis
   Coleta SIM/NÃO do operador
#>
function Get-YesNoUserChoice{

    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Texto a ser questionado ao operador
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        $message
    )
    begin{
        $caption = "Escolha a opção"
        $optYes = new-Object System.Management.Automation.Host.ChoiceDescription "&Sim","Sim"
        $optNo = new-Object System.Management.Automation.Host.ChoiceDescription "&Não","Não"
        $choices = [System.Management.Automation.Host.ChoiceDescription[]]($optYes,$optNo)
        $answer = $host.ui.PromptForChoice($caption,$message,$choices,0)
        switch( $answer ) {
            0 { return $true  }
            1 { return $false }
        }
    }
}

function scriptFolder{
    $ret = $MyInvocation.ScriptName
    return Split-Path $ret -Parent
}

function loadPendFile{
    $Global:PendReportFilename = Join-Path (scriptFolder) -ChildPath "pendencias.txt"
    if( Test-Path $Global:PendReportFilename -PathType Leaf){ 
        $choice = Get-YesNoUserChoice -message "Encontrado arquivo padrão com pendências.`r`nDeseja usá-lo?"           
    }else{
        Write-Log -Message "Arquivo padrão não encontrado.`r`nPedindo o nome de um nome válido" -Level Info
        $choice = $false
    }
    if( !$choice ){  #Será pedido nome de arquivo para a fonte dos dados de entrada           
        Write-LogEntry -Message "Iniciando seleção de arquivo de entrada"
        #$Global:PendReportFilename = 
    }
    #Arquivo padrão não encontrado, pedir ao usuário para selecionar um
    Write-Verbose "Arquivo de pendências carregados de $Global:PendReportFilename"    
    $Global:PendReport = Get-Content $Global:PendReportFilename
}

<#
 ############ Globais ##################
#>
$Global:WKSList = new-object collections.hashtable #Hashtable com lista de estações
$Global:PendReport
$Global:PendReportFilename


<# ----------------- PONTO de entrada --------------------------#>
Clear
$Error.Clear()
#Garante os caminhos dos dados de entrada e de saída
try{
    $logPath = Join-Path (scriptFolder) -ChildPath "Logs"
    if( !(Test-Path -Path $logPath) ){
        New-Item -Path $logPath -ItemType directory -ErrorAction Stop  #Caminho dos logs
    }
    $timeStamp = Date
    $timeStamp = "Log" + $timeStamp.ToString("yyyyMMdd") + ".log"
    Start-Log -LogPath $logPath -LogName $timeStamp -Level All
}catch{    
    Write-Error "Caminhos para os arquivos de entrada/saída não foram inicializados`r`n Causa: $_.Exception"
    Exit
}
try{
    Write-LogEntry -message "Script iniciado - Start" -EntryType Start
    Write-LogEntry -Message "Script iniciado - information" -EntryType Information
    #Carga do arquivo com as pendências
    loadPendFile
}finally{
    Stop-Log
}
