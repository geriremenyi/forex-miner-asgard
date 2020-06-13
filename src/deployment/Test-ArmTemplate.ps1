function Test-ArmTemplate
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the template should be tested agains')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The template file to test')]
        [string] $ArmTemplateFilePath = 'ForexMiner.template.json',
        [Parameter(Mandatory=$false, HelpMessage='The parameters file for the template file to test')]
        [string] $ArmParametersFilePath = $null
    )

    # Check that the resource group exist
    Write-Host "[Test-ArmTemplate] Checking that resource group '$ResourceGroupName' exist..." -NoNewline
    $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if(!$ResourceGroup)
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplate] Resource group '$ResourceGroupName' doesn't exist"
    } else {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Testing the ARM template file path
    Write-Host "[Test-ArmTemplate] Checking that template path '$ArmTemplateFilePath' exists..." -NoNewline
    if (!(Test-Path $ArmTemplateFilePath))
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplate] Template file '$ArmTemplateFilePath' doesn't exist"
    }
    else
    {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Searching for the ARM parameters file (if given)
    $ArmParametersFilePassed = ($ArmParametersFilePath -and !([string]::IsNullOrEmpty($ArmParametersFilePath)))
    if($ArmParametersFilePassed)
    {
        Write-Host "[Test-ArmTemplate] Checking that parameters path '$ArmParametersFilePath' exists..." -NoNewline
        if (!(Test-Path $ArmParametersFilePath))
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[Test-ArmTemplate] Parameters file '$ArmParametersFilePath' doesn't exist"
        }
    }

    # Cleanup temp ARM folder
    Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force

    # Testing the ARM template against the resource group
    try {
        Write-Host "[Test-ArmTemplate] Testing template file '$ArmTemplateFilePath' $(if ($ArmParametersFilePassed) { "and parameters file '$ArmParametersFilePath'" })against the resource group '$($ResourceGroup.ResourceGroupName)'..." -NoNewline
        $ExpandedArmTemplateFilePath = Expand-LinkedArmTemplates -ArmTemplateFilePath $ArmTemplateFilePath
        if($ArmParametersFilePassed)
        {
            $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath -TemplateParameterFile $ArmParametersFilePath
        }
        else
        {
            $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplateFilePath
        }

        if($ArmErrors -and !([string]::IsNullOrEmpty($ArmErrors)))
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[Test-ArmTemplate] ARM template test failed. Errors: $($ArmErrors | ConvertTo-Json -Depth 100 -Compress)"
        }
        else
        {
            Write-Host 'OK' -ForegroundColor Green
        }

        # Cleanup temp ARM folder
        Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
    }
    catch {
        # Custom thrown exception already handled FAILED indicatior
        if ($_.Exception.Message -notlike '* ARM template test failed. Errors: *')
        {
            Write-Host 'FAILED' -ForegroundColor Red
        }
        Resolve-Path (Join-Path $PSScriptRoot '..\..\temp\arm') -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
        throw $_
    }
}