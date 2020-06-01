function Invoke-TestArmDeployment (
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $TemplateFile,
    [string] [Parameter(Mandatory=$true)] $ParametersFile
)
{
    $ErrorActionPreference = 'Stop'

    # Install Az powershell module if not already there
    . (Join-Path (Join-Path (Join-Path  $($PSScriptRoot) '..') 'utilities') 'Install-AzPowershellModule.ps1')
    Install-AzPowershellModule
}