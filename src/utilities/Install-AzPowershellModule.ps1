#Requires -RunAsAdministrator
function Install-AzPowerShellModule
{
    [CmdletBinding()]
    
    $ErrorActionPreference = 'Stop'

    # First check that AzureRM is installed and if it is delete all versions
    Write-Host '[Install-AzPowerShellModule] Checking if legacy AzureRM module is installed...' -NoNewline
    $AzureRMVersions = Get-InstalledModule -Name 'AzureRM' -AllVersions -ErrorAction SilentlyContinue
    if ($AzureRMVersions) {
        Write-Host 'INSTALLED' -ForegroundColor Yellow
        Write-Host '[Install-AzPowerShellModule] Removing AzureRM module...' -NoNewline
        foreach ($AzureRM in $AzureRMVersions)
        {
            try {
                Uninstall-Module -Name $AzureRM.Name -RequiredVersion $AzureRM.Version -Force
            }
            catch 
            {
                Write-Host 'FAILED' -ForegroundColor Red
                throw $_
            }
        }
        Write-Host 'OK' -ForegroundColor Green
    }
    else
    {
        Write-Host 'OK' -ForegroundColor Green
    }

    # Then check if Az is installed and install it if not
    Write-Host '[Install-AzPowerShellModule] Checking if Az module is installed...' -NoNewline
    $Az = Get-InstalledModule -Name 'Az' -ErrorAction SilentlyContinue
    if (!$Az)
    {
        Write-Host 'MISSING' -ForegroundColor Yellow

        # Check that nuget provider is installed, install if not
        Write-Host '[Install-AzPowerShellModule] Checking if Nuget package provider is available...' -NoNewline
        $NugetPackageProvider = Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue
        if (!$NugetPackageProvider)
        {
            Write-Host 'MISSING' -ForegroundColor Yellow
            Write-Host '[Install-AzPowerShellModule] Installing Nuget package provider...' -NoNewline
            try {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -ForceBootstrap | Out-Null   
            }
            catch {
                Write-Host 'FAILED' -ForegroundColor Red
                throw $_
            }
        }
        else
        {
            Write-Host 'OK' -ForegroundColor Green
        }
     
        # Eventually install Az
        Write-Host '[Install-AzPowerShellModule] Installing Az module...' -NoNewline
        try {
            Install-Module -Name Az -AllowClobber -Force | Out-Null
            Write-Host 'OK' -ForegroundColor Green
        }
        catch {
            Write-Host 'FAILED' -ForegroundColor Red
            throw $_
        }
    }
    else
    {
        Write-Host 'OK' -ForegroundColor Green
    }
}