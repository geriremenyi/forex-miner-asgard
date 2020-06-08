function Get-ArmTemplates
{
    [CmdletBinding()]

    $ErrorActionPreference = 'Stop'

    $ArmTemplates = Get-ChildItem (Join-Path -Resolve $PSScriptRoot '..\templates') -Recurse -Directory

    return $ArmTemplates
}