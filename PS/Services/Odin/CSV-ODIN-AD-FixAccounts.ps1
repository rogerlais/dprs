<#
# Filename: CSV-AD-FixAccounts.ps1
# Author: Roger(Baseado em versão anterior de Marcell)
# Finalidade: Usa o atributo título exportado pelas identidades do Odin para buscar no AD(TRE-PB) os demais atributos
# Justificativa: Reflete mais facilmente as alterações nos atributos do domínio para o serviço Odin
# Requisitos: AD preenchido corretamente com os dados de título de eleitor e CPF nos campos definidos
# History:
# 2010810 - Versão inicial
# Melhorias:
# 1 - Preencher demais campos ainda desconhecidos
# 2 - Carregar valores via constantes
#>

Function Get-FileName($initialDirectory){
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null    
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.Title = "Caminho para arquivo com contas exportadas"    
    $OpenFileDialog.filter = "Texto (*.txt)| *.txt"
    $OpenFileDialog.ShowDialog() | Out-Null
    $OpenFileDialog.filename
}


#------------------------------------------------ Ponto de entrada  --------------------------------------
$inputFile = Get-FileName( "." )

$users = Import-Csv $inputFile -Header Titulo,CPF,EMail,A,UF
$users | Format-Table
foreach ($user in $users) {
    $cpf = $user.CPF.ToString()
    $aduser = Get-ADUser -Filter "postOfficeBox -eq '$cpf'" -Properties EmailAddress
    if ($aduser -is [system.array]) {  #Elimina demais para caso de mais de uma conta possuir atributo
            $adusers = $aduser
            foreach ($u in $adusers) {
                if ($u.Enabled) {
                    $aduser = $u
                }
            }
    }
    if ($aduser) {
        $emailName = [string]($aduser.EmailAddress)
        $emailName.Split('@', 2 )
        if( $emailName.IndexOf( '.' ) -eq 0 ){
            Write-Error "Dados para $aduser incompatíveis no email( $emailName )"
        }
        $user.EMail = $aduser.EmailAddress
        $user.EMail = $user.EMail.Replace(".gov.br",".jus.br")
    } else {
        $user.A = "I"
        $user.EMail = $user.EMail.Replace(".gov.br",".jus.br")
    }
    $user.UF = "PB"
}
$users | Format-Table
$users | Export-Csv C:\Users\mbarbacena\Desktop\IdentidadesCorrigido.txt -NoTypeInformation 