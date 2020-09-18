function Remove-AzureResourceGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$true, HelpMessage='The name of the resource group to delete')]
        [string] $ResourceGroupName
    )

    # Preferences
    $ErrorActionPreference = 'Stop'

    # Connecting to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription

    # Check that the resource group exists
    Write-Host "[Remove-AzureResourceGroup] Getting '$ResourceGroupName' resource group in '$Subscription' subscription..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($ResourceGroup)
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'FAILED' -ForegroundColor Yellow
        Write-Warning "[Remove-AzureResourceGroup] The '$ResourceGroupName' resource group doesn't exist. Skipping the deletion..."
        return
    }

    # Delete resource group
    try 
    {
        Write-Host "[Remove-AzureResourceGroup] Deleting '$ResourceGroupName' resource group from '$Subscription' subscription..." -NoNewline
        $ResourceGroup | Remove-AzResourceGroup -Force | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Remove-AzureResourceGroup] Failed to delete '$ResourceGroupName' resource group from the '$Subscription' subscription."
    }
}