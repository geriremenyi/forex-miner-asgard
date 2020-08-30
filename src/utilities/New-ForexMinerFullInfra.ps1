function New-AForexMinerFullInfra
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to create the resource groups and resource in.')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='The name of the resource group')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The GEO of the resource group and resources')]
        [string] $Location = 'WestEurope',
        [Parameter(Mandatory=$false, HelpMessage='Is the infra deployment a test run and should be cleaned up after deployment?')]
        [switch] $TestDeployment
    )

    # Preferences
    $ErrorActionPreference = 'Stop'

    # Connect to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription

    try 
    {
        # Create main resource group
        New-AzureResourceGroup -Subscription $Subscription -ResourceGroupName $ResourceGroupName -Location $Location

        # Test ARM linked ARM templates
        Test-ArmTemplateDeployment -Subscription $Subscription -ResourceGroupName $ResourceGroupName

        # Deploy ARM template
        New-ArmTemplateDeployment -Subscription $Subscription -ResourceGroupName $ResourceGroupName
    }
    catch
    {
        # Delete main resource group
        Remove-AzureResourceGroup -Subscription $Subscription -ResourceGroupName $ResourceGroupName

        # Delete AKS resource group
        $AKSResourceGroupName = "$($ResourceGroupName)-aks"
        Remove-AzureResourceGroup -Subscription $Subscription -ResourceGroupName $AKSResourceGroupName

        # Throw error
        throw "[New-ForexMinerFullInfra] Deployment failed. Error: $_"
    }

    # Cleanup on test deployment
    if ($TestDeployment.IsPresent)
    {
        # Delete main resource group
        Remove-AzureResourceGroup -Subscription $Subscription -ResourceGroupName $ResourceGroupName

        # Delete AKS resource group
        $AKSResourceGroupName = "$($ResourceGroupName)-aks"
        Remove-AzureResourceGroup -Subscription $Subscription -ResourceGroupName $AKSResourceGroupName
    }
}