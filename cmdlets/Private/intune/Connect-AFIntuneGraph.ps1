function Connect-AFIntuneGraph {
    [CmdletBinding()]
    param([switch]$Force)

    $minimumLifetime = [TimeSpan]::FromMinutes(5)

    if (
        -not $Force.IsPresent -and
        $script:graph_access_token -and
        $script:graph_token_expires -and
        (($script:graph_token_expires - [DateTimeOffset]::UtcNow) -gt $minimumLifetime)
    ) {return}

    if ([string]::IsNullOrWhiteSpace($script:appregistration_tenant)) {
        throw "Intune Graph authentication failed: Tenant ID is not configured."
    }

    if ([string]::IsNullOrWhiteSpace($script:appregistration_client)) {
        throw "Intune Graph authentication failed: Client ID is not configured."
    }

    if ([string]::IsNullOrWhiteSpace($script:appregistration_secret)) {
        throw "Intune Graph authentication failed: Client secret is not configured."
    }

    $tokenUri = "https://login.microsoftonline.com/$($script:appregistration_tenant)/oauth2/v2.0/token"

    $body = @{
        client_id     = $script:appregistration_client
        client_secret = $script:appregistration_secret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    try {
        $response = Invoke-RestMethod `
            -Uri $tokenUri `
            -Method Post `
            -Body $body `
            -ContentType "application/x-www-form-urlencoded" `
            -ErrorAction Stop
    }
    catch {
        $message = $_.Exception.Message

        if ($_.ErrorDetails.Message) {
            $message = "$message - $($_.ErrorDetails.Message)"
        }

        throw "Unable to authenticate to Microsoft Graph. $message"
    }

    if ([string]::IsNullOrWhiteSpace($response.access_token)) {
        throw "Microsoft Graph authentication succeeded but no access token was returned."
    }

    $script:graph_access_token = $response.access_token
    $script:graph_token_expires = [DateTimeOffset]::UtcNow.AddSeconds(
        [int]$response.expires_in
    )

    if ($script:enable_logging) {
        Write-AFLogEntry `
            -Message "[Application Factory] :: Connected to Microsoft Graph." `
            -Tag "Intune"
    }
}