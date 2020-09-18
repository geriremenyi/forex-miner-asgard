function Test-ArmTemplateDeployment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the template should be tested agains')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The template file to test')]
        [string] $ArmTemplateFileName = 'ForexMiner.template.json',
        [Parameter(Mandatory=$false, HelpMessage='The parameters file for the template file to test')]
        [string] $ArmParametersFileName = $null
    )

    # Preferences 
    $ErrorActionPreference = 'Stop'

    # Connect to Azure subscription
    Connect-AzureSubscription -Subscription $Subscription

    # Check that the resource group exist
    Write-Host "[Test-ArmTemplateDeployment] Checking that '$ResourceGroupName' resource group exists..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if($ResourceGroup)
    {
        Write-Host 'OK' -ForegroundColor Green
    } else {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplateDeployment] Resource group '$ResourceGroupName' doesn't exist"
    }

    # Testing the ARM template file path
    $TemplateFolder = Join-Path -Resolve $PSScriptRoot '..\arm-templates'
    Write-Host "[Test-ArmTemplateDeployment] Searching for the template file '$ArmTemplateFileName' in the template folder '$TemplateFolder'..." -NoNewline
    $ArmTemplateFile = Get-ChildItem $TemplateFolder -Recurse -Filter $ArmTemplateFileName -ErrorAction SilentlyContinue
    if ($ArmTemplateFile)
    {
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplateDeployment] Template file '$ArmTemplateFileName' doesn't exist in the 'TemplateFolder' folder"
    }

    # Searching for the ARM parameters file (if given)
    $ArmParametersFilePassed = ($ArmParametersFileName -and !([string]::IsNullOrEmpty($ArmParametersFileName)))
    if($ArmParametersFilePassed)
    {
        Write-Host "[New-ArmTemplateDeployment] Searching for the parameters file '$ArmParametersFileName' in the template folder '$TemplateFolder'..." -NoNewline
        $ArmParametersFile = Get-ChildItem $TemplateFolder -Recurse -Filter $ArmParametersFileName -ErrorAction SilentlyContinue
        if($ArmParametersFile)
        {
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
        else {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[New-ArmTemplateDeployment] The parameters file '$ArmParametersFileName' doesn't exist in the template folder '$TemplateFolder'"     
        }
    }

    # Cleanup timestamped ARM folder (if folder already exists)
    $OutFolderTimestamp = (Get-Date -format "yyyy-MM-dd_HH-mm").ToString()
    Resolve-Path (Join-Path $PSScriptRoot "..\..\out\arm\test\$($OutFolderTimestamp)") -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Testing the ARM template against the resource group
    try {
        Write-Host "[Test-ArmTemplateDeployment] Testing template file '$ArmTemplateFileName'$(if ($ArmParametersFilePassed) { "with parameters file '$ArmParametersFileName'" }) against the resource group '$($ResourceGroup.ResourceGroupName)'..." -NoNewline
        $ArmTemplateOutDirectoryPath = Join-Path $PSScriptRoot "..\..\out\arm\test\$($OutFolderTimestamp)"
        New-Item $ArmTemplateOutDirectoryPath -ItemType 'directory' -Force | Out-Null
        $ExpandedArmTemplateFilePath = Expand-LinkedArmTemplates -ArmTemplateFilePath $ArmTemplateFile.FullName -ArmTemplateOutDirectoryPath (Resolve-Path $ArmTemplateOutDirectoryPath).Path
        if($ArmParametersFilePassed)
        {
            $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath -TemplateParameterFile $ArmParametersFile.FullName
        }
        else
        {
            $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath
        }

        if($ArmErrors -and !([string]::IsNullOrEmpty($ArmErrors)))
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[Test-ArmTemplateDeployment] ARM template test failed. Errors: $($ArmErrors | ConvertTo-Json -Depth 100 -Compress)"
        }
        else
        {
            Write-Host 'OK' -ForegroundColor Green
        }
    }
    catch {
        # Custom thrown exception in template linking, already handled FAILED indicatior
        if ($_.Exception.Message -notlike '* ARM template test failed. Errors: *')
        {
            Write-Host 'FAILED' -ForegroundColor Red
        }
        throw $_
    }
}