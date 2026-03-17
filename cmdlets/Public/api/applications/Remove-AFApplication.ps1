<#
.SYNOPSIS
    Removes an application from the Application Factory API.
.DESCRIPTION
    Calls the API to delete the specified application.
.PARAMETER id
    The ID or name of the application to remove.
.OUTPUTS
    API response object.
.EXAMPLE
    Remove-AFApplication -id "AppId"
#>
function Remove-AFApplication{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Delete
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to delete application. $error_message"
  }  

}