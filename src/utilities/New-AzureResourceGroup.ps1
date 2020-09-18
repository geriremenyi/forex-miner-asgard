function New-AzureResourceGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='The name of the resource group to create')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The GEO of the resource group')]
        [string] $Location = 'WestEurope'
    )

    # Preferences
    $ErrorActionPreference = 'Stop'

    # Connecting to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription

    # Check that resource group is not already there
    Write-Host "[New-AzureResourceGroup] Checking that the '$ResourceGroupName' resource group doesn't exist already..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($ResourceGroup) 
    {
        Write-Host 'FAILED' -ForegroundColor Yellow
        Write-Warning "[New-AzureResourceGroup] The '$ResourceGroupName' resource group exists. Skipping the creation..."
        return
    }
    else 
    {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Check that given location is available
    Write-Host "[New-AzureResourceGroup] Checking requested location '$Location'..." -NoNewline
    $RequestedLocation = Get-AzLocation | Where-Object {$_.Location -eq $Location.ToLower()}
    if ($RequestedLocation) 
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-AzureResourceGroup] The '$Location' location is not available for the '$Subscription' subscription."
    }

    # Try to create resource group
    try 
    {
        Write-Host "[New-AzureResourceGroup] Creating '$ResourceGroupName' resource group in '$Subscription' subscription..." -NoNewline
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-AzureResourceGroup] Failed to create '$ResourceGroupName' resource group in the '$Subscription' subscription."
    }
}