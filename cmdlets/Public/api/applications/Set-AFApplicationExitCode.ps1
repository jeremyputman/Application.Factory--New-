<#
.SYNOPSIS
    Updates exit codes for an application via API.
.DESCRIPTION
    Sends a PATCH request to the API to add or remove an exit code for the specified application, section, and type.
.PARAMETER id
    The unique identifier for the application. (Mandatory)
.PARAMETER action
    The action to perform: 'add' or 'remove'. (Mandatory)
.PARAMETER section
    The section to update: 'install' or 'uninstall'. (Mandatory)
.PARAMETER type
    The type of exit code: 'ignore', 'reboot', or 'success'. (Mandatory)
.PARAMETER exitcode
    The exit code to add or remove. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Set-AFApplicationExitCode -id '12345' -action 'add' -section 'install' -type 'success' -exitcode 0
#>
function Set-AFApplicationExitCode{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('ignore', 'reboot', 'success')][string]$type,
    [Parameter(Mandatory = $true)][int]$exitcode
  )  
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  # Prepare endpoint and request body for API call
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/exitcodes/$($section)/$($type)"
  $body = @{
    action = $action
    exitcode = $exitcode
  }
  # Attempt to send the API request
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($body | ConvertTo-JSON -Depth 5) -Method Patch
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
    Write-Error "Failed to update exit codes for application. $error_message"
  }  
}