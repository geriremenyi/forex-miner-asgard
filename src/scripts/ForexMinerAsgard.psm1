foreach ($file in (Get-ChildItem $PSScriptRoot -Recurse -Filter '*.ps1'))
{
    Write-Verbose "ForexMinerAsgard Module Loader loaded '$($file.FullName)'"
    . $file.FullName
    Export-ModuleMember -Function $file.BaseName -ErrorAction 'Stop'
}