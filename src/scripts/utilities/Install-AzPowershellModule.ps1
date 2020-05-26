function Install-AzPowerShellModule()
{
    $ErrorActionPreference = 'Stop'

    # First check that AzureRM is installed and if it is delete all versions
    $AzureRMVersions = Get-InstalledModule -Name 'AzureRM' -AllVersions -ErrorAction SilentlyContinue
    if ($AzureRMVersions) {
        foreach ($AzureRM in $AzureRMVersions)
        {
            Uninstall-Module -Name $AzureRM.Name -RequiredVersion $AzureRM.Version -Force
        }
    }

    # Then check if Az is installed and install it if not
    try {
        Get-InstalledModule -Name 'Az' | Out-Null
    }
    catch {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force | Out-Null
    }  
}