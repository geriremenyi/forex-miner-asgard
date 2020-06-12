function Test-ArmTemplate
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The resource group which the template should be tested agains')]
        [string] $ResourceGroupName = 'forex-miner',
        [Parameter(Mandatory=$false, HelpMessage='The template file to test')]
        [string] $ArmTemplateFileName = 'ForexMiner.template.json',
        [Parameter(Mandatory=$false, HelpMessage='The parameters file for the template file to test')]
        [string] $ArmParametersFileName
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

    # Searching for the ARM template file
    Write-Host "[Test-ArmTemplate] Searching for the template file '$ArmTemplateFileName'..." -NoNewline
    $ArmTemplateFile = Get-ChildItem (Join-Path -Resolve $PSScriptRoot '..\templates') -Recurse -Filter $ArmTemplateFileName -ErrorAction SilentlyContinue
    if(!$ArmTemplateFile)
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplate] Template file '$ArmTemplateFileName' doesn't exist"
    }
    else {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Searching for the ARM parameters file (if given)
    if($ArmParametersFile)
    {
        Write-Host "[Test-ArmTemplate] Searching for the parameters file '$ArmParametersFileName'..." -NoNewline
        $ArmParametersFile = Get-ChildItem (Join-Path -Resolve $PSScriptRoot '..\templates') -Recurse -Filter $ArmParametersFileName -ErrorAction SilentlyContinue
        if(!$ArmParametersFile)
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw "[Test-ArmTemplate] Parameters file '$ArmParametersFile' doesn't exist"
        }
        else {
            Write-Host 'OK' -ForegroundColor Green

            Write-Host "[Test-ArmTemplate] Checking that the template and the parameters file are in the same folder..." -NoNewline
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

    # Testing the ARM template against the resource group
    if ($ArmParametersFile)
    {
        Write-Host "[Test-ArmTemplate] Testing teamplate file '$ArmTemplateFileName' and parameters file 'ArmParametersFileName' against the resource group '$($ResourceGroup.Name)'..." -NoNewline
        $ExpandedArmTemplate = Expand-LinkedArmTemplates -ArmTemplateFilePath $ArmTemplateFile.FullName
        $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplate -TemplateParameterFile $ArmParametersFile.FullName
    }
    else {
        Write-Host "[Test-ArmTemplate] Testing teamplate file '$ArmTemplateFileName' and parameters file 'ArmParametersFileName' against the resource group '$($ResourceGroup.Name)'..." -NoNewline
        $ExpandedArmTemplate = Expand-LinkedArmTemplates -ArmTemplateFilePath $ArmTemplateFile.FullName
        $ArmErrors = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroup.ResourceGroupName -TemplateFile $ExpandedArmTemplate
    }
    if($ArmErrors)
    {
        Write-Host 'FAILED' -ForegroundColor Red
        throw "[Test-ArmTemplate] ARM template test failed. Errors: $(($ArmErrors | Select-Object Message) -Join ", ")"
    }
    else 
    {
        Write-Host 'OK' -ForegroundColor Green
    }
}