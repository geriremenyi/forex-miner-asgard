Write-Host '[ForexMinerAsgard] Importing module files...' -NoNewline
try {
    foreach ($file in (Get-ChildItem $PSScriptRoot -Recurse -Filter '*.ps1'))
    {
        Write-Verbose "[ForexMinerAsgard] Loaded module file '$($file.FullName)'"
        . $file.FullName
        Export-ModuleMember -Function $file.BaseName -ErrorAction 'Stop'
    }
    Write-Host 'OK' -ForegroundColor Green
}
catch
{
    Write-Host 'FAILED' -ForegroundColor Red
    throw $_
}