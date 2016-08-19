<# RemoteUpdate
Version: 20160621
Author: Rogerlais Andrade
Usage: <scriptname> <-ScriptName <filename.ps1>> [-auto] [-skip lines]
Parameters:
    auto: Inibe o modo interativo usando os valores padrão(não renova a lista de entrada)
    Scriptname: Nome do arquivo contendo a rotina a ser invocada remotamente
    skip: número de linhas a serem saltadas

NOTAS:
    * Execução em modo interativo. Pode coletar todas os computadores que pertençam a classe WKS do domínio para alimentar o arquivo "InputPCList.txt", localizado na mesma pasta do script.
    * As credenciais devem ser do suporte do domínio para o uso interativo
    * Os diálogos chamados de modos simples, impedem que sejam exibidos como janela topo, assim atenção para tais janelas.
Funcionamento(modo interativo):
    1 - Pergunta se deseja regerar a lista de estações ou usar a preexistente
    2 - Pergunta se deve-se saltar um determinado número de linhas(útil para execução interrompida)
    3 - Varre as linhas do arquivo de entrada e para cada nome de host, inicialmente tenta-se localizar-lo no arquivo de hosts a igonorar("IgnorePCList.txt"), o qual é alimentando quando houver uma execução com sucesso ou inserção manual.
    4 - Caso o host não deva ser ignorado, segue:
    4.1 Inicia uma sessão remota na qual o arquivo passado será invocado
    4.2 - Havendo sucesso na operação anterior returna cadeia "OK", indicando que o host será inserido no arquivo de host a ignorar no futuro

Problemas enfrentados:
    1 - A registrar

Funcionalidades não implementadas:
    1 - Simular o registro da instalação do pacote seguro equivalente(requer aprovação da equipe), ou ainda usar isso como filtro para a execução(idem).

Histórico:
    20160621 -  Versão inicial
#>

$debugClientScript = {  #Ignorar serve apenas para depuração
    $sbReturn = new-object PSCustomObject –property @{ operationResult = "Erro desconhecido"  }  #Retorna ultima entrada do array    
    $innerResult=@([string] "Erro desconhecido")
    $sbReturn.operationResult = $innerResult.GetValue( 0 )
    return $sbReturn
}

$clientScript = {
} #Fim do scriptBlock

<#---- Parte de execução local ----#>
function localExecution{
    if( $global:isDebugging ){  #execução direta pelo ISE
        return ( Invoke-Command -ScriptBlock $clientScript )
    }else{
        return ( Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock $clientScript -Credential $Global:credentials )
    }
}

function readList([string] $filename){
#Leitura da lista de estações a serem tratadas nesta invocação
#A leitura será feita de um arquivo texto com um nome por linha, caso se deseje pode-se editar tal arquivo antes da execução
    #Testar arquivo disponivel e throw caso contrario
    if( Test-Path $filename ){
        $lines =  Get-content $filename
        if( $lines ){
            return $lines
        } else {
            return ""
        }
    } else {
        throw "Arquivo com nomes de computadores não encontrado em: $filename"
    }
}

function Get-ScriptRoot{
    $ret = $MyInvocation.ScriptName
    $ret = Split-Path $ret -Parent
    Write-Host "Executando em $ret"
    return $ret
}


<#
.Synopsis
   Registra o retorno da operação para determinado computador
.DESCRIPTION
   Para sucesso: registra nome do PC na lista a ignorar
   Para insucesso: registra apenas no log de operações
#>
function registerResult(){
    [CmdletBinding()]
    param(
 
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $pcName,
 
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $operResult,

        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Boolean]
        $success
 
    )      
    $nbName = $pcName.Split('.')[0] #Pega apenas o hostname(parte que interessa)    
    if( $success ){
        Add-Content $Global:ignoreFilename $nbName  #Passa a ignorar este computador
    }
    #Registra no log de operações
    $logLine = "$nbName=" + (Get-Date).ToString( "yyyyMMddhhmmss" ) + "-:-$operResult"
    if(! (Test-Path $Global:logFilename) ){
        Set-Content $Global:logFilename $logLine
    }else{
        Add-Content $Global:logFilename $logLine
    }    
}


<#
.Synopsis
    ATENÇÃO: Rotina a ser chamada pelo console do ISE
   Gera lista de computadores cujo nome indique se tratar de uma estação de trabalho
.DESCRIPTION
   Todo o dompinio será pesquisado
.EXAMPLE
   Get-DomainComputerList 
#>
function Get-DomainComputerList
{
    [CmdletBinding()]
    #[OutputType([void)]
    Param
    (
        # Domínio para pesquisa
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        # Full path para arquivo de saída
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutFilename
    )
    Process {

        ####### tentativa $domaininfo = new-object DirectoryServices.DirectoryEntry("LDAP://192.168.200.2/cn=sites,cn=configuration,dc=example,dc=com","example\high","PaSS")

        $strCategory = "computer"
        [System.DirectoryServices.DirectoryEntry] $objDomain = New-Object System.DirectoryServices.DirectoryEntry                 
        $objDomain.distinguishedName="DC=zne-pb001,DC=gov,DC=br"
        $objDomain.Username="suporte@zne-pb0001.gov.br"
        $objDomain.Password="$!$adm!n"
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher( $objDomain )        
        $objSearcher.SearchRoot = $objDomain
        $objSearcher.SearchRoot.name=$DomainName
        $objSearcher.Filter = ("(objectCategory=$strCategory)") #!Colocar o filtro do nome das estações na consulta

        $colProplist = "name"
        foreach ($i in $colPropList){
            $objSearcher.PropertiesToLoad.Add($i) | Out-Null #out-null para capturar retorno indesejável
        }

        [System.DirectoryServices.SearchResultCollection] $colResults = $objSearcher.FindAll()
        if( Test-Path $OutFilename ){
            Clear-Content $OutFilename #**Zera todo o conteúdo anterior
        }else{
            Set-Content $OutFilename $null
        }
        foreach ($objResult in $colResults){
            $objComputer = $objResult.Properties            
            if( (([string]($objComputer.name)).toUpper()).Contains("WKS") ){ #***Apenas as WKS interessam
                Add-Content $OutFilename (([string]($objComputer.name)).toUpper())
            }
        }

    }
}


<#
.Synopsis
   Processa instruções para computador elegido
.DESCRIPTION
   Abre sessão remota e em sucesso executa o script remoto. Havendo retorno OK - Registra nome do computador na lista de PCs a ignorar para nova execução
#>
function Do-ProcessPC{
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param
    (
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, Position=0)]
        $fqnHost,

        #Bloco a ser executado remotamente
        [Parameter(Mandatory=$true, Position=0)]
        $clientScript

    )

    Begin {
        #Grafia de entrada
        Write-Host "Verficando $fqnHost ..."
    }
    Process {
        $Error.Clear()  #Limpa erros anteriores
        if( Test-Connection  -ErrorAction SilentlyContinue -ComputerName $fqnHost -Count 3 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 1 ){  #!alternativa Test-WSMan
            Write-Host "Computador $fqnHost ativo, tentando realizar atualização...."
            try{
                $psRemSession = new-pssession -computername $fqnHost -Credential $Global:credentials -ErrorAction SilentlyContinue
                if( $psRemSession ){                                                
                    try{                        
                        $remoteResult = ( Invoke-Command -session $psRemSession -ScriptBlock $clientScript -Verbose )  
                        return $remoteResult #Devolve retorno da execução remota(tipo deve ser igual sempre)
                    }finally{
                        Remove-PSSession -Session $psRemSession
                    }
                }else{
                    Write-Host "roger remota para $fqnHost falhou!" -ForegroundColor DarkRed
                    return new-object PSCustomObject –property @{ operationResult = ("Estação não responde a pedido de sessão remota." + $Error[0].Exception) }
                }
            }catch{
                if( !$psRemSession ){
                    return new-object PSCustomObject –property @{ operationResult = ("Sessão remota não pode ser estabelecida:" + $Error[0].Exception) }
                }
            }
        }else{            
            Write-Host "Computador $fqnHost inativo"
            if( $Error[0].CategoryInfo.Category.Equals( [System.Management.Automation.ErrorCategory]::ResourceUnavailable <#InvalidOperation talvez entre aqui#>  ) ){
                return new-object PSCustomObject –property @{ operationResult = ("Estação não responde ou desligada:" + $Error[0].Exception) }
            }else{
                return new-object PSCustomObject –property @{ operationResult = ("Estação não mais inexistente ou desconhecida:" + $Error[0].Exception) }
            }
        }
    }
    End{
        #Grafia de encerramento
    }
}



<#
.Synopsis
   Apresenta dálogo de pergunta binária
.DESCRIPTION
    Value  Description   
    0 Show OK button. 
    1 Show OK and Cancel buttons. 
    2 Show Abort, Retry, and Ignore buttons. 
    3 Show Yes, No, and Cancel buttons. 
    4 Show Yes and No buttons. 
    5 Show Retry and Cancel buttons.
.EXAMPLE
   Get-BooleanAnswer( "Deseja realmente continuar?", "Responda:" )
#> 
function Get-BooleanAnswer{

    [CmdletBinding()]
    [OutputType([Boolean])]
    Param
    (
        # Detalhe do prompt a ser exibido
        [Parameter(Mandatory=$true, Position=0)]
        [string]
        $prompt,

        # Título do diálogo
        [Parameter(Mandatory=$true, Position=1)]
        [string]
        $caption
    )
    $a = new-object -comobject wscript.shell 
    $intAnswer = $a.popup( $prompt, 0, $caption ,4) 
    If ($intAnswer -eq 6) { 
        return $true
    } else { 
        return $false
    } 
}



######  Globals Vars   ######

### ALERTA: Flag de depuração ###
$Global:isDebugging = $true

$Global:credentials   #Credenciais para invocação remota
$Global:inputList = @() #array com nomes dos computadores
$Global:ignoreList #array com nomes dos computadores a serem ignorados
$Global:curPCName #nome do computador atualmente em processamento
$Global:INPUT_PC_LIST = "InputPCList.txt"  #nome do arquivo na pasta do script com nomes dos PCs para processamento
$Global:IGNORE_PC_LIST = "IgnorePCList.txt" #nome do arquivo na pasta do script com nomes dos PCs para ignorar(execução com sucesso insere entrada neste)
$Global:DEFAULT_ZNE_DOMAIN = "ZNE-PB001.GOV.BR" #domínio MS da operação das estações
$Global:DEFAULT_ZNE_ADMIN_USER = "$Global:DEFAULT_ZNE_DOMAIN\suporte" #Conta padrão para invocação remota
$Global:inputFilename #FullPath para arquivo de nomes de entrada
$Global:ignoreFilename #FullPath para aquivo de nomes para ignorar
$Global:logFilename #FullPath para arquivo com resumo das operações
[int] $Global:HostCountOffset = 0

###Parametros de linha de comando
$Global:ParamSkipLines = $null
$Global:ParamScriptNames = $null
$Global:ParamAutoFlag = $null


#Main
Clear
$Error.Clear()
$basePath = Get-ScriptRoot
if( ! $Global:credentials ){
    $Global:credentials = Get-Credential -UserName $Global:DEFAULT_ZNE_ADMIN_USER -Message "Credenciais de conta administrativa do domínio dos computadores" 
}
try{
    $Global:inputFilename = "$basePath\$Global:INPUT_PC_LIST"
    $Global:ignoreFilename = "$basePath\$Global:IGNORE_PC_LIST"    
    if( !( Get-BooleanAnswer -prompt "Deseja manter a lista de computadores alvo?`n`rRespondendo ""NÃO"", uma lista com todas as estações do domínio será gerada." -caption "Responda!" )){
        Get-DomainComputerList -DomainName "zne-pb001.gov.br" -OutFilename $Global:inputFilename 
    }

    $Global:logFilename = "$basePath\ExecScript.log"
    $Global:inputList = readList( $Global:inputFilename )
    $Global:ignoreList = readList( $Global:ignoreFilename ) 
} catch {    
    Write-Error "Lista de nomes dos computadores não pode ser carregada: $Error[0].Exception.toString()"
    Write-Error "Execução será abortada"
    Exit
}

$pcCount=0

try{
    #Leitura do offset de linhas a ignorar 
    Write-Host "Janela de diálogo apresentada - Verifique janelas por trás de outras" -ForegroundColor Yellow
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
    $tmp = [Microsoft.VisualBasic.Interaction]::InputBox("Informe a quantidade de linhas a pular na listagem (0-" + $Global:inputList.Count.ToString() + ")", "Saltos:", "0")
    $Global:HostCountOffset=[convert]::ToInt32($tmp, 10)
}catch{
    $Global:HostCountOffset=0
}

do{
    $cycleErrorCount=0  #Zera contador do ciclo
    $cycleSuccessCount=0
    Foreach( $Global:curPCName in $Global:inputList ){    
        $pcCount++
        if( $pcCount -lt $Global:HostCountOffset ){  #Pula quantidade informada(uso para interrupção forçada e reinicio de ponto de parada)
            Write-Host $pcCount.toString("000") " : $Global:curPCName - Pulado pelo salto informado($Global:HostCountOffset)"
            Continue
        }
        if( $Global:ignoreList.Contains($Global:curPCName) ){
            Write-Host $pcCount.toString("000") " : $Global:curPCName - Encontrado no arquivo de PCs a ignorar"
            continue
        }else{ #Execução para o pc não ignorado      
            Write-Host $pcCount.toString("000") " : $Global:curPCName - Em execução"  
            if( $Global:curPCName.StartsWith( "localhost" )){
                $remoteResult = localExecution
                Write-Host $remoteResult.operationResult            
            }else{
                if( ! $Global:curPCName.EndsWith($Global:DEFAULT_ZNE_DOMAIN) ){
                    $Global:curPCName+=".$Global:DEFAULT_ZNE_DOMAIN"
                }            
                $scriptFilename=Join-Path $basePath "SADPHomologa.ps1"
                $scriptFilename="D:\Temp\SADPHomologa.ps1"
                Unblock-File -Path $scriptFilename
                $sb=get-command $scriptFilename 
                $sb= $sb | select -ExpandProperty ScriptBlock 
                $remoteResult = Do-ProcessPC -fqnHost $Global:curPCName -clientScript $sb
            }
            $retStr = $remoteResult.operationResult.toString()
            if( $retStr.EndsWith( "OK" ) ){
                Write-Host $pcCount.toString("000") " : $Global:curPCName - Atualizada com sucesso!"
                Write-Host "Sucessos do ciclo = $cycleSuccessCount"
            }else{
                $cycleErrorCount++
            }
            registerResult -pcname $Global:curPCName -operResult $retStr -success $retStr.EndsWith( "OK" )         
        }
    }    
}until ($cycleErrorCount -lt 1)  #repete ciclo até não encontrar mais erros

Write-Host "Final da execução" -ForegroundColor Yellow