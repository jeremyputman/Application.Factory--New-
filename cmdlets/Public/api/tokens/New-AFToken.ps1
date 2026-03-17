<#
.SYNOPSIS
    Creates a new token via API.
.DESCRIPTION
    Sends a POST request to the API to create a new token with the provided name and expiration date.
.PARAMETER name
    The name of the token. (Mandatory)
.PARAMETER expires_at
    The expiration date and time for the token. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    New-AFToken -name 'Token1' -expires_at (Get-Date).AddDays(30)
#>
function New-AFToken{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][string]$name,
    [parameter(Mandatory = $true)][datetime]$expires_at
  )
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint and request body for API call
  $endpoint = "$($script:api_uri)api/v1/tokens/"
  try{
    $body = @{
      "name" = $name
      "expires_at" = $expires_at.ToString("o")
    }
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Post -body $($body | ConvertTo-Json -Depth 3)
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to create token. $_"
  }
}
