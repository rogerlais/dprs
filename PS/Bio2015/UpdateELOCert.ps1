$clientScript = {
    function installCert( [string] $repoDir ){
        $javaHome = Get-JavaPath
        $ktPath = $javaHome + "bin\keytool.exe"
        $JRECerts = $javaHome + "lib\security\cacerts"
        $argsKTDel = " -delete -keystore " + """$JRECerts""" + " -alias biometria-applet-b -file " + """$repoDir\biometria-applet-secad-sti-tse-b.cer""" + " -storepass changeit -noprompt"
        $argsKTIns = " -import -keystore " + """$JRECerts""" + " -alias biometria-applet-b -file " + """$repoDir\biometria-applet-secad-sti-tse-b.cer""" + " -storepass changeit -noprompt"


        #criação de processo
        $ps = new-object System.Diagnostics.Process
        $ps.StartInfo.Filename = """$ktPath"""    
        $ps.StartInfo.RedirectStandardOutput = $True
        $ps.StartInfo.UseShellExecute = $false

        #Invocação para apagar certificado anterior caso exista
        $ps.StartInfo.Arguments = $argsKTDel
        $ps.start()
        $ps.WaitForExit()    
        [string] $Out = $ps.StandardOutput.ReadToEnd();
        Write-Debug $ps.ExitCode
        Write-Debug $Out

        #Invocação para inserir certificado novo 
        $ps.StartInfo.Arguments = $argsKTIns
        $ps.start()
        $ps.WaitForExit()    
        [string] $Out = $ps.StandardOutput.ReadToEnd();
        Write-Debug $ps.ExitCode
        Write-Debug $Out
        if( $ps.ExitCode -eq 0 ){
            return "OK"
        }else{
            return $Out
        }
    }

    function Get-JavaPath{
		#Captura caminho para as JRE primária da máquina
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

    function downloadConfigFile( [string] $repoDir ){
        try{
            #!Colocar abaixo como argumento 
            $url = "http://arquivos.tre-pb.gov.br/setores/sesop/AppData/Cert_Applet_ELO/cert-applet.zip"
            $tempFile = "$env:TEMP\cert-applet.zip"        
            Invoke-WebRequest -Uri $url -OutFile $tempFile
            $certFile = "$repoDir\sesop.zip"
            Copy-Item $tempFile $certFile -Force
            return $true
        } catch {
            return $false
        }
    }

    function openFiles([string] $repoDir ){
        $certFile = "$repoDir\sesop.zip"
        $destFiles = "$repoDir\sesop.tmp"
        if( ! (Test-Path $destFiles -PathType Any )){
            New-Item -Path $destFiles -ItemType directory -Force 
        }
        try{
            Add-Type -assembly "system.io.compression.filesystem"
            [io.compression.zipfile]::ExtractToDirectory($certFile, $destFiles )     
            $subFiles = Get-ChildItem -Path "$repoDir\sesop.tmp" 
            try{
                foreach( $item in $subFiles ){
                    if( Test-Path -Path "$repoDir\$item" ){
                        Remove-Item "$repoDir\$item" -Force
                    }
                    Move-Item $item.FullName -Destination $repoDir -Force
                }
                return "OK"
            }catch{
                return "Erro movendo arquivos para destino"
            }        
        }finally{
            Remove-Item -Path $destFiles -Force -Recurse
            Remove-Item -Path $certFile -Force
        }
    }

    function mainProc( [string] $dummy ){
        $certRepo="D:\aplic\Biometria\certificado-applet"
        if( !( Test-Path $certRepo ) ){
            return "OK - Cliente não necessita de atualização"
        }
        if( downloadConfigFile($certRepo) ){ #!Passar a URL como argumento
            try{
                openFiles($certRepo)
                try{
                    return installCert($certRepo)
                } catch {
                    $ErrorMessage = $_.Exception.Message
                    $FailedItem = $_.Exception.ItemName
                    return "$ErrorMessage `n`r $FailedItem"
                }
            } catch {
                return "Erro durante descompressão/abertura dos arquivos $_.Exception.Message $_.Exception.ItemName"
            }
        }else{
            return "Falha na operação de download"
        }
    }



    Try {
        $innerResult = mainProc( "dummy" )
    } catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        $innerResult = "$ErrorMessage `n`r $FailedItem"
    } finally{
            $sbReturn = new-object PSCustomObject –property @{ operationResult = $innerResult.Item($innerResult.Count-1) }            
    }
    return $sbReturn  #objeto de retorno 
} #Fim do scriptBlock

function localExecution{
    return Invoke-Command -ScriptBlock $clientScript
}

function readList([string] $filename){
#Leitura da lista de estações a serem tratadas nesta invocação
#A leitura será feita de um arquivo texto com um nome por linha, caso se deseje pode-se editar tal arquivo antes da execução
    #!Testar arquivo disponivel e throw caso contrario
    return Get-content $filename
}

function scriptRoot{
    $ret = $MyInvocation.ScriptName
    $ret = Split-Path $ret -Parent
    Write-Host "Executando em $ret"
    return $ret
}

function registerSucess( [string] $pcName ){
    $nbName = $pcName.Split('.')[0]
    #Get-Content $Global:inputList | Where-Object {$_ -notmatch 'not'} | Set-Content out.txt 
}

######  Globals Vars   ######

$Global:credentials   #Credenciais para invocação remota
$Global:inputList #array com nomes dos computadores
$Global:ignoreList #array com nomes dos computadores a serem ignorados
$Global:curPCName #nome do computador atualmente em processamento
$Global:INPUT_PC_LIST = "InputPCList.txt"  #nome do arquivo na pasta do script com nomes dos PCs para processamento
$Global:IGNORE_PC_LIST = "IgnorePCList.txt" #nome do arquivo na pasta do script com nomes dos PCs para ignorar(execução com sucesso insere entrada neste)
$Global:DEFAULT_ZNE_DOMAIN = "ZNE-PB001.GOV.BR" #domínio MS da operação das estações
$Global:DEFAULT_ZNE_ADMIN_USER = "$Global:DEFAULT_ZNE_DOMAIN\suporte" #Conta padrão para invocação remota
$Global:inputFilename #FullPath para arquivo de nomes de entrada
$Global:ignoreFilename #FullPath para aquivo de nomes para ignorar
$Global:logFilename #FullPath para arquivo com resumo das operações


#Main
Clear
$basePath = scriptRoot
if( ! $Global:credentials){
    $Global:credentials = Get-Credential -UserName $Global:DEFAULT_ZNE_ADMIN_USER -Message "Credenciais de conta administrativa do domínio dos computadores" 
}
$Global:inputFilename = "$basePath\$Global:INPUT_PC_LIST"
$Global:ignoreFilename = "$basePath\$Global:IGNORE_PC_LIST"
$Global:inputList = readList( $Global:inputFilename )
$Global:ignoreList = readList( $Global:ignoreFilename ) 
Foreach( $Global:curPCName in $Global:inputList ){    
    if( $Global:ignoreList.Contains($Global:curPCName) ){
        continue
    }else{ #Execução para o pc não ignorado        
        if( $Global:curPCName.StartsWith( "localhost" )){
            $remoteResult = localExecution
            Write-Host $remoteResult.operationResult            
        }else{
            if( ! $Global:curPCName.EndsWith($Global:DEFAULT_ZNE_DOMAIN) ){
                $Global:curPCName+=".$Global:DEFAULT_ZNE_DOMAIN"
            }
            Write-Host "Verficando $Global:curPCName ..."
            if( Test-Connection -ComputerName $Global:curPCName -Count 3 -Delay 2 -TTL 255 -BufferSize 256 -ThrottleLimit 32 ){
                Write-Host "Computador $Global:curPCName ativo, tentando realizar atualização...."
                $psRemSession = new-pssession -computername $Global:curPCName -Credential $Global:credentials
                if( $psRemSession ){                                                
                    try{
                        $remoteResult = Invoke-Command -session $psRemSession -ScriptBlock $clientScript
                        write-host $remoteResult                
                    }finally{
                        Remove-PSSession -Session $psRemSession
                    }
                }else{
                    Write-Error "Sessão remota para $Global:curPCName falhou"
                }
            }
        }
        $retStr = $remoteResult.operationResult.toString()
        if( $retStr.EndsWith( "OK" ) ){
            registerSucess($Global:curPCName)
        }
    }
}
Write-Host "Final da execução" -ForegroundColor Yellow

