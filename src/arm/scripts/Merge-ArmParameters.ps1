
function Merge-ArmParameters
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage='The parameters given inline. The values present here have bigger priority than in the linked parameters.')]
        [psobject] $InlineParameters,
        [Parameter(Mandatory=$true, HelpMessage='The parameters parsed from a linked parameters file. The inline parameters have priority over the values present here.')]
        [psobject] $LinkedParameters
    )

    foreach ($Parameter in $LinkedParameters.PSOBject.Properties)
    {
        if (!($InlineParameters.PSOBject.Properties | Where-Object {$_.Name -eq $Parameter.Name}))
        {
            $InlineParameters | Add-Member -NotePropertyName $Parameter.Name -NotePropertyValue $Parameter.Value
        }
    }

    return $InlineParameters
}