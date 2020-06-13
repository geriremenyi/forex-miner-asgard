function New-ArmTemplateDeployment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the template should be tested agains')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The template file to test')]
        [string] $ArmTemplateFileName = 'ForexMiner.template.json',
        [Parameter(Mandatory=$false, HelpMessage='The parameters file for the template file to test')]
        [string] $ArmParametersFileName = $null
    )

    $ErrorActionPreference = 'Stop'

    # Find the template file in the templates directory by it's name
    $TemplateFolder = Join-Path -Resolve $PSScriptRoot '..\templates'
    Write-Host "[New-ArmTemplateDeployment] Searching for the template file '$ArmTemplateFileName' in the template folder '$TemplateFolder'..." -NoNewline
    $ArmTemplateFile = Get-ChildItem $TemplateFolder -Recurse -Filter $ArmTemplateFileName -ErrorAction SilentlyContinue
    if (!$ArmTemplateFile)
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[New-ArmTemplateDeployment] The template file '$ArmTemplateFileName' doesn't exist in the folder (and it's subfolders) '$TemplateFolder'"
    }
    else {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Find the parameters file in the templates directory by it's name (if parameters file parameter is passed)
    $ArmParametersFilePassed = ($ArmParametersFileName -and !([string]::IsNullOrEmpty($ArmParametersFileName)))
    if($ArmParametersFilePassed)
    {
        Write-Host "[New-ArmTemplateDeployment] Searching for the parameters file '$ArmParametersFileName' in the template folder '$TemplateFolder'..." -NoNewline
        $ArmParametersFile = Get-ChildItem $TemplateFolder -Recurse -Filter $ArmParametersFileName -ErrorAction SilentlyContinue
        if(!$ArmParametersFile)
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[New-ArmTemplateDeployment] The parameters file '$ArmParametersFileName' doesn't exist in the template folder '$TemplateFolder'"
        }
        else {
            Write-Host 'OK' -ForegroundColor Green

            Write-Host "[New-ArmTemplateDeployment] Checking that the template and the parameters file are in the same folder..." -NoNewline
            if($ArmTemplateFile.Parent.FullName -eq $ArmParametersFile.Parent.FullName)
            {
                Write-Host 'OK' -ForegroundColor Green
            }
            else
            {
                Write-Host 'FAILED' -ForegroundColor Yellow
            }
        }
    }

    # Test the template
    Test-ArmTemplate -ResourceGroupName $ResourceGroupName -ArmTemplateFilePath $ArmTemplateFile.FullName -ArmParametersFilePath $ArmParametersFile.FullName

    # Cleanup temp ARM folder
    Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Deploy the ARM template
    $ExpandedArmTemplateFilePath = Expand-LinkedArmTemplates -ArmTemplateFilePath $ArmTemplateFile.FullName
    try {
        $DeploymentName = $ArmTemplateFileName.Split('.')[0]
        Write-Host "[New-ArmTemplateDeployment] Deploying ARM template file '$ArmTemplateFileName'$(if ($ArmParametersFilePassed) { "with ARM parameters file '$ArmParametersFileName'" }) with the deployment name '$DeploymentName'..." -NoNewline
        if ($ArmParametersFilePassed)
        {
            New-AzResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath -TemplateParameterFile $ArmParametersFile.FullName
        }
        else {
            New-AzResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath
        }
        Write-Host 'OK' -ForegroundColor Green

        # Cleanup temp ARM folder
        Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    }
    catch {
        Write-Host 'FAILED' -ForegroundColor Red
        Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
        throw $_
    }
}