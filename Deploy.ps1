using namespace System.Diagnostics.CodeAnalysis
using namespace System.Management.Automation



[SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
param(
    [switch] $Log,
    [switch] $LogAll,

    [switch] $RemoveAll,
    [switch] $DeployAll
)

Set-StrictMode -Version latest
Clear-Host



# ---------------------------------------------------------------------------------------------
Import-Module $(Resolve-Path "$PSScriptRoot\Funcs.psm1") -ArgumentList @{
    Log    = $Log.IsPresent
    LogAll = $LogAll.IsPresent
}

Write-Info 'Imported: Funcs module' -Color DarkGray

if ($RemoveAll.IsPresent) {
    Reset-CurrentStep
}



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

Set-Location "$PSScriptRoot"



# ---------------------------------------------------------------------------------------------
Write-Verbose 'Init constants'

# define globals constants
$__LOCATION = 'WestEurope'
$__SUBSCRIPTION = 'RWS-HUB-09'

# define key-vault constants
$__AKV = 'SutAkv'
$__AKV_RG = "$__AKV-rg"

# define Git-token constants
$__GIT_TOKEN = 'Sut-Git-token'
$__GIT_TOKEN_VALUE = $(Get-Content -LiteralPath "$PSCommandPath.key" -Raw).Trim()

# define container-registry constants
$__ACR_DOCKER_URL = 'docker.io'
$__ACR_TASK_YAML = 'acr-task.yaml'

# define container-registry: public constants
$__ACR_PUBLIC = 'SutAcrPublic'
$__ACR_PUBLIC_RG = "$__ACR_PUBLIC-rg"
$__ACR_PUBLIC_TASK = "$__ACR_PUBLIC-task"
$__ACR_PUBLIC_GIT = 'https://github.com/RapTapApp/ExtDepAcr-0-Public.git#main'
$__ACR_PUBLIC_URL = "$__ACR_PUBLIC.azurecr.io"
$__ACR_PUBLIC_USER = "$__ACR_PUBLIC-user"
$__ACR_PUBLIC_PASS = "$__ACR_PUBLIC-pass"

# define container-registry: import constants
$__ACR_IMPORT = 'SutAcrImport'
$__ACR_IMPORT_RG = "$__ACR_IMPORT-rg"
$__ACR_IMPORT_TASK = "$__ACR_IMPORT-task"
$__ACR_IMPORT_GIT = 'https://github.com/RapTapApp/ExtDepAcr-1-Import.git#main'
$__ACR_IMPORT_URL = "$__ACR_IMPORT.azurecr.io"
$__ACR_IMPORT_USER = "$__ACR_IMPORT-user"
$__ACR_IMPORT_PASS = "$__ACR_IMPORT-pass"

# define container-registry: target constants
$__ACR_TARGET = 'SutAcrTarget'
$__ACR_TARGET_RG = "$__ACR_TARGET-rg"
$__ACR_TARGET_TASK = "$__ACR_TARGET-task"
$__ACR_TARGET_GIT = 'https://github.com/RapTapApp/ExtDepAcr-2-Target.git#main'
$__ACR_TARGET_URL = "$__ACR_TARGET.azurecr.io"
$__ACR_TARGET_USER = "$__ACR_TARGET-user"
$__ACR_TARGET_PASS = "$__ACR_TARGET-pass"
$__ACR_TARGET_REPO = 'my-app-repo'

# define container-instance constants
$__ACI = 'SutAci'
$__ACI_RG = "$__ACI-rg"
$__ACI_SUB = $__SUBSCRIPTION
$__ACI_LOC = $__LOCATION
$__ACI_NAME = 'my-app-container'



$__ConfigDir = Join-Path -Path $PSScriptRoot -ChildPath '.config'
if (-not (Test-Path $__ConfigDir)) {
    Write-Verbose "Creating '.config' folder"
    mkdir $__ConfigDir | Out-Null
}

$__LogsDir = Join-Path -Path $PSScriptRoot -ChildPath '.logs'
if (-not (Test-Path $__LogsDir)) {
    Write-Verbose "Creating '.logs' folder"
    mkdir $__LogsDir | Out-Null
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 0 -DoTitle 'Initializing Az-Cli tool' -DoScript {

    $Env:AZURE_CONFIG_DIR = $__ConfigDir

    if (Test-Path (Join-Path $__ConfigDir -ChildPath 'config')) {
        return
    }

    try {
        AzCli account clear
        Write-Verbose 'Cleared account'
    } catch {
        Write-Verbose 'Unable to clear account'
    }

    try {
        AzCli logout
        Write-Verbose 'Logged out'
    } catch {
        Write-Verbose 'Unable to log out'
    }

    AzCli login --query '[].name' | Write-Info -Color DarkGray
    Write-Verbose 'Logged in'


    Write-Verbose 'Setting config'
    # Disable warning output (e.g. from preview commands)
    AzCli config set core.only_show_errors=false

    # Disable color output (Fails when running in parallel)
    AzCli config set core.no_color=false

    # Enable logging
    AzCli config set "logging.log_dir=$__LogsDir\"
    AzCli config set logging.enable_log_file=true

    # Install devops cli extension
    $__InstalledExtensions = @(AzCli extension list --query '[].name' | ConvertFrom-Json)
    if ('azure-devops' -notin $__InstalledExtensions) {
        Write-Verbose "Installing 'azure-devops' extention"
        AzCli extension add --name 'azure-devops'
    }
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 1 -DoTitle 'Initializing subscription: Az-Cli' -DoScript {


    function Get-AzCliSub () {
        try {
            AzCli account show --query 'name' --output tsv
        } catch {
            ''
        }
    }

    $__SUB_CLI = Get-AzCliSub
    Write-Verbose "Subscription is '$__SUB_CLI'"

    if ($__SUB_CLI -ne $__SUBSCRIPTION) {
        Write-Verbose "Subscription => '$__SUBSCRIPTION'"

        AzCli account set --subscription $__SUBSCRIPTION

        $__SUB_CLI = Get-AzCliSub
        if ($__SUB_CLI -ne $__SUBSCRIPTION) {
            throw [InvalidOperationException] "Az-Cli: Failed changing subscription to '$__SUBSCRIPTION'"
        }

        Write-Verbose "Subscription is '$__SUB_CLI'"
    }
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 2 -DoTitle 'Initializing subscription: Az-Pwsh' -DoScript {

    $__SUB_PWSH = Get-AzContext | ForEach-Object Subscription | ForEach-Object Name
    Write-Verbose "Subscription is '$__SUB_PWSH'"

    if ($__SUB_PWSH -ne $__SUBSCRIPTION) {
        Write-Verbose "Subscription => '$__SUBSCRIPTION'"

        Clear-AzContext -Scope Process -ErrorAction SilentlyContinue
        Disconnect-AzAccount -Scope Process -ErrorAction SilentlyContinue
        Write-Verbose 'Subscription => Cleared context & Disconnected account'

        Connect-AzAccount -Scope Process -Subscription $__SUBSCRIPTION
        Set-AzContext -Scope Process -Subscription $__SUBSCRIPTION
        Write-Verbose 'Subscription => Connected account & Set context'

        $__SUB_PWSH = Get-AzContext | ForEach-Object Subscription | ForEach-Object Name
        if ($__SUB_PWSH -ne $__SUBSCRIPTION) {
            throw [InvalidOperationException] "Az-Pwsh: Failed changing subscription to '$__SUBSCRIPTION'"
        }

        Write-Verbose "Subscription is '$__SUB_PWSH'"
    }
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 3 -DoTitle 'Removing all' -DoScript {

    if ($RemoveAll.IsPresent) {
        Write-Host ' ! - Removing all' -ForegroundColor Red

        Write-Verbose 'Resources'
        # @(AzCli resource list --subscription $__SUBSCRIPTION --query [].name | ConvertFrom-Json) +
        @($__ACR_PUBLIC, $__ACR_IMPORT, $__ACR_TARGET, $__AKV, $__ACI, $__ACI_NAME) |
            Remove-WhenFoundAzResource



        Write-Verbose 'Resource-groups'
        # @(AzCli group list --subscription $__SUBSCRIPTION --query [].name | ConvertFrom-Json) +
        @($__ACR_PUBLIC_RG, $__ACR_IMPORT_RG, $__ACR_TARGET_RG, $__AKV_RG, $__ACI_RG) |
            Remove-WhenFoundAzResourceGroup



        Write-Verbose 'Purge key-vault'
        Az keyvault purge `
            --subscription $__SUBSCRIPTION `
            --location $__LOCATION `
            --name $__AKV `
            --only-show-errors
    }
}



# ---------------------------------------------------------------------------------------------
if (-not $DeployAll.IsPresent) {

    Write-Warning '-DeployAll not specied.'
    Write-Verbose 'Exiting deployment script'
    exit 1
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 4 -DoTitle 'Creating key-vault' -DoScript {

    AzCli group create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --name $__AKV_RG `
        --query 'name' | Write-Info -Color DarkGray

    AzCli keyvault create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --resource-group $__AKV_RG `
        --name $__AKV `
        --query 'name' | Write-Info -Color DarkGray

    Write-Verbose 'Setting secret: Git-token'
    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__GIT_TOKEN `
        --value $__GIT_TOKEN_VALUE `
        --query 'name' | Write-Info -Color DarkGray
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 5 -DoTitle 'Creating container-registry: Public' -DoScript {

    Remove-WhenFoundAzResourceGroup $__ACR_PUBLIC_RG

    AzCli group create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --name $__ACR_PUBLIC_RG `
        --query 'name' | Write-Info -Color DarkGray

    AzCli acr create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --resource-group $__ACR_PUBLIC_RG `
        --name $__ACR_PUBLIC `
        --sku 'Premium' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Creating task'
    AzCli acr task create `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_PUBLIC_RG `
        --registry $__ACR_PUBLIC `
        --name $__ACR_PUBLIC_TASK `
        --assign-identity '[system]' `
        --context "$__ACR_PUBLIC_GIT" `
        --git-access-token $__GIT_TOKEN_VALUE `
        --commit-trigger-enabled true `
        --base-image-trigger-enabled false `
        --file $__ACR_TASK_YAML `
        --set "FROM_REGISTRY_URL=$__ACR_DOCKER_URL/" `
        --image 'node:15-alpine' `
        --image 'node:15-alpine-{{.Run.ID}}' |
        Write-Info -Color Magenta



    Write-Verbose 'Started running task'
    AzCli acr task run `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_PUBLIC_RG `
        --registry $__ACR_PUBLIC `
        --name $__ACR_PUBLIC_TASK

    Write-Verbose "Finished running task => Showing tags of 'node' repository"
    AzCli acr repository show-tags `
        --name $__ACR_PUBLIC `
        --repository 'node'



    Write-Verbose 'Creating user with pull authorization'
    $__ACR_PUBLIC_PASS_VALUE = $(
        AzCli acr token create `
            --subscription $__SUBSCRIPTION `
            --resource-group $__ACR_PUBLIC_RG `
            --registry $__ACR_PUBLIC `
            --name $__ACR_PUBLIC_USER `
            --scope-map '_repositories_pull' `
            --query 'credentials.passwords[0].value' `
            --output 'tsv'
    )

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_PUBLIC_USER `
        --value $__ACR_PUBLIC_USER `
        --query 'name' | Write-Info -Color DarkGray

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_PUBLIC_PASS `
        --value $__ACR_PUBLIC_PASS_VALUE `
        --query 'name' | Write-Info -Color DarkGray
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 6 -DoTitle 'Creating container-registry: Import' -DoScript {

    Remove-WhenFoundAzResourceGroup $__ACR_IMPORT_RG

    AzCli group create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --name $__ACR_IMPORT_RG `
        --query 'name' | Write-Info -Color DarkGray

    AzCli acr create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --resource-group $__ACR_IMPORT_RG `
        --name $__ACR_IMPORT `
        --sku 'Premium' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Creating task'
    AzCli acr task create `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_IMPORT_RG `
        --registry $__ACR_IMPORT `
        --name $__ACR_IMPORT_TASK `
        --assign-identity '[system]' `
        --context "$__ACR_IMPORT_GIT" `
        --git-access-token "$__GIT_TOKEN_VALUE" `
        --commit-trigger-enabled true `
        --base-image-trigger-enabled true `
        --file $__ACR_TASK_YAML `
        --set "FROM_REGISTRY_URL=$__ACR_PUBLIC_URL/" `
        --image 'node:15-alpine' `
        --image 'node:15-alpine-{{.Run.ID}}' |
        Write-Info -Color Magenta

    AzCli acr task credential add `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_IMPORT_RG `
        --registry $__ACR_IMPORT `
        --name $__ACR_IMPORT_TASK `
        --login-server $__ACR_PUBLIC_URL `
        --username "https://$__AKV.vault.azure.net/secrets/$__ACR_PUBLIC_USER" `
        --password "https://$__AKV.vault.azure.net/secrets/$__ACR_PUBLIC_PASS" `
        --use-identity '[system]' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Granting task access to key-vault'
    $__ACR_IMPORT_TASK_ID = $(
        AzCli acr task show `
            --subscription $__SUBSCRIPTION `
            --resource-group $__ACR_IMPORT_RG `
            --registry $__ACR_IMPORT `
            --name $__ACR_IMPORT_TASK `
            --query 'identity.principalId' `
            --output 'tsv'
    )

    AzCli keyvault set-policy `
        --subscription $__SUBSCRIPTION `
        --resource-group $__AKV_RG `
        --name $__AKV `
        --object-id $__ACR_IMPORT_TASK_ID `
        --secret-permissions 'get' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Started running task'
    AzCli acr task run `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_IMPORT_RG `
        --registry $__ACR_IMPORT `
        --name $__ACR_IMPORT_TASK

    Write-Verbose "Finished running task => Showing tags of 'node' repository"
    AzCli acr repository show-tags `
        --name $__ACR_IMPORT `
        --repository 'node'



    Write-Verbose 'Creating user with pull authorization'
    $__ACR_IMPORT_PASS_VALUE = $(
        AzCli acr token create `
            --subscription $__SUBSCRIPTION `
            --resource-group $__ACR_IMPORT_RG `
            --name $__ACR_IMPORT_USER `
            --registry $__ACR_IMPORT `
            --scope-map '_repositories_pull' `
            --query 'credentials.passwords[0].value' `
            --output 'tsv'
    )

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_IMPORT_USER `
        --value $__ACR_IMPORT_USER `
        --query 'name' | Write-Info -Color DarkGray

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_IMPORT_PASS `
        --value $__ACR_IMPORT_PASS_VALUE `
        --query 'name' | Write-Info -Color DarkGray
}



# ---------------------------------------------------------------------------------------------
Invoke-Step -When 7 -DoTitle 'Creating container-registry: Target' -DoScript {

    Remove-WhenFoundAzResourceGroup $__ACR_TARGET_RG

    AzCli group create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --name $__ACR_TARGET_RG `
        --query 'name' | Write-Info -Color DarkGray

    AzCli acr create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --resource-group $__ACR_TARGET_RG `
        --name $__ACR_TARGET `
        --sku 'Premium' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Creating container-instances'
    AzCli group create `
        --subscription $__SUBSCRIPTION `
        --location $__LOCATION `
        --name $__ACI_RG `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Creating task'
    AzCli acr task create `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_TARGET_RG `
        --registry $__ACR_TARGET `
        --name $__ACR_TARGET_TASK `
        --assign-identity '[system]' `
        --Context "$__ACR_TARGET_GIT" `
        --git-access-token "$__GIT_TOKEN_VALUE" `
        --file $__ACR_TASK_YAML `
        --set "FROM_REGISTRY_URL=$__ACR_IMPORT_URL/" `
        --set "TARGET_IMAGEREPO=$__ACR_TARGET_REPO" `
        --set "DEPLOY_USERNAME_URL=https://$__AKV.vault.azure.net/secrets/$__ACR_TARGET_USER" `
        --set "DEPLOY_PASSWORD_URL=https://$__AKV.vault.azure.net/secrets/$__ACR_TARGET_PASS" `
        --set "ACI_SUB=$__ACI_SUB" `
        --set "ACI_LOC=$__ACI_LOC" `
        --set "ACI_RG=$__ACI_RG" `
        --set "ACI_NAME=$__ACI_NAME" `
        --image '{{.Values.TARGET_IMAGEREPO}}:{{.Run.ID}}' |
        Write-Info -Color Magenta

    AzCli acr task credential add `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_TARGET_RG `
        --registry $__ACR_TARGET `
        --name $__ACR_TARGET_TASK `
        --login-server $__ACR_IMPORT_URL `
        --username "https://$__AKV.vault.azure.net/secrets/$__ACR_IMPORT_USER" `
        --password "https://$__AKV.vault.azure.net/secrets/$__ACR_IMPORT_PASS" `
        --use-identity '[system]' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Granting task access to key-vault'
    $__ACR_TARGET_TASK_ID = $(
        AzCli acr task show `
            --subscription $__SUBSCRIPTION `
            --resource-group $__ACR_TARGET_RG `
            --registry $__ACR_TARGET `
            --name $__ACR_TARGET_TASK `
            --query 'identity.principalId' `
            --output 'tsv'
    )

    AzCli keyvault set-policy `
        --subscription $__SUBSCRIPTION `
        --resource-group $__AKV_RG `
        --name $__AKV `
        --object-id $__ACR_TARGET_TASK_ID `
        --secret-permissions 'get' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Assigning task to owner role of container-instances'
    $__ACI_RG_ID = $(
        AzCli group show `
            --name $__ACI_RG `
            --query 'id' `
            --output 'tsv'
    )

    AzCli role assignment create `
        --assignee $__ACR_TARGET_TASK_ID `
        --scope $__ACI_RG_ID `
        --role 'owner' `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Creating user with pull authorization'
    $__ACR_TARGET_PASS_VALUE = $(
        AzCli acr token create `
            --subscription $__SUBSCRIPTION `
            --resource-group $__ACR_TARGET_RG `
            --name $__ACR_TARGET_USER `
            --registry $__ACR_TARGET `
            --repository $__ACR_TARGET_REPO 'content/read' 'metadata/read' `
            --query 'credentials.passwords[0].value' `
            --output 'tsv'
    )

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_TARGET_USER `
        --value $__ACR_TARGET_USER `
        --query 'name' | Write-Info -Color DarkGray

    AzCli keyvault secret set `
        --subscription $__SUBSCRIPTION `
        --vault-name $__AKV `
        --name $__ACR_TARGET_PASS `
        --value $__ACR_TARGET_PASS_VALUE `
        --query 'name' | Write-Info -Color DarkGray



    Write-Verbose 'Started running task'
    AzCli acr task run `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACR_TARGET_RG `
        --registry $__ACR_TARGET `
        --name $__ACR_TARGET_TASK

    Write-Verbose 'Finished running task => Showing ip-address of deployed container'
    AzCli container show `
        --subscription $__SUBSCRIPTION `
        --resource-group $__ACI_RG `
        --name $__ACI_NAME `
        --query 'ipAddress.ip' `
        --out 'tsv'
}
