function Get-SourceFile{
    $ret = $Script:MyInvocation.InvocationName
    return $ret
}

try
{
    Clear
    $VERNAME = "18.0"
    $dest = $env:APPDATA + "\Embarcadero\BDS\" + $VERNAME + "\Formatter_SESOP_Defaults.config"
    $source = Get-Item -Path ( Get-SourceFile )
    $SrcFile = $source.Directory.FullName + "\Formatter_SESOP_Defaults.config"
    Copy-Item -LiteralPath $SrcFile -Destination $dest -Force

    #TODO: Ajustar o registro para apontar para este preset

    [System.Windows.Forms.MessageBox]::Show("Preset de formatação de código carregado com sucesso", "Code Format")
    
}
catch [System.Net.WebException],[System.Exception]
{
    [System.Windows.Forms.MessageBox]::Show("Operação falhou!", "ERROR!!!")
}

