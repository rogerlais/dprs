
#region Start-Log
function Start-Log
{
	[CmdletBinding(ConfirmImpact="Low")]
	param
	(
		[parameter(Position = 0, Mandatory=$true)]
        [ValidateScript({
			if (-not $_.Exists)
			{
				throw "LogPath does not exist"
			}
			return $true
		})]
		[System.IO.DirectoryInfo]$LogPath,
		
		[parameter(Position = 1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
		[string]$LogName,
		
		[parameter(Position = 1, Mandatory=$true)]
		[System.Diagnostics.SourceLevels]$Level
	)
	
	Add-Type -AssemblyName Microsoft.VisualBasic	
	$script:LogFile = $logName
	$script:Log = New-Object Microsoft.VisualBasic.Logging.Log
	$script:Log.DefaultFileLogWriter.Append = $true
	$script:Log.DefaultFileLogWriter.AutoFlush = $true
	$script:Log.DefaultFileLogWriter.Delimiter = ";"
	$script:Log.DefaultFileLogWriter.MaxFileSize = 2GB
	$script:log.DefaultFileLogWriter.ReserveDiskSpace = 1GB
	$script:Log.DefaultFileLogWriter.LogFileCreationSchedule = "Daily"
	$script:Log.DefaultFileLogWriter.Location = "Custom"
	$script:Log.DefaultFileLogWriter.CustomLocation = $LogPath
	$script:Log.DefaultFileLogWriter.BaseFileName = $LogName
	$script:Log.TraceSource.Switch.Level = $Level
	
	Write-LogEntry -Message "Starting log" -EntryType Information
}
#endregion

#region Stop-Log
function Stop-Log
{	
	Write-LogEntry -Message "Closing log" -EntryType Verbose
	$Log.DefaultFileLogWriter.Flush()
	$Log.DefaultFileLogWriter.Close()
}
#endregion

#region Write-LogEntry
function Write-LogEntry
{
	param
	(
		[Parameter(Position = 0, Mandatory=$true)]
		[AllowEmptyString()]
		[string]$Message,
		
		[Parameter(Position = 1, Mandatory=$true)]
		[System.Diagnostics.TraceEventType] $EntryType,
		
		[Parameter(Position = 2)]
		[ValidateNotNullOrEmpty()]
		[string] $Details,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch] $SupressConsole
	)
	
	if(!$Log)
	{
		Microsoft.PowerShell.Utility\Write-Verbose "Cannot write to the log file until Start-Log has been called"
		return
	}
	if (($EntryType -band $Log.TraceSource.Switch.Level) -ne $EntryType)
	{
		return
	}
	
	$caller = (Get-PSCallStack)[1]
	if ($caller.Command -eq "Write-Host" -or
		$caller.Command -eq "Write-Warning" -or
		$caller.Command -eq "Write-Verbose" -or
		$caller.Command -eq "Write-Debug" -or
		$caller.Command -eq "Write-Error" -or
		$caller.Command -eq "Start-Log" -or
		$caller.Command -eq "Stop-Log")
	{
		$caller = (Get-PSCallStack)[2]
	}
	
	$callerFunctionName = $caller.Command
	if ($caller.ScriptName) { $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf }
	$Message = "{0};{1};{2};{3};{4}" -f  (Get-Date),$callerScriptName,$callerFunctionName,$Message,$Details
	$Log.WriteEntry($Message, $EntryType)
	
	if (-not $SupressConsole)
	{
		$Message = ($Message -split ";")[2..3]
		if ($Details)
		{
			$Message += ": $Details"
		}
		
		if ($EntryType -eq "Verbose")
		{
			Microsoft.PowerShell.Utility\Write-Verbose $Message
		}
		elseif ($EntryType -eq "Warning")
		{
			Microsoft.PowerShell.Utility\Write-Warning $Message
		}
		elseif ($EntryType -eq "Information")
		{		
			Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor DarkGreen
		}
		elseif ($EntryType -eq "Error")
		{
			Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
		}
		elseif ($EntryType -eq "Critical")
		{
			Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
		}
	}
}
#endregion

#region Write-LogFunctionEntry
function Write-LogFunctionEntry
{
	if(!$Log)
	{
		throw "Cannot write to the log file until Start-Log has been called"
		return
	}
	if (([System.Diagnostics.TraceEventType]::Verbose -band $Log.TraceSource.Switch.Level) -ne [System.Diagnostics.TraceEventType]::Verbose)
	{
		return
	}
	
	$Message = "Entering..."
	
	$caller = (Get-PSCallStack)[1]
	$callerFunctionName = $caller.Command
	if ($caller.ScriptName) { $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf }
	
	$Message += " ("
	foreach ($parameter in $caller.InvocationInfo.BoundParameters.GetEnumerator())
	{
		if ($parameter.Value -is [System.Array])
		{
			$Message += "{0}={1}({2})," -f $parameter.Key, $parameter.Value, $parameter.Value.Count
		}
		else
		{
			$Message += "{0}={1}," -f $parameter.Key, $parameter.Value
		}
	}
	$Message = $Message.Substring(0, $Message.Length - 1)
	$Message += ")"
	
	$Message = "{0};{1};{2};{3}" -f  (Get-Date),$callerScriptName,$callerFunctionName,$Message
	$Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Verbose)
	$Message = ($Message -split ";")[2..3] -join ' '
	
	Microsoft.PowerShell.Utility\Write-Verbose $Message
}
#endregion

#region Write-LogFunctionExit
function Write-LogFunctionExit
{
    param
	(
		[Parameter(Position = 0)]
		[string]$ReturnValue
	)

	if(!$Log)
	{
		throw "Cannot write to the log file until Start-Log has been called"
		return
	}
	if (([System.Diagnostics.TraceEventType]::Verbose -band $Log.TraceSource.Switch.Level) -ne [System.Diagnostics.TraceEventType]::Verbose)
	{
		return
	}

    if ($ReturnValue)
    {
	    $Message = "...leaving - return value is '{0}'" -f $ReturnValue
    }
    else
    {
        $Message = "...leaving."
    }
	
	$caller = (Get-PSCallStack)[1]
	$callerFunctionName = $caller.Command
	if ($caller.ScriptName) { $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf }
	
	$Message = "{0};{1};{2};{3}" -f  (Get-Date),$callerScriptName,$callerFunctionName,$Message
	$Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Verbose)
	$Message = -join ($Message -split ";")[2..3]
	
	Microsoft.PowerShell.Utility\Write-Verbose $Message
}
#endregion

#region Write-LogFunctionExitWithError
function Write-LogFunctionExitWithError
{
	[CmdletBinding(
		ConfirmImpact="Low",
		DefaultParameterSetName="Message"
	)]
	
	param
	(
		[Parameter(Position = 0, ParameterSetName="Message")]
        [ValidateNotNullOrEmpty()]
		[string]$Message,

		[Parameter(Position = 0, ParameterSetName="ErrorRecord")]
        [ValidateNotNullOrEmpty()]
		[System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Position = 0, ParameterSetName="Exception")]
        [ValidateNotNullOrEmpty()]
		[System.Exception]$Exception,

		[Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
		[string]$Details
	)
	if(!$Log)
	{
		throw "Cannot write to the log file until Start-Log has been called"
		return
	}
	if (([System.Diagnostics.TraceEventType]::Error -band $Log.TraceSource.Switch.Level) -ne [System.Diagnostics.TraceEventType]::Error)
	{
		return
	}
	
	switch ($pscmdlet.ParameterSetName)
	{
		"Message"
		{
			$Message = "...leaving: " + $Message
		}
		"ErrorRecord"
		{
			$Message = "...leaving: " + $ErrorRecord.Exception.Message
		}
        "Exception"
        {
            $Message = "...leaving: " + $Exception.Message
        }
	}
	
	$EntryType = "Error"
	
	$caller = (Get-PSCallStack)[1]
	$callerFunctionName = $caller.Command
	if ($caller.ScriptName) { $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf }
	
	$Message = "{0};{1};{2};{3}" -f  (Get-Date),$callerScriptName,$callerFunctionName,$Message
	if ($Details) { $Message += ";" + $Details }
	$Log.WriteEntry($Message, [System.Diagnostics.TraceEventType]::Error)
	$Message = -join ($Message -split ";")[2..3]
	
	Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
}
#endregion

#region Write-LogError
function Write-LogError
{
	[CmdletBinding(
		ConfirmImpact="Low",
		DefaultParameterSetName="Name"
	)]
	param
	(
		[Parameter(Position = 0, Mandatory=$true,ParameterSetName="Message")]
        [ValidateNotNullOrEmpty()]
		[string]$Message,
		
		[Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
		[string]$Details,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
		[System.Exception]$Exception
	)	
	if(!$Log)
	{
		throw "Cannot write to the log file until Start-Log has been called"
		return
	}
	if ($EntryType -band $Log.TraceSource.Switch.Level -ne $EntryType)
	{
		return
	}
	
	$EntryType = "Error"
	
	$caller = (Get-PSCallStack)[1]
	$callerFunctionName = $caller.Command
	if ($caller.ScriptName) { $callerScriptName = Split-Path -Path $caller.ScriptName -Leaf }
	
	if ($Excpetion)
    {
        $Message = "{0};{1};{2};{3}" -f  (Get-Date),$callerScriptName,$callerFunctionName,("{0}: {1}" -f $Message, $Excpetion.Message)
    }
    else
    {
        $Message = "{0};{1};{2};{3}" -f  (Get-Date),$callerScriptName,$callerFunctionName,$Message
    }

	if ($Details) { $Message += ";" + $Details }
	$Log.WriteEntry($Message, $EntryType)
	$Message = -join ($Message -split ";")[2..3]
	
	Microsoft.PowerShell.Utility\Write-Host $Message -ForegroundColor Red
}
#endregion

#region Write-Host
function Write-Host
{
	[CmdletBinding()]
	param(
	    [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
	    [System.Object]
	    ${Object},

	    [Switch]
	    ${NoNewline},

	    [System.Object]
	    ${Separator},

	    [System.ConsoleColor]
	    ${ForegroundColor},

	    [System.ConsoleColor]
	    ${BackgroundColor})

	begin
	{
	    try {
			Write-LogEntry -EntryType Information -Message $Object -SupressConsole
	        $outBuffer = $null
	        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
	        {
	            $PSBoundParameters['OutBuffer'] = 1
	        }
	        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
	        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
	        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
	        $steppablePipeline.Begin($PSCmdlet)
	    } catch {
	        throw
	    }
	}

	process
	{
	    try {
	        $steppablePipeline.Process($_)
	    } catch {
	        throw
	    }
	}

	end
	{
	    try {
	        $steppablePipeline.End()
	    } catch {
	        throw
	    }
	}
	<#

	.ForwardHelpTargetName Write-Host
	.ForwardHelpCategory Cmdlet

	#>
}
#endregion

#region Write-Warning
function Write-Warning
{
	[CmdletBinding()]
	param(
	    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
	    [Alias('Msg')]
	    [AllowEmptyString()]
	    [System.String]
	    ${Message})

	begin
	{
	    try {
			Write-LogEntry -EntryType Warning -Message $Message -SupressConsole
	        $outBuffer = $null
	        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
	        {
	            $PSBoundParameters['OutBuffer'] = 1
	        }
	        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Warning', [System.Management.Automation.CommandTypes]::Cmdlet)
	        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
	        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
	        $steppablePipeline.Begin($PSCmdlet)
	    } catch {
	        throw
	    }
	}

	process
	{
	    try {
	        $steppablePipeline.Process($_)
	    } catch {
	        throw
	    }
	}

	end
	{
	    try {
	        $steppablePipeline.End()
	    } catch {
	        throw
	    }
	}
	<#

	.ForwardHelpTargetName Write-Warning
	.ForwardHelpCategory Cmdlet

	#>
}
#endregion

#region Write-Verbose
function Write-Verbose
{
	[CmdletBinding()]
	param(
	    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
	    [Alias('Msg')]
	    [AllowEmptyString()]
	    [System.String]
	    ${Message})

	begin
	{
	    try {
			Write-LogEntry -EntryType Verbose -Message $Message -SupressConsole
	        $outBuffer = $null
	        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
	        {
	            $PSBoundParameters['OutBuffer'] = 1
	        }
	        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
	        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
	        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
	        $steppablePipeline.Begin($PSCmdlet)
	    } catch {
	        throw
	    }
	}

	process
	{
	    try {
	        $steppablePipeline.Process($_)
	    } catch {
	        throw
	    }
	}

	end
	{
	    try {
	        $steppablePipeline.End()
	    } catch {
	        throw
	    }
	}
	<#

	.ForwardHelpTargetName Write-Verbose
	.ForwardHelpCategory Cmdlet

	#>
}
#endregion

#region Write-Error
function Write-Error
{
	[CmdletBinding(DefaultParameterSetName='NoException')]
	param(
	    [Parameter(ParameterSetName='WithException', Mandatory=$true)]
	    [System.Exception]
	    ${Exception},

	    [Parameter(ParameterSetName='NoException', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
	    [Parameter(ParameterSetName='WithException')]
	    [Alias('Msg')]
	    [AllowNull()]
	    [AllowEmptyString()]
	    [System.String]
	    ${Message},

	    [Parameter(ParameterSetName='ErrorRecord', Mandatory=$true)]
	    [System.Management.Automation.ErrorRecord]
	    ${ErrorRecord},

	    [Parameter(ParameterSetName='NoException')]
	    [Parameter(ParameterSetName='WithException')]
	    [System.Management.Automation.ErrorCategory]
	    ${Category},

	    [Parameter(ParameterSetName='NoException')]
	    [Parameter(ParameterSetName='WithException')]
	    [System.String]
	    ${ErrorId},

	    [Parameter(ParameterSetName='NoException')]
	    [Parameter(ParameterSetName='WithException')]
	    [System.Object]
	    ${TargetObject},

	    [System.String]
	    ${RecommendedAction},

	    [Alias('Activity')]
	    [System.String]
	    ${CategoryActivity},

	    [Alias('Reason')]
	    [System.String]
	    ${CategoryReason},

	    [Alias('TargetName')]
	    [System.String]
	    ${CategoryTargetName},

	    [Alias('TargetType')]
	    [System.String]
	    ${CategoryTargetType})

	begin
	{
	    try {
			Write-LogEntry -EntryType Error -Message $Message -SupressConsole
	        $outBuffer = $null
	        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
	        {
	            $PSBoundParameters['OutBuffer'] = 1
	        }
	        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Error', [System.Management.Automation.CommandTypes]::Cmdlet)
	        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
	        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
	        $steppablePipeline.Begin($PSCmdlet)
	    } catch {
	        throw
	    }
	}

	process
	{
	    try {
	        $steppablePipeline.Process($_)
	    } catch {
	        throw
	    }
	}

	end
	{
	    try {
	        $steppablePipeline.End()
	    } catch {
	        throw
	    }
	}
	<#
	.ForwardHelpTargetName Write-Error
	.ForwardHelpCategory Cmdlet
	#>
}
#endregion

#region Write-Debug
function Write-Debug
{
	[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113424', RemotingCapability='None')]
	param(
	    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
	    [Alias('Msg')]
	    [AllowEmptyString()]
	    [string]
	    ${Message})

	begin
	{
	    try {
			Write-LogEntry -EntryType Verbose -Message $Message -SupressConsole
	        $outBuffer = $null
	        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
	        {
	            $PSBoundParameters['OutBuffer'] = 1
	        }
	        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)
	        $scriptCmd = {& $wrappedCmd @PSBoundParameters }
	        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
	        $steppablePipeline.Begin($PSCmdlet)
	    } catch {
	        throw
	    }
	}

	process
	{
	    try {
	        $steppablePipeline.Process($_)
	    } catch {
	        throw
	    }
	}

	end
	{
	    try {
	        $steppablePipeline.End()
	    } catch {
	        throw
	    }
	}
	<#

	.ForwardHelpTargetName Write-Debug
	.ForwardHelpCategory Cmdlet

	#>
}
#endregion