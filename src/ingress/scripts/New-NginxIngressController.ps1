function New-NginxIngressController
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the AKS cluster is in')]
        [string] $ResourceGroupName = 'forex-miner'
    )

    # Preferences 
    $ErrorActionPreference = 'Stop'

    # Connect to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription
 
    # Check that the resource group exist
    Write-Host "[New-NginxIngressController] Checking that '$ResourceGroupName' resource group exists..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if($ResourceGroup)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-NginxIngressController] Resource group '$ResourceGroupName' doesn't exist"
    }
 
    # Check that there is an IP address which can be used for inbound traffic
    Write-Host "[New-NginxIngressController] Checking that there an IP address in the '$ResourceGroupName' resource group..." -NoNewline
    $IpAddress = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    if($IpAddress)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-NginxIngressController] There is no IP address in the '$ResourceGroupName' resource group."
    }

    # Add nginx helm charts repo
    Write-Host "[New-NginxIngressController] Adding nginx ingress controller helm charts repo..." -NoNewline
    try 
    {
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx | Out-Null
        helm repo update | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    } 
    catch
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-NginxIngressController] An error occured while trying to add nginx ingress controller helm charts repo. Error: $_."
    }

    # Deploy helm charts
    Write-Host "[New-NginxIngressController] Deploying nginx ingress controller helm charts..." -NoNewline
    try 
    {
        helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress `
            --set controller.replicaCount=2 `
            --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux `
            --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux `
            --set controller.service.loadBalancerIP="$($IpAddress.IpAddress)" `
            --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-dns-label-name"="$ResourceGroupName" `
            --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-resource-group"="$ResourceGroupName" | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-NginxIngressController] An error occured while trying to deploy nginx ingress controller helm charts. Error: $_."
    }

}