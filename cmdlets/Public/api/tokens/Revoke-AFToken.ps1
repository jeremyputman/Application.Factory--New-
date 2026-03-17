<#
.SYNOPSIS
    Revokes a token via API.
.DESCRIPTION
    Sends a PATCH request to the API to revoke the token with the specified prefix, setting the revoked_at timestamp.
.PARAMETER prefix
    The prefix of the token to revoke. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Revoke-AFToken -prefix 'Token1'
#>
function Revoke-AFToken{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][string]$prefix
  )
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint for API call
  $endpoint = "$($script:api_uri)api/v1/tokens/$($prefix)"
  try{
    # Prepare request body with revoked_at timestamp
    $body = @{
      "revoked_at" = (Get-Date).ToString("o")
    }
    # Attempt to send the API PATCH request
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Patch -body $($body | ConvertTo-Json -Depth 3)
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to revoke token. $_"
  }
}
