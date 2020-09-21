function New-CertManager
{
    [CmdletBinding()]

    # Preferences 
    $ErrorActionPreference = 'Stop'

    # Adding cert-manager label
    Write-Host "[New-CertManager] Adding cert manager label to namespace..." -NoNewline
    try 
    {
        kubectl label namespace ingress cert-manager.io/disable-validation=true | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch 
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-CertManager] An error occured while adding the cert manager label. Error: $_."
    }

    # Add cert-manager helm charts repo
    Write-Host "[New-CertManager] Adding cert-manager helm charts repo..." -NoNewline
    try 
    {
        helm repo add jetstack https://charts.jetstack.io | Out-Null
        helm repo update | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    } 
    catch
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-CertManager] An error occured while trying to add cert-manager helm charts repo. Error: $_."
    }

    # Deploy helm charts
    Write-Host "[New-CertManager] Deploying cert-manager helm charts..." -NoNewline
    try 
    {
        helm install cert-manager --namespace ingress --version v0.16.1 --set installCRDs=true --set nodeSelector."beta\.kubernetes\.io/os"=linux jetstack/cert-manager | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-CertManager] An error occured while trying to deploy cert-manager helm charts. Error: $_."
    }

    # Adding cluster issuer
    Deploy-KubernetesResource -ResourceYamlFileName 'cluster-issuer-letsencrypt.yaml'
}