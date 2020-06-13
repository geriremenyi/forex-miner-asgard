# This function is needed because currently ARM templates can't handle local files in lin URIs
# https://github.com/microsoft/vscode-azurearmtools/issues/588
function Expand-LinkedArmTemplates
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage='The template file to expand')]
        [string] $ArmTemplateFilePath
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
    foreach ($LinkedDeployment in $LinkedDeployments)
    {
        $LinkedLocalTemplateFile = $LinkedDeployment.properties.templateLink | Where-Object { !([string]::IsNullOrEmpty($_.uri)) -and !($_.uri -contains 'http:' -or $_.uri -contains 'https://') }
        $LinkedLocalParametersFile = $LinkedDeployment.properties.parametersLink | Where-Object { !([string]::IsNullOrEmpty($_.uri)) -and !($_.uri -contains 'http:' -or $_.uri -contains 'https://') }

        if($LinkedLocalParametersFile)
        {
             # Expand parameters link
             $ParametersFileFullPath = Join-Path -Resolve (Split-Path $ArmTemplateFilePath -Parent) $LinkedLocalParametersFile.uri
             if (!(Test-Path $ParametersFileFullPath))
             {
                throw "[Expand-LinkedArmTemplates] The given ARM parameters path '$TemplateFileFullPath' doesn't exist in the template file 'ArmTemplateFilePath'"
             }
             $LinkedDeployment.properties | Add-Member -NotePropertyName parameters -NotePropertyValue ((Get-Content $ParametersFileFullPath) | Out-String | ConvertFrom-Json)
             $LinkedDeployment.properties.PSObject.Properties.Remove('parametersLink')
        }
        
        if($LinkedLocalTemplateFile)
        {
            # Expand template link
            $TemplateFileFullPath = Join-Path -Resolve (Split-Path $ArmTemplateFilePath -Parent) $LinkedLocalTemplateFile.uri
            if (!(Test-Path $TemplateFileFullPath))
            {
                throw "[Expand-LinkedArmTemplates] The given ARM template path '$TemplateFileFullPath' doesn't exist in the template file 'ArmTemplateFilePath'"
            }
            $LinkedDeployment.properties | Add-Member -NotePropertyName template -NotePropertyValue ((Get-Content $TemplateFileFullPath) | Out-String | ConvertFrom-Json)
            $LinkedDeployment.properties.PSObject.Properties.Remove('templateLink')
        }

        if($LinkedLocalParametersFile -or $LinkedLocalTemplateFile)
        {
            # There was an expansion so a new deployment json file must be created
            $NewTempArmFilePath = Join-Path $PSScriptRoot "..\..\temp\arm\$((New-Guid).Guid).json"
            New-Item $NewTempArmFilePath -Force | Out-Null
            Set-Content $NewTempArmFilePath -Value ($ArmJson | ConvertTo-Json -Depth 100 -Compress)

            if ($LinkedLocalTemplateFile)
            {
                # There was a template expansion so there is a chance that there are more linked templates in the newly expanded template file
                # Recursively call this function to expand even more if needed
                Expand-LinkedArmTemplates -ArmTemplateFilePath (Resolve-Path $NewTempArmFilePath).Path | Out-Null
            }

            return (Resolve-Path $NewTempArmFilePath).Path
        }

        return $ArmTemplateFilePath
    }

    return $ArmTemplateFilePath
}