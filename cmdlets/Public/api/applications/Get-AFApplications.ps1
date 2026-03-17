<#
.SYNOPSIS
    Retrieves application details from the Application Factory API.
.DESCRIPTION
    Calls the API to get details for a specific application or all applications if no ID is provided.
.PARAMETER id
    Optional. The ID or name of the application to retrieve.
.OUTPUTS
    Application object(s) from the API.
.EXAMPLE
    Get-AFApplications -id "AppNameOrId"
#>
function Get-AFApplications{
  [cmdletbinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
  # Validate API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }

  # Build endpoint URL
  $endpoint = "$($script:api_uri)api/v1/applications/"
  if($PSBoundParameters.ContainsKey('id')){
    $endpoint = "$($endpoint)$($id)"
  }

  # Call API and handle response
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve application list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }    
}