function Invoke-AKSInitialization
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

    # Connect to the cluster
    Connect-AKSCluster -Subscription $Subscription -ResourceGroupName $ResourceGroupName

    # Create namespaces
    Deploy-KubernetesResource -ResourceYamlFileName 'namespace-ingress.yaml'
    Deploy-KubernetesResource -ResourceYamlFileName 'namespace-forex-miner.yaml'

    # Deploy NGINX ingress controller
    New-NginxIngressController -Subscription $Subscription -ResourceGroupName $ResourceGroupName

    # Deploy cert manager
    New-CertManager

    # Create ingress routes
    Deploy-KubernetesResource -ResourceYamlFileName 'service-forex-miner-sif.yaml'
    Deploy-KubernetesResource -ResourceYamlFileName 'ingress-forex-miner.yaml'
}