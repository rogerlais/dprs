<#
.SYNOPSIS
Determines a users most recent logins to a specific computer.
.DESCRIPTION
Get-LoginTimes digs through a computer's local security logs to find logon and logoff events triggered by a specific user.

This is accomplished through the local RemoteRegistry service running on a machine. If this service is stopped, Get-LoginTimes will start it.
.PARAMETER User
The user account that you would like to determine the login times for.
If this paramter is not present, it will default to the current authenticated user.
.PARAMETER Computer
The computer that the user presumably logged into.
If this parameter is not preset, it will default to the local computer.
.PARAMETER Before
Working backwards, this is the most recent time to check at.
.PARAMETER LeaveServiceRunning
Tells the script to stopped the RemoteRegistry service or to leave it running.
Defaults to $true.
.EXAMPLE
Get-LoginTimes

This returns the login times for the authenticated user on the computer the script is running on.
.EXAMPLE
Get-LoginTimes Twon.of.An DaCrib01

Returns the login times of Twon.of.An on the computer/server Dacrib01 starting at the current time and working back to the beginning of the security logs.
.EXAMPLE
Get-LoginTimes Twon.of.An Dacrib01 -before 8:30:00 -LeaveServiceRunning $true

Returns the login times of Twon.of.An on the computer/server Dacrib01 starting at 8:30 and working back to the befinning of the security logs. With these arguments, it will also end the RemoteRegistry service upon finishing.
.NOTES
Author: Twon of An
.LINK
Get-Service
Set-Service
Get-EventLog
Get-WmiObject
#>
Function Get-LoginTimes
{
	param
	(
		[Parameter(ValueFromPipeline=$true)]
		[String]$User = $env:username
		,
		[Parameter(ValueFromPipeline=$true)]
		[String]$Computer = $env:computername
		,
		[Parameter(Mandatory=$false)]
		[DateTime]$Before = (Get-Date)
		,		
		[Parameter(Mandatory=$false)]
		[Bool]$LeaveServiceRunning = $true
		
	)
	$RegServ = Get-Service remoteregistry -ComputerName $Computer
	If(($RegServ.status -ne "Running") -and ($Computer -ne $env:computername))
	{
		Set-Service remoteregistry -ComputerName $Computer -status Running
	}
	Get-Eventlog security -computer $Computer -before $Before | Where-Object {($_.instanceID -eq "4624") -and ($_.replacementstrings -contains $User)}
	If($LeaveServiceRunning -eq $false)
	{
		Write-Host Turning RemoteRegistry service off...
		Get-WmiObject -Class Win32_Service -Filter 'name="remoteregistry"' -ComputerName $Computer | Invoke-WmiMethod -Name StopService | out-null
	}
}

Get-LoginTimes -Computer "ZPB033WKS10.ZNE-PB001.GOV.BR" -User "033770231295"