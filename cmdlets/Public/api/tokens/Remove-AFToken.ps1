<#
.SYNOPSIS
    Removes a token via API.
.DESCRIPTION
    Sends a DELETE request to the API to remove the token with the specified prefix.
.PARAMETER prefix
    The prefix of the token to remove. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Remove-AFToken -prefix 'Token1'
#>
function Remove-AFToken{
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
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Delete
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to delete token. $_"
  }
}
