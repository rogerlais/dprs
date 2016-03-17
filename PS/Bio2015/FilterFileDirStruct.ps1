<#
.Synopsis
   Enumera os arquivos movendo da pasta de origem para a pasta de destino
.DESCRIPTION
   Monta estrutura da pasta de destino baseado na data de modificação do arquivo a ser movido no formato YYYY\MM
.EXAMPLE
   Exemplo de como usar este cmdlet
.EXAMPLE
   Outro exemplo de como usar este cmdlet
#>
function Move-Files
{
    [CmdletBinding()]
    [OutputType([int])]
    Param(
        # Descrição da ajuda de parâm1
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)] [string] $srcFolder,
        # Descrição da ajuda de parâm2
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)] [System.IO.DirectoryInfo] $destFolder
    )

    Begin{
    }
    Process {
        Write-Host "Local de origem dos arquivos a serem movidos: $srcFolder"
        Write-Host "Local de destino dos arquivos a serem movidos: $destFolder"
        #Enumera arquivos da origem e move para o destino separando por ano/mes
        Set-Location $srcFolder
        #!$filesFound = Get-ChildItem .\*.*
        $filesFound = [System.IO.Directory]::GetFiles("$srcFolder", "*.*")
        #[System.IO.Directory]::EnumerateFiles("$srcFolder", "*.*")
        foreach($filepath in $filesFound.GetEnumerator() ){    
            $file = New-Object System.IO.FileInfo($filepath)
            Write-Host "Arquivo origem: $file.FullName"                        
            $dir1=$file.LastWriteTime.Year.ToString("0000")
            $destFolder.CreateSubdirectory( $dir1 )
            $dir2=$file.LastWriteTime.Month.ToString("00")
            $fullDest = $destFolder.CreateSubdirectory( "$dir1\$dir2" ).FullName + "\" + $file.Name
            Write-Host $file.FullName " -> $fullDest" 
            Move-item $file.FullName -Destination $fullDest -Force
        }
        return 0
    }
    End{
    }
}


Clear
$DEBUG_MODE=!($env:COMPUTERNAME.StartsWith("CPB101PDC01" ) )
try{
    $oldLocation=Get-Location
    if ($DEBUG_MODE){
        $srcFolder=$env:TEMP
        $destFolder= Get-Item -Path $srcFolder
        $destFolder= $destFolder.CreateSubdirectory("TransBio.Logs")
        $destFolder=Get-Item -Path ( $destFolder.CreateSubdirectory( "Logs" ))       
    } else {
        $srcFolder="D:\Aplic\TransBio\Bin\Logs"        
        $destFolder= (Get-Item -Path "I:\Biometria\Arq.Morto\TransBio.Logs")
        $destFolder=Get-Item -Path ( $destFolder.CreateSubdirectory( "Logs" ))        
    }

    Write-Host "Limpeza de logs de serviços do TSE"
    Write-Host "Pasta de origem($srcFolder)"
    Write-Host "Pasta de destino($destFolder)"

    #Enumera arquivos da origem e move para o destino separando por ano/mes
    Move-Files -srcFolder $srcFolder -destFolder $destFolder
}finally{
    Set-Location $oldLocation
    Read-Host -Prompt "Tecle enter para finalizar"
}