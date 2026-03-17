<#
.SYNOPSIS
    Creates a new client via API.
.DESCRIPTION
    Sends a POST request to the API to create a new client with the provided parameters.
.PARAMETER name
    The name of the client. (Mandatory)
.PARAMETER id
    The unique identifier for the client. (Optional)
.PARAMETER assigned_groups
    Array of assigned group names for the client. (Optional)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    New-AFClient -name 'Client1' -assigned_groups @('GroupA','GroupB')
#>
function New-AFClient{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$name,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
  )
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  # Prepare endpoint for API call
  $endpoint = "$($script:api_uri)api/v1/clients/"
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($PSBoundParameters | ConvertTo-JSON) -Method Post
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
    Write-Error "Failed to create client. $error_message"
  }  
}