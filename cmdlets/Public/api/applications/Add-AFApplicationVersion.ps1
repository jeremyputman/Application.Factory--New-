<#
.SYNOPSIS
    Adds a version to an application in the Application Factory API.
.DESCRIPTION
    Calls the API to add a new version to the specified application.
.PARAMETER id
    The ID of the application.
.PARAMETER versions
    The version(s) to add.
.OUTPUTS
    API response object.
.EXAMPLE
    Add-AFApplicationVersion -id "AppId" -versions "1.2.3"
#>
function Add-AFApplicationVersion{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter()][string]$versions
  )
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Base Endpoint for Applications
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/versions"
  $body = @{
    action = "add"
    version = $versions
  }
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($body | ConvertTo-JSON -Depth 5) -Method Patch
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to create application. $error_message"
  }    
}