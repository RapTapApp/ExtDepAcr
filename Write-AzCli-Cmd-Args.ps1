using namespace System.IO
using namespace System.Management.Automation
using namespace System.Text.RegularExpressions



param(
    [switch] $Log,
    [switch] $LogAll
)



# ---------------------------------------------------------------------------------------------
Import-Module $(Resolve-Path "$PSScriptRoot\Funcs.psm1") -ArgumentList @{
    Log    = $Log.IsPresent
    LogAll = $LogAll.IsPresent
}

Write-Info 'Imported: Funcs module' -Color DarkGray




# ---------------------------------------------------------------------------------------------
Write-Info 'Session: Cleanup' -Color Cyan

Get-Variable -Name '__*' | Clear-Variable -ErrorAction Ignore

$Error.Clear();



# ---------------------------------------------------------------------------------------------
Write-Info 'Session: Logging' -Color Cyan

$ErrorActionPreference = [ActionPreference]::Stop

$InformationPreference = [ActionPreference]::Continue

if ($LogAll.IsPresent) {
    $VerbosePreference = [ActionPreference]::Continue
    $DebugPreference = [ActionPreference]::Continue
}

$PSDefaultParameterValues = @{
    'Write-Verbose:Verbose' = $LogAll.IsPresent -or $Log.IsPresent
    'Write-Debug:Debug'     = $LogAll.IsPresent -or $Log.IsPresent
}



# ---------------------------------------------------------------------------------------------
Write-Verbose 'Init constants'

$__Commands = @(
    'account set',
    'account show',

    'acr create',
    'acr repository show-tags',
    'acr task create',
    'acr task credential add',
    'acr task run',
    'acr task show',
    'acr token create',

    'container show',
    'container create',

    'group create',
    'group show',

    'keyvault create',
    'keyvault secret set',
    'keyvault set-policy',

    'role assignment create'
)

$__ExcludedCmdArgs = @(
    'debug',
    'verbose',

    'help',
    'only-show-errors',

    'output',
    'query'
)



# ---------------------------------------------------------------------------------------------
Write-Verbose 'Init regex'

$__ParseHelp = Get-Regex @'
^\s+
    --(?<FullName> [\w\d-_]+ )

(\s
    -(?<ShortName> \w )
)?

(\s
    (?<IsRequired> \[ REQUIRED \] )
)?

\s+ : \s
    (?<Description> .*? )
(?=
    \n
    ( \s+ -- )?
    [\w\d-_]+
)
'@



# ---------------------------------------------------------------------------------------------
class CmdArgInfo {
    [string] $FullName
    [string] $ShortName

    [bool] $IsRequired

    [string] $Description
}



# ---------------------------------------------------------------------------------------------
function Select-CmdArgInfo {

    [CmdletBinding()]
    [OutputType([CmdArgInfo])]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [GroupCollection] $Groups
    )

    process {
        [CmdArgInfo] @{
            FullName    = $Groups.Item('FullName').Value
            ShortName   = $Groups.Item('ShortName').Value
            IsRequired  = $Groups.Item('IsRequired').Value -ne ''
            Description = $Groups.Item('Description').Value -replace '\s+', ' '
        }
    }
}



# ---------------------------------------------------------------------------------------------
Write-Info 'CmdArgs: parsing help output' -Color Cyan

Reset-CurrentStep

$__CmdInfos = [ordered] @{}
foreach ($__CmdName in $__Commands) {

    Start-LogLine ('   - {0,-30}' -f $__CmdName) -Color Cyan

    Invoke-Az -CmdArgs @("$__CmdName --help" -split ' ') |
        Join-String -Separator "`n" -OutVariable '__CmdHelp' |
        ForEach-Object { $__ParseHelp.Matches($__CmdHelp) } -OutVariable '__Parsed' |
        Select-CmdArgInfo -OutVariable '__Selected' |
        Where-Object FullName -NotIn $__ExcludedCmdArgs -OutVariable '__Filtered' |
        Out-Null

    Write-LogLine ('Selected: {0} args' -f $__Selected.Count) -NoNewLine
    Write-LogLine ('Filtered: {0} args' -f $__Filtered.Count) -Color Green

    $__CmdInfos.Add($__CmdName, $__Filtered)
}

Set-Content `
    -LiteralPath $([Path]::ChangeExtension($PSCommandPath, '.json')) `
    -Value $($__CmdInfos | ConvertTo-Json)
