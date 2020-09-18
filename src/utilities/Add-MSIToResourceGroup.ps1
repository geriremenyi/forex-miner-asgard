function Add-MSIToResourceGroup
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',

        [Parameter(Mandatory=$false, HelpMessage='The name of the resource group in which the resource with the system assigned managed identity is in')]
        [string] $ResourceGroupName = 'forex-miner',

        [Parameter(Mandatory=$false, HelpMessage='The name of the resource which has a system assigned managed identity')]
        [string] $ResourceName = 'forexmineraks',

        [Parameter(Mandatory=$false, HelpMessage='The name of the resource group to add the role assignement to')]
        [string] $TargetResourceGroupName = 'forex-miner',

        [Parameter(Mandatory=$false, HelpMessage='Role to assign')]
        [string] $RoleDefinitionName = 'Contributor'
    )

    # Preferences
    $ErrorActionPreference = 'Stop'

    # Connecting to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription
    
    # Check that the resource group exists
    Write-Host "[Add-MSIToResourceGroup.ps1] Getting '$ResourceGroupName' resource group in '$Subscription' subscription..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($ResourceGroup)
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Add-MSIToResourceGroup.ps1] The '$ResourceGroupName' resource group doesn't exist in the '$Subscription' subscription."
    }

    # Check that the resource exist
    Write-Host "[Add-MSIToResourceGroup.ps1] Getting '$ResourceName' resource in '$ResourceGroupName' resource group..." -NoNewline
    $Resource = Get-AzResource -Name $ResourceName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if ($Resource)
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Add-MSIToResourceGroup.ps1] The '$ResourceName' resource doesn't exist in the '$ResourceGroupName' resource group."
    }

    # Check that the resource group has a system assigned managed service identity assigned
    Write-Host "[Add-MSIToResourceGroup.ps1] Checking that the '$ResourceName' has a managed identity..." -NoNewline
    if ($Resource.Identity -and $Resource.Identity.PrincipalId)
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Add-MSIToResourceGroup.ps1] The '$Resource' resource doesn't have a managed identity assigned."
    }

    # Assign the role to the resource's managed indentity on the target resource group
    Write-Host "[Add-MSIToResourceGroup.ps1] Adding '$ResourceName' resource to the '$ResourceGroupName' resource group as a(n) '$RoleDefinitionName'..." -NoNewline
    try 
    {
        $ServicePrincipal = Get-AzADServicePrincipal -ObjectId $Resource.Identity.PrincipalId
        if (!$ServicePrincipal)
        {
            throw "Service principal with id '$Resource.Identity.PrincipalId' could not be found."
        }
        New-AzRoleAssignment -ApplicationId $ServicePrincipal.ApplicationId -Scope $ResourceGroup.ResourceId -RoleDefinitionName $RoleDefinitionName | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Add-MSIToResourceGroup.ps1] Failed to add the '$ResourceName' resource to the '$ResourceGroupName' resource group as a(n) '$RoleDefinitionName'. Error: $_"
    }
}