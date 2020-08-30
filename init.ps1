[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage='Should be the module reload forced or not, used for local development to force to work with latest ps1 files.')]
    [switch] $Force
)

$ErrorActionPreference = 'Stop'

# Import infra powershell module
$ModulePath = Join-Path -Resolve $PSScriptRoot 'src\ForexMinerAsgard.psm1'
Import-Module -Name $ModulePath -Force:$Force

# Install prerequisites
Install-AzPowerShellModule

# Connect to the forex-miner Azure subscription
Connect-AzureSubscription