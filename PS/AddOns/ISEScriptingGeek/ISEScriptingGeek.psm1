#requires -version 3.0

<#
A collection of add-ons for the Powershell 4.0 ISE
#>

#dot source the scripts
. $psScriptRoot\New-CommentHelp.ps1
. $psScriptRoot\ConvertTo-TextFile.ps1
. $psScriptRoot\Convert-AliasDefinition.ps1
. $psScriptRoot\Convertall.ps1
. $psScriptRoot\ConvertFrom-Alias.ps1
. $psScriptRoot\Sign-ISEScript.ps1
. $psScriptRoot\Print-ISEFile.ps1
. $psScriptRoot\Convert-CodeToSnippet.ps1
. $psScriptRoot\Out-ISETab.ps1
. $psScriptRoot\Open-SelectedinISE.ps1
. $psScriptRoot\Convert-CommandToHash.ps1
. $psScriptRoot\Get-CommandMetadata.ps1
. $psScriptRoot\CycleISETabs.ps1
. $psScriptRoot\New-DSCResourceSnippet.ps1
. $psScriptRoot\New-PSCommand.ps1
. $psScriptRoot\New-PSDriveHere.ps1
. $psScriptRoot\Find-InFile.ps1
. $psScriptRoot\CIMScriptMaker.ps1


<#
Add an ISE Menu shortcut to save all open files.
This will only save files that have previously been saved
with a title. Anything that is untitled still needs
to be manually saved first.
#>

$saveall={
  $psise.CurrentPowerShellTab.files | 
  where {-Not ($_.IsUntitled)} | 
  foreach {
    $_.Save()
  }
}

#a function to display scripting about topics
Function Get-ScriptingHelp {
Param()
 Get-Help about_Scripting* | Select Name,Synopsis | 
 Out-GridView -Title "Select one or more help topics" -OutputMode Multiple |
 foreach { $_ | get-help -ShowWindow}
}

#create a custom sub menu
$jdhit=$psise.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("ISE Scripting Geek",$null,$null)

#add my menu addons
$jdhit.submenus.Add("Add Help",{New-CommentHelp},"ALT+H") | Out-Null

#add menu entries
$jdhit.submenus.Add("Convert All Aliases",{ConvertTo-Definition $psise.CurrentFile.Editor.SelectedText},$Null) | Out-Null
$jdhit.submenus.Add("Convert Code to Snippet",{Convert-CodetoSnippet -Text $psise.CurrentFile.Editor.SelectedText},"CTRL+ALT+S")
$jdhit.submenus.Add("Convert Selected From Alias",{ConvertFrom-Alias},$Null) | Out-Null
$jdhit.submenus.Add("Convert Single Selected to Alias",{Convert-AliasDefinition $psise.CurrentFile.Editor.SelectedText -ToAlias},$Null) | Out-Null
$jdhit.submenus.Add("Convert Single Selected to Command",{Convert-AliasDefinition $psise.CurrentFile.Editor.SelectedText -ToDefinition},$Null) | Out-Null
$jdhit.Submenus.Add("Convert to lowercase",
{$psise.currentfile.editor.insertText($psise.CurrentFile.Editor.SelectedText.toLower())},"CTRL+ALT+L") | Out-Null
$jdhit.Submenus.Add("Convert to parameter hash",{Convert-CommandToHash},"Ctrl+ALT+H") | Out-Null
$jdhit.submenus.Add("Convert to text file",{ConvertTo-TextFile}, "ALT+T") | Out-Null
$jdhit.Submenus.Add("Convert to uppercase",
{$psise.currentfile.editor.insertText($psise.CurrentFile.Editor.SelectedText.toUpper())},"CTRL+ALT+U") | Out-Null
$jdhit.Submenus.add("Create new DSC Resource Snippets",{New-DSCResourceSnippet},$Null) | Out-Null

$jdhit.submenus.Add("Get Scripting Help",{Get-ScriptingHelp},$Null) | Out-Null

$jdhit.Submenus.add("Find in File",{Find-InFile},"Ctrl+Shift+F") | Out-Null

$jdhit.submenus.Add("Insert Datetime",{$psise.CurrentFile.Editor.InsertText(("{0} {1}" -f (get-date),(get-wmiobject win32_timezone -property StandardName).standardName))},"ALT+F5") | out-Null

$jdhit.Submenus.add("New CIM Commnd",{New-CimCommand},$Null) | Out-Null

$jdhit.submenus.Add("Open Current Script Folder",{Invoke-Item (split-path $psise.CurrentFile.fullpath)},"ALT+O") | out-Null
$jdhit.Submenus.Add("Open Selected",{Open-SelectedISE},"Ctrl+Alt+F") | Out-Null

$jdhit.submenus.Add("Print Script",{Send-ToPrinter},"CTRL+ALT+P") | Out-Null

$jdhit.Submenus.Add("Save All Files",$saveall,"Ctrl+Shift+A") | Out-Null
$jdhit.submenus.Add("Save File as ASCII",{$psISE.CurrentFile.Save([Text.Encoding]::ASCII)}, $null) | Out-Null
$jdhit.submenus.Add("Sign Script",{Write-Signature},$null) | Out-Null

$jdhit.Submenus.Add("Switch next tab",{Get-NextISETab},"Ctrl+ALT+T") | Out-Null

$jdhit.Submenus.Add("Use local help",{$psise.Options.UseLocalHelp = $True},$Null) | Out-Null
$jdhit.Submenus.Add("Use online help",{$psise.Options.UseLocalHelp = $False},$Null) | Out-Null

#define some ISE specific variables
$mysnippets = "$Env:USERPROFILE\Documents\WindowsPowerShell\Snippets"
$mymodules = Join-Path -Path $home -ChildPath "documents\WindowsPowerShell\Modules"

Export-ModuleMember -Function * -Alias * -Variable mysnippets,mymodules