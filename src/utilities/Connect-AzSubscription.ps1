function Connect-AzSubscription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage='The subscription id to connect to')]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',
        [Parameter(Mandatory=$false, HelpMessage='Replace the standard popup login with managed identity authentication')]
        [switch] $UseManagedIdentity
    )

    $ErrorActionPreference = 'Stop'

    try {
        if ($UseManagedIdentity.IsPresent)
        {
            # With Managed Identity
            Write-Host "[Connect-AzSubscription] Connecting to Azure subscription '$($Subscription)' using Managed Identity..." -NoNewline
            Connect-AzAccount -Subscription $Subscription -Identity:$UseManagedIdentity | Out-Null
        }
        else 
        {
            # Without Managed Identity
            Write-Host "[Connect-AzSubscription] Connecting to Azure subscription '$($Subscription)' with login popup..." -NoNewline
            Connect-AzAccount -Subscription $Subscription | Out-Null
        }
        
        Write-Host 'OK' -ForegroundColor Green
    }
    catch {
        Write-Host 'FAILED' -ForegroundColor Red
        throw $_
    }
}