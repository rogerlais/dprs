<# dicas
Version: 20151006
Author: Roger
Usage: <scriptname> [clientname(win7)|localhost]
Altera as configurções do EDIClient e o reinicia.
As configurações são armazenadas no servidor http://arquivos.tre-pb.gov.br/setores/sesop/AppData/EDIClient/config.properties
As credenciais devem ser do suporte do domínio para o uso interativo
Alertamos que a transmissão será iniciada imediatamente após execução, causando impacto no atendimento do local
Todos os arquivos movidos para a pasta "comerro" serão repostos para nova tentativa de transmissão
#>

#Para invocar para depuração scriptname -paramName(i) paramValue(i)
param( [string]$commandPCName=$null )


$innerScript = {
    function initGlobals(){
        if( $DEBUG_MODE ){
            $global:EDICLIENT_HOME = "C:\Temp\EDIClient"
            $global:EDICLIENT_TOSEND = $EDICLIENT_HOME + "\envio\aenviar"
            $global:EDICLIENT_ERROR = $EDICLIENT_HOME + "\envio\comerro"
        }
    }

    function downloadConfigFile(){
        $url = "http://arquivos.tre-pb.gov.br/setores/sesop/AppData/EDIClient/config.properties"
        $tempFile = "$env:TEMP\config.properties"
        write-host "Arquivo temporário:$tempFile"
        $start_time = Get-Date
        Invoke-WebRequest -Uri $url -OutFile $tempFile  
        Write-host "Tempo de download: $((Get-Date).Subtract($start_time).Seconds) segundo(s)"
        $confFile = "$EDICLIENT_HOME\config.properties"
        $sufixDate = Get-Date -Format yyyyMMddHHmm
        $bakConfFile = $confFile + "." + $sufixDate
        if( Test-path $confFile ){
            Move-Item $confFile $bakConfFile
        }
        Copy-Item $tempFile $confFile
        return $true
    }


    function isEDIInstalled(){
    #Verifica se o cliente possui EDIClient instalado checando presença de diretorio como assinatura
        return Test-Path $EDICLIENT_HOME
    }

    function hasErrorBioFiles(){
    #Verifica se há arquivos a serem transmitidos que foram marcados como "com erro"
        $errorPath = $EDICLIENT_ERROR + "\*.bio"
        Write-Host "Verificando arquivos $errorPath"
        return Test-Path( $errorPath )
    }

    function resetErrorTransfer(){
    #Move todos os arquivos *.bio para a pastar aenviar
        #--testa destino OK
        if( !(Test-Path $EDICLIENT_TOSEND -PathType Container)){ #Criar a pasta
            new-item $EDICLIENT_TOSEND -type Directory -force
        }

        #$srcDir = $EDICLIENT_ERROR
        $files = (Get-Item $EDICLIENT_ERROR).GetFiles("*.bio") 
        $countFile=$files.Count

        Write-Host "Arquivos " + """ComErro""" + " recuperaodneste momento =  $countFile"
        Write-Host "Foram encontrados $countFile arquivos a serem enviados"

        foreach($fileName in $files)
        {   
            # Test if the destination folder exists and move it
            $srcFile = $EDICLIENT_ERROR + "\" + $fileName
            Move-Item -Path $srcFile -Destination $EDICLIENT_TOSEND
        }    

        $files = (Get-Item $EDICLIENT_TOSEND).GetFiles("*.bio") 
        $countFile=$files.Count

        Write-Host "Arquivos " + """AEnviar""" + " neste momento =  $countFile"


    }

    function isConfigUpdated(){
    #existindo arquivo de backup de configuração com o formato yyyymmddhhMM este computador foi atualizado para a versão seguinte
    #Rotina pode ser expandida para ser usada data de referencia
        $result = $false
        $oldPropMask = "config.properties.*"
        Write-Host "Buscando por $oldProp"
        #lista de arquivos
        $fileList = Get-ChildItem -path $EDICLIENT_HOME -filter $oldPropMask | Sort-Object extension -descending
        if( $fileList.GetType().IsArray){ #Havendo apenas arquivo original o retorno não será array
            if( $fileList.Length -gt 1 ){ #existe ao menos um backup anterior
                $lastBak=[System.IO.FileSystemInfo]$fileList[1] #Pela ordenação deve ser o backup mais recente(pula o proprio arquivo)
                $result = ( $lastBak.Extension.CompareTo( "." + $global:VERSION_DATE.ToString() ) -gt 0 )
            }        
        }
        return $result
    }

    <#
    /Ponto de entrada do script
    #>

    function CheckOS([string] $pcName){

    }
    function doRun(){
        cls 
        initGlobals
        if( $DEBUG_MODE ){
            $DebugPreference = "Continue"  #Alterna para o modo onde a saida de depuração é exibida
        }
        if( isEDIInstalled ){  #Transmissor de arquivos presentes neste computador
            if( !(isConfigUpdated) ){  #Necessário parar o serviço e atualizar a cofiguração
                if( !( downloadConfigFile ) ){
                    write-host "Novo arquivo de configuração não pode ser baixado"
                    Exit
                }
                #Reiniciar o runtime d:\aplica\biometria\ediclient\transmarqbio.exe
                $transApp = Get-Process transmarqbio
                if( $transApp ){
                    $transAppPath = $transApp.Path
                    Write-Host "Finalizando processo....`n" $transAppPath
                    Stop-Process $transApp -WarningAction Continue
                    Write-Host "Reiniciando processo.... `n" $transAppPath
                    Start-Sleep -s 5
                    $newProc=Start-Process $transAppPath
                    if($newProc){
                        Write-Host "Aplicativo de transmissão iniciado com sucesso"
                    }
                }
            }
            if( hasErrorBioFiles ){
                write-host "Existem arquivos a recuperar para novo envio"
                resetErrorTransfer    
            }else{
                Write-Host "Não foram encontrados arquivos em situação """ComErro""" neste computador"
                $sendFiles = (Get-Item $EDICLIENT_TOSEND).GetFiles("*.bio") 
                $countFile=$sendFiles.Count
                Write-Host "Arquivos  """AEnviar"""  neste momento =  $countFile"

            }
        } else { #Saida sem fazer nada
            write-host "EDIClient não instalado neste computador"
        }
        write-host "Final da execução do script"
        Exit
    }

    <# CONSTANTES E GLOBAIS #>
    $global:colectCred=$null
    $global:VERSION_DATE=201510140000  #DataHora da versão corrente
    $global:DEBUG_MODE = $false
    $global:EDICLIENT_HOME = "D:\aplic\Biometria\ediclient"
    $global:EDICLIENT_TOSEND = $EDICLIENT_HOME + "\envio\aenviar"
    $global:EDICLIENT_ERROR = $EDICLIENT_HOME + "\envio\comerro"
    doRun
}

function isWindows7( [string] $pcName ){
   $ver = Get-WmiObject -Class Win32_OperatingSystem -Namespace root/cimv2 -ComputerName $pcName
   $result  = [string] $ver.Version
   if( $result.StartsWith( "6.") ){ #6->win7
    return $true
   }else{
    return $false
   }
}

#Chamada ponto de entrada
if( !$commandPCName ) {
    write-host "Nacessário informar nome do computador para a operação"
    $commandPCName=Read-Host "Informe o nome do computador remoto para a operação"
    if( !$commandPCName ){
        $commandPCName="localhost"
    }else{
        if(!$commandPCName.EndsWith( ".zne-pb001.gov.br" ) ){
            $commandPCName = $commandPCName + ".zne-pb001.gov.br"
        }
    }
}else{
    Write-Host "Invocando ajustes para computador $commandPCName"
}
if( !$commandPCName ){
    Exit
}
$commandPCName=$commandPCName.ToUpperInvariant()
if( $commandPCName -eq "localhost".ToUpperInvariant() ){
    #Chamada para si mesmo
    Invoke-Command -ScriptBlock $innerScript
} else {
    if(!$global:colectCred){
        $global:colectCred = Get-Credential -UserName "zne-pb001.gov.br\suporte" -Message "Apenas conta suporte domínio funcional" ###Autenticação local em estudo
    }
    if( isWindows7( $commandPCName ) ){
        $psRemSession = new-pssession -computername $commandPCName -Credential $global:colectCred
        if( $psRemSession ){ 
            Write-Host "Resetando configurações do EDIClient para o computador $commandPCName"
            Invoke-Command -Session $psRemSession  -ScriptBlock $innerScript        
        }
   }else{
      write-host "Não se aplica para estações não windows 7"
   }    
}
Exit
