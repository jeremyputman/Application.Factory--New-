<#
.SYNOPSIS
    Retrieves the list of tokens via API.
.DESCRIPTION
    Sends a GET request to the API to retrieve all tokens.
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Get-AFTokenList
#>
function Get-AFTokenList{
  [CmdletBinding()]
  param()
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint for API call
  $endpoint = "$($script:api_uri)api/v1/tokens/"
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to retrieve token list. $_"
  }
}
