<#
.Synopsis
   Descrição resumida
.DESCRIPTION
   Descrição longa
.EXAMPLE
   Exemplo de como usar este cmdlet
.EXAMPLE
   Outro exemplo de como usar este cmdlet
#>
function Update-SADPTreinaShortcut()
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([boolean])]
    Param
    (
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
        [string] $target,

        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=1)]
        [string] $icon,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=2)]
        [boolean] $debugStep

    )
    $fileLinkFinal= Join-Path $env:PUBLIC "Desktop\Acesso Treina.lnk"
    $fileLink= Join-Path $env:TEMP "Acesso Treina.lnk"
    if( Test-Path $fileLink ){
        Remove-Item $fileLink -Force
    }
    $WshShell = New-Object -comObject WScript.Shell    
    $Shortcut = $WshShell.CreateShortcut( $fileLink )
    $Shortcut.TargetPath = $target
    $Shortcut.IconLocation=$icon
    $Shortcut.Save()    
    try{
        Copy-Item -Path $fileLink -Destination $fileLinkFinal -Force
        return $true
    } catch {
        if( $debugStep ){
            return $true
        }else{
            throw "Erro criando atalho na área de trabalho pública $_.Exception.Message"    
        }
    }
}

<#
.Synopsis
   Monta conjunto de arquivos para instância do Acesso-Treina
.DESCRIPTION
   * Requer TNSNames atualizado para funcionar
   * Usa como Fonte uma instância funcional do acesso cliente
#>
function Update-AcessoTreinaFiles
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Instancia funcional do acesso cliente
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=0)]
        [string] $acessoDir,

        # Caminho com arquivos de configuração para acesso-treina
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=1)]
        $configFilesDir,

        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=2)]
        [string] $acessoTreinaDir
    )
    #Copia arquivos de fonte para destino
    if( Test-Path -LiteralPath $acessoTreinaDir ){ #Destino ja existe, e agora?
        Copy-Item "$acessoDir\*.*" "$acessoTreinaDir" -recurse -Force
        Copy-Item "$acessoDir\*" "$acessoTreinaDir" -recurse -Force
    }else{
        Copy-Item $acessoDir $acessoTreinaDir -Container -recurse -Force
    }
    Copy-Item ( Join-Path $configFilesDir "AcessoCli.ini" ) ( Join-Path $acessoTreinaDir "AcessoCli.ini") 
    Copy-Item ( Join-Path $configFilesDir "Atualizador.ini" ) ( Join-Path $acessoTreinaDir "Atualizador.ini")
    Copy-Item ( Join-Path $configFilesDir "SADP-TREINA.ico" ) ( Join-Path $acessoTreinaDir "SADP-TREINA.ico")
}

<#
.Synopsis
   Atualiza os descritores de conexão sobrescrevendo o arquivo
.DESCRIPTION
   Arquivo contido em /AppData da SESOP
#>
function Update-TNSNames
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([boolean])]
    Param
    (
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=0)]
        [string] $sourceDir,

        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=1)]
        [string] $destDir
    )
    #apenas copia origem -> destino
    $source = Join-Path $sourceDir "tnsnames.ora"
    $dest = Join-Path $destDir "tnsnames.ora"
    New-Item -Path $destDir -ItemType Directory -Force | Out-Null
    try{
        Copy-Item -LiteralPath $source -Destination $dest -Force -ErrorAction Stop
        return $true
    }catch{
        Throw "TNSNames não pode ser copiado: $_.Exception.Message"
    }    
}

<#
.Synopsis
   Extrai os arquivos do zip para a pasta informada
.DESCRIPTION
   Descrição longa
#>
function extractFiles{
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=0)]
        [string] $destDir,
        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$false, Position=1)]
        [string] $zipFile
    )
    $ret=$destDir  #Salva antecipadamente o retorno
    if( ! (Test-Path -LiteralPath $destDir -PathType Container)){
        New-Item -Path $destDir -ItemType directory -Force #origem da bronca aqui
        if( ! (Test-Path $destDir -PathType Container )){
            throw "Falha criando pasta temporária de referência: $destDir"
        }
    }else{ #Apaga conteudo anterior para limpeza de versão antiga prévia
        Remove-Item "$destDir\*.*" -Force -Recurse
        Remove-Item "$destDir\*" -Force -Recurse
    }
    try{            
        try{
            Unzip-File -File $zipFile -Destination "$destDir" -ForceCOM | Out-Null
            return $ret
        }catch{
            Write-Host "Erro descompactando arquivos... $Error"
            return $null
        }            
    }catch{
        return $null        
    }    
}

<#
.Synopsis
   Baixa e descompacta arquivos a serem usados no processo
.DESCRIPTION
   Formato de compressão obrigatoriamente ZIP no momento
.EXAMPLE
   Outro exemplo de como usar este cmdlet
#>
function loadDataFiles{                 
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    Param
    (
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$False, ValueFromPipeline=$False, Position=0)]
        [string] $zipURL,
        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$False, ValueFromPipeline=$False, Position=1)]
        [string] $destFolder
    )
    if( !$destFolder ){
        $resultDir=$env:TEMP
    }else{
        $resultDir = $destFolder
    }
    $ret=$resultDir  #Salva antecipadamente o retorno
    if( !( Test-Path $resultDir ) ){ #Criar destino        
        New-Item -Path $resultDir -ItemType Directory -Force
    }         
    $zipFile=downloadDataFile -destDir $resultDir -urlFile $zipURL
    if( $zipFile ){             
        try{
            $resultDir = $resultDir + "\DataFiles"
            $ret = $resultDir
            $test = ( extractFiles -destDir $resultDir -zipFile $zipFile ) 
            if( $test ){  #Todos os arquivos localmente disponiveis para a operação
                $ret  #Tentativa de colocar no pipeline
                return $ret
                <#
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                return "$ErrorMessage `n`r $FailedItem"
                #>
            }else{
                throw "Erro abrindo arquivos de configuração baixados"
            }
        } catch {
            throw "Erro durante descompressão/abertura dos arquivos $_.Exception.Message $_.Exception.ItemName"
        }
    }else{
        throw "Falha na operação de download"
    }
}

function downloadDataFile(){
    [CmdletBinding()]
    [Alias()]
    [OutputType([string])]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String] $destDir,
 
        [Parameter(Position=1)] [ValidateNotNullOrEmpty()]
        [System.String] $urlFile
 
    )
    try{
        $result = $destDir + "\" + $urlFile.Substring( $urlFile.LastIndexOf("/") + 1 )
        $client = new-object System.Net.WebClient
        $client.DownloadFile( $urlFile, $result )
        if( Test-Path $result -PathType Leaf ) {#retorna se arquivo baixado existe
            return $result
        }else{
            return $null
        }
    } catch {            
        return $null
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
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)] 
        <#
        [ValidateScript({ 
            If ((Test-Path -Path $_ -PathType Leaf) -and ($_ -like "*.zip")) { 
                $true 
            } 
            else { 
                Throw "$_ is not a valid zip file. Enter in 'c:\folder\file.zip' format" 
            } 
        })] 
        ROGER Desespero #>
        [string]$File, 
 
        [ValidateNotNullOrEmpty()] 
        <# ROGER Desespero 
        [ValidateScript(
            { If (Test-Path -Path $_ -PathType Container) { 
                $true 
            } 
            else { 
                Throw "$_ is not a valid destination folder. Enter in 'c:\destination' format" 
            } 
        })] 
        #>
        [string]$Destination <#= (Get-Location).Path  ROGER despero#>, 
 
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

$DEBUG=( "PB037677" -contains $env:COMPUTERNAME ) #PC Roger
$ACESSOTREINADIR = "D:\AplicTRE\Acesso-Treina"
$ACESSODIR = "D:\AplicTRE\AcessoCliente"
$ACESSODIR_DBG ="D:\AplicTRE\Justica_Eleitoral\AcessoCliente"
$URL_DATAFILE = "http://arquivos.tre-pb.gov.br/setores/sesop/AppData/SADP-TREINA/configfiles.zip"
$ORACLE_CLIENT = "D:\AplicTRE\Oracle11g\product\11.2.0\client_1"
$ORACLE_NET_CONFIG = "$ORACLE_CLIENT\NETWORK\ADMIN"
    
### ---------------------------   Ponto de entrada da execução remota  ------------------------------------------------
Clear
$Error.Clear()
$sbReturn = new-object PSCustomObject –property @{ operationResult = "Erro desconhecido"  }  #Retorna ultima entrada do array    
$innerResult=@([string] "Erro desconhecido")
$sbReturn.operationResult = $innerResult.GetValue( 0 )
$destFolder=$env:TEMP + "\SESOP.RemoteUpd"
Try{            
    $baseDir = (loadDataFiles -zipURL $URL_DATAFILE -destFolder $destFolder)  #Fazendo uma segunda chamado o retorno sempre será o esperado
    if( $baseDir.GetType().Name -ne "String" ){  ####Maluqice sem tamanho ainda sem soluçao. Por desespero, testa-se o tipo para correção
        if( $baseDir.GetType().Name -ne "Object[]" ){
            Throw "Tipo de retorno para disponibilização dos dados incompatível com os valores esperados"
        }else{
            $baseDir=$baseDir[1]
        }
    }    
    Update-TNSNames -sourceDir ( $baseDir ) -destDir $ORACLE_NET_CONFIG
    if( $DEBUG ){
        Update-AcessoTreinaFiles -acessoDir $ACESSODIR_DBG -configFilesDir $baseDir -acessoTreinaDir $ACESSOTREINADIR
    }else{
        Update-AcessoTreinaFiles -acessoDir $ACESSODIR -configFilesDir $baseDir -acessoTreinaDir $ACESSOTREINADIR        
    }
    Update-SADPTreinaShortcut -target ( Join-Path $ACESSOTREINADIR "Atualizador.exe" ) -icon ( Join-Path $ACESSOTREINADIR "SADP-TREINA.ico"  ) -debugStep $true
    $innerResult = $baseDir
    $innerResult=@([string] "OK")
    $sbReturn.operationResult = "OK"
} catch {
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    $innerResult[0] = "$ErrorMessage `n`r $FailedItem"
}finally{
    Remove-Item -Path $destFolder -Force -Recurse #Apaga arquivos temporários
    Write-Verbose "Escrevendo o retorno da chamada remota"        
    $sbReturn.operationResult = $innerResult.GetValue( $innerResult.Length-1)
}
return $sbReturn  #objeto de retorno 
