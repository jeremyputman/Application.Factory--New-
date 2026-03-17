<#
.SYNOPSIS
    Removes an application configuration via API.
.DESCRIPTION
    Sends a DELETE request to the API to remove the application configuration with the specified ID.
.PARAMETER id
    The unique identifier of the application configuration to remove. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Remove-AFAppConfig -id '12345'
#>
function Remove-AFAppConfig{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$id
  )
  # Check for required API header
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint for API request
  $endpoint = "$($script:api_uri)api/v1/config/$id/"    
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Delete
    return $response
  }
  catch{
    # Handle and report API errors
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to delete app config. $error_message"
  }  
}