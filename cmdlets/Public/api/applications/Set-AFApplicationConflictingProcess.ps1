<#
.SYNOPSIS
    Updates conflicting processes for an application via API.
.DESCRIPTION
    Sends a PATCH request to the API to add or remove a conflicting process for the specified application, section, and type.
.PARAMETER id
    The unique identifier for the application. (Mandatory)
.PARAMETER action
    The action to perform: 'add' or 'remove'. (Mandatory)
.PARAMETER section
    The section to update: 'install' or 'uninstall'. (Mandatory)
.PARAMETER type
    The type of process: 'start' or 'end'. (Mandatory)
.PARAMETER process
    The name of the process to add or remove. (Mandatory)
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Set-AFApplicationConflictingProcess -id '12345' -action 'add' -section 'install' -type 'start' -process 'notepad.exe'
#>
function Set-AFApplicationConflictingProcess{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('start', 'end')][string]$type,
    [Parameter(Mandatory = $true)][string]$process
  )  
  # Check for required API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  # Prepare endpoint and request body for API call
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/conflictingprocesses/$($section)/$($type)"
  $body = @{
    action = $action
    process = $process
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
    Write-Error "Failed to update conflicting processes for application. $error_message"
  }    
}