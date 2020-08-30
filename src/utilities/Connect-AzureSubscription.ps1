function Connect-AzureSubscription
{
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$false,
            HelpMessage='The subscription id to connect to'
        )]
        [string] $Subscription = '565174da-8303-4991-96b0-1032d880541e',

        [Parameter(
            Mandatory=$false, 
            HelpMessage='Service principal ApplicationId'
        )]
        [string] $ApplicationId,

        [Parameter(
            Mandatory=$false,
            HelpMessage='Service principal secret'
        )]
        [string] $Secret,

        [Parameter(
            Mandatory=$false,
            HelpMessage='Tenant ID for ServicePrincipal authentication'
        )]
        [string] $Tenant='048fb62a-b5ac-48b3-99a2-d7f6bb7ff561'
    )

    # Preferences
    $ErrorActionPreference = 'Stop'

    # Variables
    $LoginRequired = $true;

    if(($AzureContext = Get-AzContext))
    {
        # There is already some azure login context
        if ($AzureContext.Subscription.ToString() -ne $Subscription.ToString())
        {
            # But that context is not the subscription requested
            try 
            {
                # Try to switch to the requested context
                Write-Host "[Connect-AzureSubscription] Switching from subscription '$($AzureContext.Subscription)' to '$($Subscription)'..." -NoNewline
                Set-AzContext -Subscription $Subscription
                Write-Host 'OK' -ForegroundColor Green
                $LoginRequired = $false
            }
            catch 
            {
                # It can happen that the switch fails due to the fact that there is a different 
                # entity logged in which doesn't have access to the subscription requested
                Write-Host 'FAILED' -ForegroundColor Red
                $LoginRequired = $true
            }
        }
        else 
        {
            Write-Host "[Connect-AzureSubscription] Connected to Azure subscription '$($Subscription)'..." -NoNewline
            Write-Host 'OK' -ForegroundColor Green
            $LoginRequired = $false
        }
    }
    
    if ($LoginRequired)
    {
        # Login is required
        try 
        {
            if (
                $ApplicationId -and !([string]::IsNullOrEmpty($ApplicationId)) `
                -and $Secret -and !([string]::IsNullOrEmpty($Secret)) `
                -and $Tenant -and !([string]::IsNullOrEmpty($Tenant))
            )
            {
                # With service principal if both ApplicationId and Secret are present
                Write-Host "[Connect-AzureSubscription] Connecting to Azure subscription '$($Subscription)' using a ServicePrincipal..." -NoNewline
                Write-Host "[Debug]"
                Write-Host "[Debug] $($Secret.ToString().length)"
                Write-Host "[Debug] $($ApplicationId.ToString().length)"
                Write-Host "[Debug] $($Tenant.ToString().length)"
                $ServicePrincipalCredentials = New-Object -TypeName System.Management.Automation.PSCredential($ApplicationId, ($Secret | ConvertTo-SecureString))
                Connect-AzAccount -Subscription $Subscription -ServicePrincipal -Credential $ServicePrincipalCredentials -Tenant $Tenant | Out-Null
            }
            else 
            {
                # With username and password popup if not
                Write-Host "[Connect-AzureSubscription] Connecting to Azure subscription '$($Subscription)' with a login popup..." -NoNewline
                Connect-AzAccount -Subscription $Subscription | Out-Null
            }
            
            Write-Host 'OK' -ForegroundColor Green
        }
        catch 
        {
            Write-Host 'FAILED' -ForegroundColor Red
            throw $_
        }   
    }
}