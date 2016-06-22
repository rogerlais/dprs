<# RemoteUpdate
Version: 20160621
Author: Rogerlais Andrade
Usage: <scriptname> <-ScriptName <filename.ps1>> [-auto] [-skip lines]
Parameters:
    auto: Inibe o modo interativo usando os valores padr�o(n�o renova a lista de entrada)
    Scriptname: Nome do arquivo contendo a rotina a ser invocada remotamente
    skip: n�mero de linhas a serem saltadas

NOTAS:
    * Execu��o em modo interativo. Pode coletar todas os computadores que perten�am a classe WKS do dom�nio para alimentar o arquivo "InputPCList.txt", localizado na mesma pasta do script.
    * As credenciais devem ser do suporte do dom�nio para o uso interativo
    * Os di�logos chamados de modos simples, impedem que sejam exibidos como janela topo, assim aten��o para tais janelas.
Funcionamento(modo interativo):
    1 - Pergunta se deseja regerar a lista de esta��es ou usar a preexistente
    2 - Pergunta se deve-se saltar um determinado n�mero de linhas(�til para execu��o interrompida)
    3 - Varre as linhas do arquivo de entrada e para cada nome de host, inicialmente tenta-se localizar-lo no arquivo de hosts a igonorar("IgnorePCList.txt"), o qual � alimentando quando houver uma execu��o com sucesso ou inser��o manual.
    4 - Caso o host n�o deva ser ignorado, segue:
    4.1 Inicia uma sess�o remota na qual o arquivo passado ser� invocado
    4.2 - Havendo sucesso na opera��o anterior returna cadeia "OK", indicando que o host ser� inserido no arquivo de host a ignorar no futuro

Problemas enfrentados:
    1 - A registrar

Funcionalidades n�o implementadas:
    1 - Simular o registro da instala��o do pacote seguro equivalente(requer aprova��o da equipe), ou ainda usar isso como filtro para a execu��o(idem).

Hist�rico:
    20160621 -  Vers�o inicial
#>

$debugClientScript = {  #Ignorar serve apenas para depura��o
    $sbReturn = new-object PSCustomObject �property @{ operationResult = "Erro desconhecido"  }  #Retorna ultima entrada do array    
    $innerResult=@([string] "Erro desconhecido")
    $sbReturn.operationResult = $innerResult.GetValue( 0 )
    return $sbReturn
}

$clientScript = {
    function installCert( [string] $repoDir ){
        try{
            $javaHome = Get-JavaPath
            $ktPath = $javaHome + "bin\keytool.exe"
            $JRECerts = $javaHome + "lib\security\cacerts"
            $argsKTDel = " -delete -keystore " + """$JRECerts""" + " -alias biometria-applet-b -file " + """$repoDir\biometria-applet-secad-sti-tse-b.cer""" + " -storepass changeit -noprompt"
            $argsKTIns = " -import -keystore " + """$JRECerts""" + " -alias biometria-applet-b -file " + """$repoDir\biometria-applet-secad-sti-tse-b.cer""" + " -storepass changeit -noprompt"

            #cria��o de processo
            $ps = new-object System.Diagnostics.Process
            $ps.StartInfo.Filename = """$ktPath"""    
            $ps.StartInfo.RedirectStandardOutput = $True
            $ps.StartInfo.UseShellExecute = $false

            #Invoca��o para apagar certificado anterior caso exista
            $ps.StartInfo.Arguments = $argsKTDel
            $ps.start()
            $ps.WaitForExit()    
            [string] $Out = $ps.StandardOutput.ReadToEnd();
            Write-Debug $ps.ExitCode  #Acesso negado ou outros erros n�o tratados, desde que haja sucesso na importa��o logo abaixo
            Write-Debug $Out

            #Invoca��o para inserir certificado novo 
            $ps.StartInfo.Arguments = $argsKTIns
            $ps.start()
            $ps.WaitForExit()    
            [string] $Out = $ps.StandardOutput.ReadToEnd();
            Write-Debug $ps.ExitCode
            Write-Debug $Out
            if( $ps.ExitCode -eq 0 ){
                return "OK"
            }else{
                if( $out.Contains( " o alias <biometria-applet-b> j� existe" ) ){  #Certificado preexistente -> sem erro ?
                    return "OK"
                }else{
                    return $Out
                }
            }
        }catch{
            Write-Host "Erro durante execu��o de script java $Error"
        }
    }

    function Get-JavaPath{
		#Captura caminho para as JRE prim�ria da m�quina
        $RegistrySearchPaths = @('HKLM:\SOFTWARE\JavaSoft\Java Runtime Environment\', 
                                 'HKLM:\SOFTWARE\Wow6432Node\JavaSoft\Java Runtime Environment\')
        $JavaExePath = $RegistrySearchPaths | where { Test-Path $_ } |
            % {
                $CurrentVersion = (Get-ItemProperty $_).CurrentVersion
                Write-Debug "Current Java version is $CurrentVersion, based on $($_)"
                $VersionKey = Join-Path $_ $CurrentVersion
                $JavaHomeBasedPath = Join-Path (Get-ItemProperty $VersionKey).JavaHome $JavaExeSuffix
                Write-Debug "Testing for $JavaHomeBasedPath, based on $VersionKey\JavaHome"
                if (Test-Path $JavaHomeBasedPath) { $JavaHomeBasedPath }
            } |
            select -First 1
        if ($JavaExePath -ne $null) {
            Write-Debug "Found $JavaExePath"
            return $JavaExePath
        }
    }

    function downloadConfigFile(){

        [CmdletBinding()]
        param(
 
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $repoDir,
 
            [Parameter(Position=1)]
            [ValidateNotNullOrEmpty()]
            [System.String]
            $urlCert
 
        )# param end        
        try{
            $tempFile = "$env:TEMP\cert-applet.zip"  
            $client = new-object System.Net.WebClient
            $client.DownloadFile( $urlCert, $tempFile )
            $certFile = "$repoDir\sesop.zip"
            Copy-Item $tempFile $certFile -Force
            return ( Test-Path $certFile -PathType Leaf ) #retorna se arquivo baixado existe
        } catch {            
            return $false
        }        
    }

    function Unzip-File { 
 
    <# 
    .SYNOPSIS 
       Unzip-File is a function which extracts the contents of a zip file. 
 
    .DESCRIPTION 
       Unzip-File is a function which extracts the contents of a zip file specified via the -File parameter to the 
    location specified via the -Destination parameter. This function first checks to see if the .NET Framework 4.5 
    is installed and uses it for the unzipping process, otherwise COM is used. 
 
    .PARAMETER File 
        The complete path and name of the zip file in this format: C:\zipfiles\myzipfile.zip  
  
    .PARAMETER Destination 
        The destination folder to extract the contents of the zip file to. If a path is no specified, the current path 
    is used. 
 
    .PARAMETER ForceCOM 
        Switch parameter to force the use of COM for the extraction even if the .NET Framework 4.5 is present. 
 
    .EXAMPLE 
       Unzip-File -File C:\zipfiles\AdventureWorks2012_Database.zip -Destination C:\databases\ 
 
    .EXAMPLE 
       Unzip-File -File C:\zipfiles\AdventureWorks2012_Database.zip -Destination C:\databases\ -ForceCOM 
 
    .EXAMPLE 
       'C:\zipfiles\AdventureWorks2012_Database.zip' | Unzip-File 
 
    .EXAMPLE 
        Get-ChildItem -Path C:\zipfiles | ForEach-Object {$_.fullname | Unzip-File -Destination C:\databases} 
 
    .INPUTS 
       String 
 
    .OUTPUTS 
       None 
 
    .NOTES 
       Author:  Mike F Robbins 
       Website: http://mikefrobbins.com 
       Twitter: @mikefrobbins 
 
    #> 
 
        [CmdletBinding()] 
        param ( 
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)] 
            [ValidateScript({ 
                If ((Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.zip")) { 
                    $true 
                } 
                else { 
                    Throw "$_ is not a valid zip file. Enter in 'c:\folder\file.zip' format" 
                } 
            })] 
            [string]$File, 
 
            [ValidateNotNullOrEmpty()] 
            [ValidateScript(
                { If (Test-Path -Path $_ -PathType Container) { 
                    $true 
                } 
                else { 
                    Throw "$_ is not a valid destination folder. Enter in 'c:\destination' format" 
                } 
            })] 
            [string]$Destination = (Get-Location).Path, 
 
            [switch]$ForceCOM 
        ) 
 
 
        If (-not $ForceCOM -and ($PSVersionTable.PSVersion.Major -ge 3) -and 
           ((Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue).Version -like "4.5*" -or 
           (Get-ItemProperty -Path "HKLM:\Software\Microsoft\NET Framework Setup\NDP\v4\Client" -ErrorAction SilentlyContinue).Version -like "4.5*")) { 
 
            Write-Verbose -Message "Attempting to Unzip $File to location $Destination using .NET 4.5" 
 
            try { 
                [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null 
                [System.IO.Compression.ZipFile]::ExtractToDirectory("$File", "$Destination") 
            } 
            catch { 
                Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message" 
            } 
 
 
        } 
        else { 
 
            Write-Verbose -Message "Attempting to Unzip $File to location $Destination using COM" 
 
            try { 
                $shell = New-Object -ComObject Shell.Application 
                $shell.Namespace($destination).copyhere(($shell.NameSpace($file)).items()) 
            } 
            catch { 
                Write-Warning -Message "Unexpected Error. Error details: $_.Exception.Message" 
            } 
 
        } 
 
    }


    function openFiles([string] $repoDir ){
        $certFile = "$repoDir\sesop.zip"
        $destFiles = "$repoDir\sesop.tmp"
        if( ! (Test-Path $destFiles -PathType Container )){
            New-Item -Path $destFiles -ItemType directory -Force 
            if( ! (Test-Path $destFiles -PathType Container )){
                throw "Falha criando pasta tempor�ria de certificados: $destFiles"
            }
        }
        try{            
            try{
                Unzip-File -File $certFile -Destination $destFiles -ForceCOM 
            }catch{
                Write-Host "Erro descompactando arquivos... $Error"
                return $false
            }            
            $subFiles = Get-ChildItem -Path "$repoDir\sesop.tmp"                        
            foreach( $item in $subFiles ){
                if( Test-Path -Path "$repoDir\$item" ){
                    Remove-Item "$repoDir\$item" -Force
                }                
                Move-Item $item.FullName -Destination $repoDir -Force
            }
        }catch{
            return $false        
        }finally{            
            Remove-Item -Path $destFiles -Force -Recurse
            Remove-Item -Path $certFile -Force
        }
    }

    function mainProc( [string] $zipURL ){                 
        $certRepo="D:\aplic\Biometria\certificado-applet"
        if( !( Test-Path $certRepo ) ){
            return "OK - Cliente n�o necessita de atualiza��o"
        }         
        if( downloadConfigFile -repoDir $certRepo -urlCert $zipURL ){             
            try{
                if( openFiles($certRepo) ){
                    try{
                        return installCert($certRepo) 
                    } catch {
                        $ErrorMessage = $_.Exception.Message
                        $FailedItem = $_.Exception.ItemName
                        return "$ErrorMessage `n`r $FailedItem"
                    }
                }else{
                    return "Erro abrindo arquivos de configura��o baixados"
                }
            } catch {
                return "Erro durante descompress�o/abertura dos arquivos $_.Exception.Message $_.Exception.ItemName"
            }
        }else{
            return "Falha na opera��o de download"
        }
    }
    
    ####Ponto de entrada da execu��o remota
    $sbReturn = new-object PSCustomObject �property @{ operationResult = "Erro desconhecido"  }  #Retorna ultima entrada do array    
    $innerResult=@([string] "Erro desconhecido")
    $sbReturn.operationResult = $innerResult.GetValue( 0 )
    Try {        
        $innerResult = mainProc( "http://arquivos.tre-pb.gov.br/setores/sesop/AppData/Cert_Applet_ELO/cert-applet.zip" )        
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $innerResult[0] = "$ErrorMessage `n`r $FailedItem"
    } finally{
        Write-Verbose "Escrevendo o retorno da chamada remota"        
        $sbReturn.operationResult = $innerResult.GetValue( $innerResult.Length-1)
    }
    return $sbReturn  #objeto de retorno 
} #Fim do scriptBlock

<#---- Parte de execu��o local ----#>
function localExecution{
    if( $global:isDebugging ){  #execu��o direta pelo ISE
        return ( Invoke-Command -ScriptBlock $clientScript )
    }else{
        return ( Invoke-Command -ComputerName $env:COMPUTERNAME -ScriptBlock $clientScript -Credential $Global:credentials )
    }
}

function readList([string] $filename){
#Leitura da lista de esta��es a serem tratadas nesta invoca��o
#A leitura ser� feita de um arquivo texto com um nome por linha, caso se deseje pode-se editar tal arquivo antes da execu��o
    #Testar arquivo disponivel e throw caso contrario
    if( Test-Path $filename ){
        $lines =  Get-content $filename
        if( $lines ){
            return $lines
        } else {
            return ""
        }
    } else {
        throw "Arquivo com nomes de computadores n�o encontrado em: $filename"
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
   Registra o retorno da opera��o para determinado computador
.DESCRIPTION
   Para sucesso: registra nome do PC na lista a ignorar
   Para insucesso: registra apenas no log de opera��es
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
    #Registra no log de opera��es
    $logLine = "$nbName=" + (Get-Date).ToString( "yyyyMMddhhmmss" ) + "-:-$operResult"
    if(! (Test-Path $Global:logFilename) ){
        Set-Content $Global:logFilename $logLine
    }else{
        Add-Content $Global:logFilename $logLine
    }    
}


<#
.Synopsis
    ATEN��O: Rotina a ser chamada pelo console do ISE
   Gera lista de computadores cujo nome indique se tratar de uma esta��o de trabalho
.DESCRIPTION
   Todo o dompinio ser� pesquisado
.EXAMPLE
   Get-DomainComputerList 
#>
function Get-DomainComputerList
{
    [CmdletBinding()]
    #[OutputType([void)]
    Param
    (
        # Dom�nio para pesquisa
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainName,

        # Full path para arquivo de sa�da
        [Parameter(Mandatory=$true, Position=1)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $OutFilename
    )
    Process {
        $strCategory = "computer"
        [System.DirectoryServices.DirectoryEntry] $objDomain = New-Object System.DirectoryServices.DirectoryEntry
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher        
        $objSearcher.SearchRoot = $objDomain
        $objSearcher.SearchRoot.name=$DomainName
        $objSearcher.Filter = ("(objectCategory=$strCategory)") #!Colocar o filtro do nome das esta��es na consulta

        $colProplist = "name"
        foreach ($i in $colPropList){
            $objSearcher.PropertiesToLoad.Add($i) | Out-Null #out-null para capturar retorno indesej�vel
        }

        [System.DirectoryServices.SearchResultCollection] $colResults = $objSearcher.FindAll()
        if( Test-Path $OutFilename ){
            Clear-Content $OutFilename #**Zera todo o conte�do anterior
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
   Processa instru��es para computador elegido
.DESCRIPTION
   Abre sess�o remota e em sucesso executa o script remoto. Havendo retorno OK - Registra nome do computador na lista de PCs a ignorar para nova execu��o
#>
function Do-ProcessPC{
    [CmdletBinding()]
    [OutputType([System.Object])]
    Param
    (
        # Descri��o da ajuda de par�m1
        [Parameter(Mandatory=$true, Position=0)]
        $fqnHost
    )

    Begin {
        #Grafia de entrada
        Write-Host "Verficando $fqnHost ..."
    }
    Process {
        $Error.Clear()  #Limpa erros anteriores
        if( Test-Connection  -ErrorAction SilentlyContinue -ComputerName $fqnHost -Count 3 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 1 ){  #!alternativa Test-WSMan
            Write-Host "Computador $fqnHost ativo, tentando realizar atualiza��o...."
            try{
                $psRemSession = new-pssession -computername $fqnHost -Credential $Global:credentials -ErrorAction SilentlyContinue
                if( $psRemSession ){                                                
                    try{                        
                        $remoteResult = ( Invoke-Command -session $psRemSession -ScriptBlock $clientScript -Verbose )  
                        return $remoteResult #Devolve retorno da execu��o remota(tipo deve ser igual sempre)
                    }finally{
                        Remove-PSSession -Session $psRemSession
                    }
                }else{
                    Write-Host "Sess�o remota para $fqnHost falhou!"
                    return new-object PSCustomObject �property @{ operationResult = ("Esta��o n�o responde a pedido de sess�o remota." + $Error[0].Exception) }
                }
            }catch{
                if( !$psRemSession ){
                    return new-object PSCustomObject �property @{ operationResult = ("Sess�o remota n�o pode ser estabelecida:" + $Error[0].Exception) }
                }
            }
        }else{            
            Write-Host "Computador $fqnHost inativo"
            if( $Error[0].CategoryInfo.Category.Equals( [System.Management.Automation.ErrorCategory]::ResourceUnavailable <#InvalidOperation talvez entre aqui#>  ) ){
                return new-object PSCustomObject �property @{ operationResult = ("Esta��o n�o responde ou desligada:" + $Error[0].Exception) }
            }else{
                return new-object PSCustomObject �property @{ operationResult = ("Esta��o n�o mais inexistente ou desconhecida:" + $Error[0].Exception) }
            }
        }
    }
    End{
        #Grafia de encerramento
    }
}



<#
.Synopsis
   Apresenta d�logo de pergunta bin�ria
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

        # T�tulo do di�logo
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

### ALERTA: Flag de depura��o ###
$Global:isDebugging = $true

$Global:credentials   #Credenciais para invoca��o remota
$Global:inputList = @() #array com nomes dos computadores
$Global:ignoreList #array com nomes dos computadores a serem ignorados
$Global:curPCName #nome do computador atualmente em processamento
$Global:INPUT_PC_LIST = "InputPCList.txt"  #nome do arquivo na pasta do script com nomes dos PCs para processamento
$Global:IGNORE_PC_LIST = "IgnorePCList.txt" #nome do arquivo na pasta do script com nomes dos PCs para ignorar(execu��o com sucesso insere entrada neste)
$Global:DEFAULT_ZNE_DOMAIN = "ZNE-PB001.GOV.BR" #dom�nio MS da opera��o das esta��es
$Global:DEFAULT_ZNE_ADMIN_USER = "$Global:DEFAULT_ZNE_DOMAIN\suporte" #Conta padr�o para invoca��o remota
$Global:inputFilename #FullPath para arquivo de nomes de entrada
$Global:ignoreFilename #FullPath para aquivo de nomes para ignorar
$Global:logFilename #FullPath para arquivo com resumo das opera��es
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
    $Global:credentials = Get-Credential -UserName $Global:DEFAULT_ZNE_ADMIN_USER -Message "Credenciais de conta administrativa do dom�nio dos computadores" 
}
try{
    $Global:inputFilename = "$basePath\$Global:INPUT_PC_LIST"
    $Global:ignoreFilename = "$basePath\$Global:IGNORE_PC_LIST"    
    if( !( Get-BooleanAnswer -prompt "Deseja manter a lista de computadores alvo?`n`rRespondendo ""N�O"", uma lista com todas as esta��es do dom�nio ser� gerada." -caption "Responda!" )){
        Get-DomainComputerList -DomainName "zne-pb001.gov.br" -OutFilename $Global:inputFilename 
    }

    $Global:logFilename = "$basePath\ExecScript.log"
    $Global:inputList = readList( $Global:inputFilename )
    $Global:ignoreList = readList( $Global:ignoreFilename ) 
} catch {    
    Write-Error "Lista de nomes dos computadores n�o pode ser carregada: $Error[0].Exception.toString()"
    Write-Error "Execu��o ser� abortada"
    Exit
}

$pcCount=0

try{
    #Leitura do offset de linhas a ignorar 
    Write-Host "Janela de di�logo apresentada - Verifique janelas por tr�s de outras" -ForegroundColor Yellow
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
    $tmp = [Microsoft.VisualBasic.Interaction]::InputBox("Informe a quantidade de linhas a pular na listagem (0-" + $Global:inputList.Count.ToString() + ")", "Saltos:", "0")
    $Global:HostCountOffset=[convert]::ToInt32($tmp, 10)
}catch{
    $Global:HostCountOffset=0
}


Foreach( $Global:curPCName in $Global:inputList ){    
    $pcCount++
    if( $pcCount -lt $Global:HostCountOffset ){  #Pula quantidade informada(uso para interrup��o for�ada e reinicio de ponto de parada)
        Write-Host $pcCount.toString("000") " : $Global:curPCName - Pulado pelo salto informado($Global:HostCountOffset)"
        Continue
    }
    if( $Global:ignoreList.Contains($Global:curPCName) ){
        Write-Host $pcCount.toString("000") " : $Global:curPCName - Encontrado no arquivo de PCs a ignorar"
        continue
    }else{ #Execu��o para o pc n�o ignorado      
        Write-Host $pcCount.toString("000") " : $Global:curPCName - Em execu��o"  
        if( $Global:curPCName.StartsWith( "localhost" )){
            $remoteResult = localExecution
            Write-Host $remoteResult.operationResult            
        }else{
            if( ! $Global:curPCName.EndsWith($Global:DEFAULT_ZNE_DOMAIN) ){
                $Global:curPCName+=".$Global:DEFAULT_ZNE_DOMAIN"
            }            
            $remoteResult = Do-ProcessPC -fqnHost $Global:curPCName
        }
        $retStr = $remoteResult.operationResult.toString()
        if( $retStr.EndsWith( "OK" ) ){
            Write-Host $pcCount.toString("000") " : $Global:curPCName - Atualizada com sucesso!"
        }
        registerResult -pcname $Global:curPCName -operResult $retStr -success $retStr.EndsWith( "OK" )         
    }
}
Write-Host "Final da execu��o" -ForegroundColor Yellow