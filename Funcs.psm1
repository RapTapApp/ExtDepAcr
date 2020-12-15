#Requires -Version 7.1
using namespace System.Collections.Generic
using namespace System.Diagnostics.CodeAnalysis
using namespace System.IO
using namespace System.Management.Automation



[SuppressMessageAttribute('PSProvideCommentHelp', '')]
[SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
param(
    [hashtable] $ImportArgs
)



# ---------------------------------------------------------------------------------------------
$__State = [PSCustomObject] @{

    Log               = ${ImportArgs}?.Log -or $false
    LogAll            = ${ImportArgs}?.LogAll -or $false

    DefaultColor      = [ConsoleColor]::Gray

    LogLine_IsWritten = $false
    LogLine_Previous  = [datetime]::MinValue

    CurrentStep       = 0
}



# ---------------------------------------------------------------------------------------------
$ErrorActionPreference = [ActionPreference]::Stop

$InformationPreference = [ActionPreference]::Continue

if ($__State.LogAll) {
    $VerbosePreference = [ActionPreference]::Continue
    $DebugPreference = [ActionPreference]::Continue
}

$PSDefaultParameterValues = @{
    'Write-Verbose:Verbose' = $__State.LogAll -or $__State.Log
    'Write-Debug:Debug'     = $__State.LogAll -or $__State.Log
}



# ---------------------------------------------------------------------------------------------
function Write-Info {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        $Message,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ForegroundColor')]
        [ConsoleColor] $Color = $__State.DefaultColor,

        [switch] $NoNewLine
    )

    process {
        $MessageData = [HostInformationMessage] @{
            ForegroundColor = $Color
            Message         = $Message
            NoNewLine       = $NoNewLine.IsPresent
        }

        Write-Information -MessageData $MessageData
    }
}

Export-ModuleMember -Function 'Write-Info'



# ---------------------------------------------------------------------------------------------
function Start-LogLine {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        $Message,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ForegroundColor')]
        [ConsoleColor] $Color = $__State.DefaultColor
    )

    process {
        $__State.LogLine_IsWritten = $false
        $__State.LogLine_Previous = [datetime]::MinValue

        Write-LogLine @PSBoundParameters -NoNewLine
    }
}

function Write-LogLine {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        $Message,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ForegroundColor')]
        [ConsoleColor] $Color = $__State.DefaultColor,

        [switch] $NoNewLine
    )

    process {
        $__Timestamp = [datetime]::UtcNow

        if ($__State.LogLine_IsWritten) {

            if ($__State.LogLine_Previous -ne [datetime]::MinValue) {
                $__TotalSeconds = $__Timestamp.Subtract($__State.LogLine_Previous).TotalSeconds

                $__TotalSeconds = [Math]::Round($__TotalSeconds, 2)
                if ($__TotalSeconds -gt 0.01) {
                    $__Duration = ' ({0:N2} sec)' -f $__TotalSeconds
                    Write-Info -Message (' {0,8}' -f $__Duration) -Color DarkGray -NoNewline
                }
            }

            Write-Info -Message ' => ' -NoNewline
        }

        Write-Info @PSBoundParameters

        if ($__State.LogLine_IsWritten) {
            $__State.LogLine_Previous = $__Timestamp
        }
        $__State.LogLine_IsWritten = $true
    }
}

Export-ModuleMember -Function 'Start-LogLine'
Export-ModuleMember -Function 'Write-LogLine'



# ---------------------------------------------------------------------------------------------
function Reset-CurrentStep {

    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int] $Value = 0
    )

    $__State.CurrentStep = $Value
}

Export-ModuleMember -Function 'Reset-CurrentStep'



# ---------------------------------------------------------------------------------------------
function Invoke-Step {

    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [int] $When,

        [Parameter(Mandatory)]
        [string] $DoTitle,

        [Parameter(Mandatory)]
        [scriptblock] $DoScript
    )

    $IsWhen = $__State.CurrentStep -eq $When
    if ($IsWhen) {

        $__StepInfo = "`n{0,2} - $DoTitle`n" -f ($__State.CurrentStep + 1)
        Write-Info $__StepInfo -Color Green

        try {
            & $DoScript
            $__State.CurrentStep++

        } catch {
            Write-Error `
                -Exception $PSItem.Exception `
                -Message "Failed while running step.$__StepInfo`nException:`n$PSItem`n" `
                -ErrorAction Stop
        }
    }
}

Export-ModuleMember -Function 'Invoke-Step'



# ---------------------------------------------------------------------------------------------
function Invoke-Executable {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $CmdName,

        [Parameter()]
        [object[]] $CmdArgs
    )

    # To prevent a 'terminating error' when redirecting StdErr e.g. '2>&1'
    $ErrorActionPreference = [ActionPreference]::Continue
    try {
        if ($__State.Log) {
            Write-Info -Message "   Executing => $CmdName $CmdArgs" -Color DarkGray
        }

        & $CmdName $CmdArgs

    } catch {
        # Triggered ONLY when the $Exe can't be resolved
        Write-Error `
            -Exception $PSItem.Exception `
            -Message "Failed running executable:`n`tName: $CmdName`n`tArgs: $CmdArgs`n`nException:`n$PSItem`n" `
            -ErrorAction Stop
    }

    if ($LASTEXITCODE) {
        Write-Error "Failed running executable:`n`tName: $CmdName`n`tArgs: $CmdArgs`n`tExit: $LASTEXITCODE`n" `
            -ErrorAction Stop
    }
}



# ---------------------------------------------------------------------------------------------
function Invoke-Az {

    [CmdletBinding()]
    param(
        [Parameter()]
        [object[]] $CmdArgs
    )

    if ($__State.LogAll) {
        $CmdArgs += @('--debug', '--verbose')
    }

    try {
        Invoke-Executable -CmdName 'az' -CmdArgs $CmdArgs

    } catch {
        $PSCmdlet.ThrowTerminatingError($PSItem)
    }
}

Export-ModuleMember -Function 'Invoke-Az'



# ---------------------------------------------------------------------------------------------
function Invoke-AzCli {

    $CmdArgs = $Args
    if ($__State.LogAll) {
        $CmdArgs += @('--debug', '--verbose')
    }

    try {
        Invoke-Executable -CmdName 'az' -CmdArgs $CmdArgs

    } catch {
        throw $PSItem
    }
}

Export-ModuleMember -Function 'Invoke-AzCli'

Set-Alias -Name 'AzCli' -Value 'Invoke-AzCli'
Export-ModuleMember -Alias 'AzCli'



# ---------------------------------------------------------------------------------------------
function Get-Regex {

    [CmdletBinding()]
    [OutputType([regex])]
    param (
        [parameter(Mandatory, Position = 1)]
        [string] $Pattern
    )

    $__Options = $(
        [RegexOptions]::Compiled -bor
        [RegexOptions]::CultureInvariant -bor
        [RegexOptions]::IgnoreCase -bor
        [RegexOptions]::IgnorePatternWhitespace -bor
        [RegexOptions]::ExplicitCapture -bor
        [RegexOptions]::Singleline -bor
        [RegexOptions]::Multiline
    )

    return $(
        [regex]::new($Pattern, $__Options)
    )
}

Export-ModuleMember -Function 'Get-Regex'



# ---------------------------------------------------------------------------------------------
function Remove-WhenFoundAzResource {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $ResourceName
    )

    process {
        if ([string]::IsNullOrWhiteSpace($ResourceName)) {
            return
        }

        Start-LogLine ('   - {0,-20}' -f $ResourceName)

        Write-LogLine 'Searching...' -NoNewLine
        $__Found = Get-AzResource -Name $ResourceName -ErrorAction Ignore
        if (-not $__Found) {
            Write-LogLine '[NOT FOUND!]' -Color Yellow
            return
        }

        Write-LogLine 'Deleting...' -Color Red -NoNewLine
        $__Deleted = $__Found | Remove-AzResource -Force -ErrorAction SilentlyContinue
        if (-not $__Deleted) {
            Write-LogLine '[FAILED!]' -Color Red

        } else {
            Write-LogLine '[SUCCES!]' -Color Green
        }
    }
}

Export-ModuleMember -Function 'Remove-WhenFoundAzResource'



# ---------------------------------------------------------------------------------------------
function Remove-WhenFoundAzResourceGroup {

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Position = 0)]
        [AllowNull()]
        [AllowEmptyString()]
        [string] $RgName
    )

    process {
        if ([string]::IsNullOrWhiteSpace($RgName)) {
            return
        }

        Start-LogLine ('   - {0,-20}' -f $RgName)

        Write-LogLine 'Searching...' -NoNewLine
        $__Found = Get-AzResourceGroup -Name $RgName -ErrorAction Ignore
        if (-not $__Found) {
            Write-LogLine '[NOT FOUND!]' -Color Yellow
            return
        }

        Write-LogLine 'Deleting...' -Color Red -NoNewLine
        $__Deleted = $__Found | Remove-AzResourceGroup -Force -ErrorAction SilentlyContinue
        if (-not $__Deleted) {
            Write-LogLine '[FAILED!]' -Color Red

        } else {
            Write-LogLine '[SUCCES!]' -Color Green
        }
    }
}

Export-ModuleMember -Function 'Remove-WhenFoundAzResourceGroup'
