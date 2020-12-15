#Requires -Version 7.0
using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation

$ErrorActionPreference = [ActionPreference]::Stop
$WarningPreference = [ActionPreference]::Continue
$InformationPreference = [ActionPreference]::Continue

$script:VsTerminalColorTable = @{
    Debug       = [ConsoleColor]::Magenta
    Verbose     = [ConsoleColor]::DarkGray
    Information = [ConsoleColor]::White
    Good        = [ConsoleColor]::DarkGreen
    Warning     = [ConsoleColor]::Yellow
    Error       = [ConsoleColor]::Red
}

function Write-VsTerminal {

    [CmdletBinding()]
    [SuppressMessage('PSAvoidUsingWriteHost', '')]
    param(
        [Parameter(Mandatory, POsition = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $Message,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('Debug', 'Verbose', 'Information', 'Good', 'Warning', 'Error')]
        [string] $Severity
    )

    process {
        [ConsoleColor]$Color = (
            $script:VsTerminalColorTable.ContainsKey($Severity) ?
            $script:VsTerminalColorTable.$Severity :
            [ConsoleColor]::White
        )

        Write-Host $Message -ForegroundColor $Color
    }
}



#region Invoke-VsTaskAnalyzeAllPowerShellScripts

function Invoke-VsTaskAnalyzeAllPowerShellScripts {
    <#
.SYNOPSIS
    Analyze all PowerShell-scripts files
.DESCRIPTION
    Invoke PSScriptAnalyzer for all PowerShell-scripts files (*.ps1 + *.psm1)
    Uses the current folder to search for the files recursively
.OUTPUTS
    @{ FilePath, Line, Column, Severity, RuleName, Message }
#>
    param(
        [switch] $ApplyFix
    )

    begin {
        function local:Initialize-Analyzer() {

            Write-VsTerminal "Initializing 'PSScriptAnalyzer' module..."

            if (-not(Get-InstalledModule 'PSScriptAnalyzer' -MinimumVersion 1.19.1)) {
                Write-VsTerminal " - Installing 'PSScriptAnalyzer' module" -Severity Verbose

                Install-Module 'PSScriptAnalyzer' -Force -Scope CurrentUser
            }

            if (-not(Get-Module 'PSScriptAnalyzer')) {
                Write-VsTerminal " - Importing 'PSScriptAnalyzer' module" -Severity Verbose

                Import-Module 'PSScriptAnalyzer' -PassThru |
                    Format-List Name, Version |
                    Out-String |
                    Write-VsTerminal -Severity Verbose
            }
        }

        function local:Select-TargetPsScripts() {

            Write-VsTerminal 'Selecting all PowerShell scripts...'

            $SeachArgs = @{
                Filter  = '*.ps*'
                Include = '*.ps1', '*.psm1' # '*.psd1'
                Exclude = '*FormatDataDisks.ps1', '*MoveAzureTempDrive.ps1', '*SetupDisks.ps1'
            }
            $FilePaths = @(
                Get-ChildItem @SeachArgs -Recurse |
                    Select-Object -ExpandProperty FullName |
                    Sort-Object
            )

            Write-VsTerminal " - Found: $($FilePaths.Count)" -Severity Verbose

            Write-Output $FilePaths -NoEnumerate
        }

        function local:Write-ProgressForEachFile {

            param(
                [Parameter(Mandatory, ValueFromPipeline)] [string[]] $FoundFiles
            )

            process {
                $Index = 0
                $LoggedFolder = ''

                foreach ($FilePath in $FoundFiles) {

                    # Log progress as percentage
                    $RelativeFile = Resolve-Path $FilePath -Relative
                    $ProgressPercentage = ($Index++) * 100 / $FoundFiles.Count
                    Write-Progress -Activity 'Analyzing PowerShell scripts...' -Status $RelativeFile -PercentComplete $ProgressPercentage

                    # Log progress as folder: throttled to once per folder
                    $RelativeFolder = Split-Path $RelativeFile -Parent
                    if ($LoggedFolder -ne $RelativeFolder) {
                        $LoggedFolder = $RelativeFolder

                        $LoggedFolderMsg = (' - Progress: {0,-6:N1}% => Folder: {1}' -f $ProgressPercentage, $RelativeFolder)
                        Write-VsTerminal $LoggedFolderMsg -Severity Verbose
                    }

                    # Yield file to pipeline
                    Write-Output $FilePath
                }
            }
        }

        function local:Invoke-AnalyzerForEachFile {

            param(
                [Parameter(Mandatory, ValueFromPipeline)] [string] $FilePath,
                [Parameter(Mandatory, ValueFromPipeline)] [Switch] $ApplyFix
            )

            begin {
                # Log started
                Write-VsTerminal '[STARTED] Analyzing PowerShell scripts...'

                $SubTotal = [PSCustomObject]@{
                    Succeeded = 0
                    Failed    = 0
                }
            }

            process {
                try {
                    Invoke-ScriptAnalyzer -Path $FilePath -Settings '.vscode\extensions\Pwsh.ScriptAnalysis.settings.psd1' -Fix:$ApplyFix.IsPresent | Write-Output

                    $SubTotal.Succeeded++
                } catch {
                    Write-Output (
                        [PSCustomObject]@{
                            FilePath = $FilePath
                            Line     = 0
                            Column   = 0
                            Severity = 'Fatal'
                            RuleName = $_.Exception.GetType().Name
                            Message  = "Failed while analyzing: $_"
                        })

                    $SubTotal.Failed++
                }
            }

            end {
                # Log finished
                Write-VsTerminal "[FINISHED] Analyzing PowerShell scripts!`n"

                # Log summary: Total scripts analyzed
                Write-VsTerminal 'Total scripts analyzed:'

                $SubTotalFormat = '{0,8} scripts which have {1}'
                Write-VsTerminal ($SubTotalFormat -f $SubTotal.Succeeded, 'succeeded') -Severity Good
                if ($SubTotal.Failed) {
                    Write-VsTerminal ($SubTotalFormat -f $SubTotal.Failed, 'failed') -Severity Error

                    $GrandTotal = $SubTotal.Succeeded + $SubTotal.Failed
                    Write-VsTerminal ('{0,8} scripts total' -f $GrandTotal) -Severity Information
                }
            }
        }

        function local:Format-AnalyzedResult {

            param(
                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [Alias('ScriptPath')]
                [string] $FilePath,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [int] $Line,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [int] $Column,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [string] $Severity,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [string] $RuleName,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [string] $Message
            )

            begin {
                $SubTotal = [PSCustomObject]@{
                    Errors         = 0
                    Warnings       = 0
                    Informationals = 0
                }
            }
            process {

                if ($Severity -eq 'Information') {
                    $SeverityLabel = 'info'
                    $SeverityColor = 'Information'

                    $SubTotal.Informationals++

                } elseif ($_.Severity -eq 'Warning') {
                    $SeverityLabel = 'warning'
                    $SeverityColor = 'Warning'

                    $SubTotal.Warnings++

                } else {
                    $SeverityLabel = 'error'
                    $SeverityColor = 'Error'

                    $SubTotal.Errors++
                }

                $FormattedAnalysisResult = "{0}({1},{2})`n   [{3}] {4}: {5}" -f @(
                    $FilePath, $Line, $Column,
                    $SeverityLabel, $RuleName, $Message)

                Write-VsTerminal $FormattedAnalysisResult -Severity $SeverityColor
            }

            end {
                # Log summary: Total violations analyzed
                Write-VsTerminal "`nTotal violations analyzed:"

                $SubTotalFormat = '{0,8} violations having severity: {1}'
                Write-VsTerminal ($SubTotalFormat -f $SubTotal.Errors, 'Error') -Severity Error
                Write-VsTerminal ($SubTotalFormat -f $SubTotal.Warnings, 'Warning') -Severity Warning
                Write-VsTerminal ($SubTotalFormat -f $SubTotal.Informationals, 'Information') -Severity Information

                $GrandTotal = $SubTotal.Errors + $SubTotal.Warnings + $SubTotal.Informationals
                Write-VsTerminal ('{0,8} violations in total' -f $GrandTotal) -Severity Information
            }
        }
    }

    process {
        local:Initialize-Analyzer

        local:Select-TargetPsScripts |
            local:Write-ProgressForEachFile |
            local:Invoke-AnalyzerForEachFile -ApplyFix:$ApplyFix.IsPresent |
            local:Format-AnalyzedResult
    }
}

#endregion Invoke-VsTaskAnalyzeAllPowerShellScripts



#region Invoke-VsTaskRunUnitTestsOfAllModules

function Invoke-VsTaskRunUnitTestsOfAllModules {
    <#
.SYNOPSIS
    Invoke-RunTestsForModule for all modules
#>
    Write-VsTerminal "Initializing 'Rws.Pipeline.PsModule.RunUnitTests' module..."
    Import-Module '.\Modules\Rws.Pipeline.PsModule.RunUnitTests'

    Write-VsTerminal 'Selecting all Modules folder...'
    $SearchDir = Resolve-Path '.\Modules'

    Write-VsTerminal '[STARTED] Running unit-tests on all modules...'
    Invoke-PsModuleRunUnitTests -SearchDir $SearchDir
    Write-VsTerminal "[FINISHED] Running unit-tests on all modules!`n"

}

#endregion Invoke-VsTaskRunUnitTestsOfAllModules



#region Invoke-VsTaskRunUnitTestsOfCurrentModule

function Invoke-VsTaskRunUnitTestsOfCurrentModule {
    <#
.SYNOPSIS
    Invoke-RunTestsForModule for the current folder
#>
    [CmdLetBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $CurrentFolderPath
    )

    if (-not (Test-Path $CurrentFolderPath)) {
        throw [DirectoryNotFoundException]::new("CurrentFolderPath does not exist: '$CurrentFolderPath'")
    }

    Write-VsTerminal 'Selecting current module folder...'
    $CurrentPath = Resolve-Path $CurrentFolderPath

    while ($CurrentPath) {

        Write-VsTerminal " - $CurrentPath" -Severity Verbose

        $foundRootScript = @(
            Get-ChildItem -LiteralPath $CurrentPath -Filter '*.psm1' -File
        )

        if ($foundRootScript) {

            Write-VsTerminal "Initializing 'Rws.Pipeline.PsModule.RunUnitTests' module..."
            Import-Module '.\Modules\Rws.Pipeline.PsModule.RunUnitTests'

            Write-VsTerminal '[STARTED] Running unit-tests of current module...' -Severity Verbose
            Invoke-PsModuleRunUnitTests -SutModuleDir $CurrentPath
            Write-VsTerminal "[FINISHED] Running unit-tests of current module!`n" -Severity Verbose

            return
        }

        $CurrentPath = $(Split-Path $CurrentPath -Parent)
    }

    Write-VsTerminal 'Unable to find module-root-script from current folder...' -Severity Error
}

#endregion Invoke-VsTaskRunUnitTestsOfCurrentModule



Export-ModuleMember -Function 'Invoke-VsTaskAnalyzeAllPowerShellScripts'

Export-ModuleMember -Function 'Invoke-VsTaskRunUnitTestsOfAllModules'
Export-ModuleMember -Function 'Invoke-VsTaskRunUnitTestsOfCurrentModule'
