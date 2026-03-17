<#
.SYNOPSIS
    Updates a client via API.
.DESCRIPTION
    Sends a PATCH request to the API to update the client with the specified parameters.
.PARAMETER id
    The unique identifier or name of the client to update. (Mandatory)
.PARAMETER assigned_groups
    Array of assigned group names for the client. (Optional)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Set-AFClient -id 'Client1' -assigned_groups @('GroupA','GroupB')
#>
function Set-AFClient{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
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
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($PSBoundParameters | ConvertTo-JSON) -Method Patch
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
    Write-Error "Failed to update client. $error_message"
  }  
}