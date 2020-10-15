function Deploy-KubernetesResource
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage='The resource yaml file to deploy')]
        [string] $ResourceYamlFileName,

        [Parameter(Mandatory=$false, HelpMessage='The folder in which the resource file is in')]
        [string] $ResourceFolder
    )

    # Preferences 
    $ErrorActionPreference = 'Stop'

    # Find the resource yaml file
    Write-Host "[Deploy-KubernetesResource] Checking that '$ResourceYamlFileName' exists..." -NoNewline
    $KubernetesResourceFolder = Join-Path -Resolve $PSScriptRoot '../k8s'
    if ($ResourceFolder)
    {
        $KubernetesResourceFolder = (Resolve-Path $ResourceFolder).Path
    }
    $ResourceYamlFile = Get-ChildItem $KubernetesResourceFolder -Recurse -Filter $ResourceYamlFileName -ErrorAction SilentlyContinue
    if($ResourceYamlFile)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Deploy-KubernetesResource] '$ResourceYamlFileName' doesn't exist."
    }

    # Deploy the yaml
    Write-Host "[Deploy-KubernetesResource] Deploying '$ResourceYamlFileName'..." -NoNewline
    try {
        kubectl apply -f $ResourceYamlFile.FullName | Out-Null
        Write-Host 'OK' -ForegroundColor Green
    }
    catch {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Deploy-KubernetesResource] '$ResourceYamlFileName' deployment failed. Error: $_"
    }
}