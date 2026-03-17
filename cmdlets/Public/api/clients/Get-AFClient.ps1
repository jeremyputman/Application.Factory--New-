<#
.SYNOPSIS
    Retrieves client information via API.
.DESCRIPTION
    Sends a GET request to the API to retrieve client information. If an ID is provided, retrieves details for a specific client.
.PARAMETER id
    The unique identifier or name of the client. (Optional)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Get-AFClient -id 'Client1'
#>
function Get-AFClient{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint for API call
  $endpoint = "$($script:api_uri)api/v1/clients/"
  if($PSBoundParameters.ContainsKey('id')){
    $endpoint = "$($endpoint)$($id)"
  }
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to retrieve client list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }  
}