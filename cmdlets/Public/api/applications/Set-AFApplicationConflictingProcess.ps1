function Set-AFApplicationConflictingProcess{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('start', 'end')][string]$type,
    [Parameter(Mandatory = $true)][string]$process
  )  
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/conflictingprocesses/$($section)/$($type)"
  $body = @{
    action = $action
    process = $process
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
    Write-Error "Failed to update conflicting processes for application. $error_message"
  }    
}