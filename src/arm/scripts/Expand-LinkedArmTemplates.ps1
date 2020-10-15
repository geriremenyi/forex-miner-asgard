# This function is needed because currently ARM templates can't handle local files in link URIs
# https://github.com/microsoft/vscode-azurearmtools/issues/588
function Expand-LinkedArmTemplates
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage='The template file to expand')]
        [string] $ArmTemplateFilePath,
        [Parameter(Mandatory=$true, HelpMessage='The output directory to generate the intermediate and final jsons to.')]
        [string] $ArmTemplateOutDirectoryPath,
        [Parameter(Mandatory=$false, HelpMessage='The list of already visited files')]
        [psobject[]] $VisitedArmTemplateFiles = @(@{}),
        [Parameter(Mandatory=$false, HelpMessage='Iteration counter')]
        [int] $IterationRound = 1
    )

    $ErrorActionPreference = 'Stop'

    # Check file existence
    if (!(Test-Path $ArmTemplateFilePath))
    {
        throw "[Expand-LinkedArmTemplates] The given ARM template '$TemplateFilePath' path doesn't exist"
    }

    # Search for local file system linked template/parameters reference
    $ArmJson = Get-Content $ArmTemplateFilePath | Out-String | ConvertFrom-Json
    $LinkedDeployments = $ArmJson.resources | Where-Object { $_.type -eq 'Microsoft.Resources/deployments' }
    $ExpansionHappened = $false
    $TemplateExpansionHappened = $false
    foreach ($LinkedDeployment in $LinkedDeployments)
    {

        $LinkedLocalTemplateFile = $LinkedDeployment.properties.templateLink | Where-Object { !([string]::IsNullOrEmpty($_.uri)) -and !($_.uri -contains 'http://' -or $_.uri -contains 'https://') }
        $LinkedLocalParametersFile = $LinkedDeployment.properties.parametersLink | Where-Object { !([string]::IsNullOrEmpty($_.uri)) -and !($_.uri -contains 'http://' -or $_.uri -contains 'https://') }

        if($LinkedLocalParametersFile)
        {
             # Expand parameters link
             $ParametersFileFullPath = Join-Path -Resolve (Split-Path $ArmTemplateFilePath -Parent) $LinkedLocalParametersFile.uri
             if (!(Test-Path $ParametersFileFullPath))
             {
                throw "[Expand-LinkedArmTemplates] The given ARM parameters path '$TemplateFileFullPath' doesn't exist in the template file 'ArmTemplateFilePath'"
             }
             $ParametersDefined = (Get-Content $ParametersFileFullPath | Out-String | ConvertFrom-Json).parameters
             if ($LinkedDeployment.Properties.parameters)
             {
                # Merge template with the inline defined params, inline comes first always
                $MergedParameters = Merge-ArmParameters -InlineParameters $LinkedDeployment.Properties.parameters -LinkedParameters $ParametersDefined
                $LinkedDeployment.Properties.PSObject.Properties.Remove('parameters')
                $LinkedDeployment.Properties | Add-Member -NotePropertyName parameters -NotePropertyValue $MergedParameters
             }
             else
             {
                $LinkedDeployment.Properties | Add-Member -NotePropertyName parameters -NotePropertyValue $ParametersDefined
             }
             $LinkedDeployment.Properties.PSObject.Properties.Remove('parametersLink')
             $ExpansionHappened = $true
        }
        
        if($LinkedLocalTemplateFile)  
        {
            # Check linked template file
            $TemplateFileFullPath = Join-Path -Resolve (Split-Path $ArmTemplateFilePath -Parent) $LinkedLocalTemplateFile.uri
            if (!(Test-Path $TemplateFileFullPath))
            {
                throw "[Expand-LinkedArmTemplates] The given ARM template path '$TemplateFileFullPath' doesn't exist in the template file 'ArmTemplateFilePath'"
            }

            # Check for cyclic dependencies to avoid endless recursion
            $CurrentArmTemplateFileAlreadyVisited = $VisitedArmTemplateFiles | Where-Object { $_.FileName -eq $TemplateFileFullPath }
            if($CurrentArmTemplateFileAlreadyVisited)
            {
                throw '[Expand-LinkedArmTemplates] There is a cycle in the linked ARM template files. Cannot expand.'
            }
            $VisitedArmTemplateFiles += @{ FileName =  $TemplateFileFullPath }

            # Expand linked template file
            $LinkedDeployment.properties | Add-Member -NotePropertyName template -NotePropertyValue ((Get-Content $TemplateFileFullPath) | Out-String | ConvertFrom-Json)
            $LinkedDeployment.properties.PSObject.Properties.Remove('templateLink')

            $ExpansionHappened = $true
            $TemplateExpansionHappened = $true
        }
    }

    if ($ExpansionHappened)
    {
        # There was an expansion so a new deployment json file must be created
        $NewArmFileName = "$([System.IO.Path]::GetFileNameWithoutExtension($ArmTemplateFilePath))$($IterationRound).json"
        $NewTempArmFilePath = Join-Path $ArmTemplateOutDirectoryPath $NewArmFileName
        New-Item $NewTempArmFilePath -Force | Out-Null
        Set-Content $NewTempArmFilePath -Value ($ArmJson | ConvertTo-Json -Depth 100 -Compress)

        if ($TemplateExpansionHappened)
        {
            # There was a template expansion so there is a chance that there are more linked templates in the newly expanded template file
            # Recursively call this function to expand even more if needed
            $IterationRound += 1
            Expand-LinkedArmTemplates `
                -ArmTemplateFilePath (Resolve-Path $NewTempArmFilePath).Path `
                -ArmTemplateOutDirectoryPath $ArmTemplateOutDirectoryPath `
                -VisitedArmTemplateFiles $VisitedArmTemplateFiles `
                -IterationRound $IterationRound `
            | Out-Null
        }

        return (Resolve-Path $NewTempArmFilePath).Path
    }
        
    return $ArmTemplateFilePath
}