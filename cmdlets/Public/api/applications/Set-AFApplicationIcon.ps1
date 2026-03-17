<#
.SYNOPSIS
    Uploads an icon for an application via API.
.DESCRIPTION
    Sends a POST request to the API to upload an icon file for the specified application.
.PARAMETER id
    The unique identifier for the application. (Mandatory)
.PARAMETER iconpath
    The file path to the icon to upload. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Set-AFApplicationIcon -id '12345' -iconpath 'C:\Icons\appicon.png'
#>
function Set-AFApplicationIcon{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][string]$iconpath
  ) 
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  # Prepare endpoint and form data for API call
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/icon"
  $form = @{
    icon = Get-Item -Path $iconpath
  }
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Post -Form $form
    return $response
  }
  catch{
    # Handle and report API errors
    Write-Error "Failed to upload application icon. $_"
  }
}