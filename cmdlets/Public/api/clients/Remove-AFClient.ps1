<#
.SYNOPSIS
    Removes a client via API.
.DESCRIPTION
    Sends a DELETE request to the API to remove the client with the specified ID.
.PARAMETER id
    The unique identifier or name of the client to remove. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Remove-AFClient -id 'Client1'
#>
function Remove-AFClient{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id
  )
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  # Prepare endpoint for API call
  $endpoint = "$($script:api_uri)api/v1/clients/$($id)"
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
    Write-Error "Failed to delete client. $error_message"
  }  
}