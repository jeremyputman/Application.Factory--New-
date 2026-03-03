function Set-AFApplicationExitCode{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('ignore', 'reboot', 'success')][string]$type,
    [Parameter(Mandatory = $true)][int]$exitcode
  )  
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/exitcodes/$($section)/$($type)"
  $body = @{
    action = $action
    exitcode = $exitcode
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
    Write-Error "Failed to update exit codes for application. $error_message"
  }  
}