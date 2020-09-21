function Connect-AKSCluster 
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id the AKS cluster is in')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the AKS cluster is in')]
        [string] $ResourceGroupName = 'forex-miner'
    )

    # Preferences 
    $ErrorActionPreference = 'Stop'

    # Connect to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription

    # Check that the resource group exist
    Write-Host "[Connect-AKSCluster] Checking that '$ResourceGroupName' resource group exists..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if($ResourceGroup)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Connect-AKSCluster] Resource group '$ResourceGroupName' doesn't exist"
    }

    # Check that there is an AKS cluster in that resource group
    Write-Host "[Connect-AKSCluster] Checking that there is an AKS cluster in the '$ResourceGroupName' resource group..." -NoNewline
    $AKSCluster = Get-AzAksCluster -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if($AKSCluster)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Connect-AKSCluster] There is no AKS cluster in the '$ResourceGroupName' resource group."
    }

    # Get AKS cluster credentials
    Write-Host "[Connect-AKSCluster] Importing credentials for '$($AKSCluster.Name)' AKS cluster..." -NoNewline
    try 
    {
        $AKSCluster | Import-AzAksCredential -Force | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Connect-AKSCluster] An error occured while importing cluster credentials. Error: $_"
    }
}