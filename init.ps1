[CmdletBinding()]
param(
    [Parameter(
        Mandatory=$false, 
        HelpMessage='Service principal ApplicationId for SP Azure connection'
    )]
    [string] $ApplicationId,

    [Parameter(
        Mandatory=$false,
        HelpMessage='Service principal secret for SP Azure connection'
    )]
    [string] $Secret,

    [Parameter(
        Mandatory=$false,
        HelpMessage='Tenant ID for for SP Azure connection'
    )]
    [string] $Tenant='048fb62a-b5ac-48b3-99a2-d7f6bb7ff561',

    [Parameter(
        Mandatory=$false, 
        HelpMessage='Should be the module reload forced or not, used for local development to force to work with latest ps1 files.'
    )]
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# Import infra powershell module
$ModulePath = Join-Path -Resolve $PSScriptRoot 'src\ForexMinerAsgard.psm1'
Import-Module -Name $ModulePath -Force:$Force

# Install prerequisites
Install-AzPowerShellModule
Install-Helm
Install-Kubectl

# Connect to the forex-miner Azure subscription
if (
    $ApplicationId -and !([string]::IsNullOrEmpty($ApplicationId)) `
    -and $Secret -and !([string]::IsNullOrEmpty($Secret)) `
    -and $Tenant -and !([string]::IsNullOrEmpty($Tenant))
)
{
    Connect-AzureSubscription -ApplicationId $ApplicationId -Secret $Secret -Tenant $Tenant
}
else 
{
    Connect-AzureSubscription
}
