function Set-AFAppConfig{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$id,
    [Parameter()][string]$application,
    [Parameter()][string]$client,
    [Alias("assignmentRequired")][Parameter()][string[]]$assignment_required,
    [Alias("assignmentRequiredExceptions")][Parameter()][string[]]$assignment_required_exceptions,
    [Alias("assignmentAvailable")][Parameter()][string[]]$assignment_available,
    [Alias("assignmentAvailableExceptions")][Parameter()][string[]]$assignment_available_exceptions,
    [Alias("assignmentUninstall")][Parameter()][string[]]$assignment_uninstall,
    [Alias("assignmentUninstallExceptions")][Parameter()][string[]]$assignment_uninstall_exceptions,
    [Parameter()][bool]$enabled = $false,
    [Alias("downloadForeground")][Parameter()][bool]$download_foreground = $false,
    [Alias("keepPreviousVersions")][Parameter()][int]$keep_previous_versions = 0,
    [Alias("copyPreviousAssignments")][Parameter()][bool]$copy_previous_assignments = $false,
    [Alias("unassignPreviousAssignments")][Parameter()][bool]$unassign_previous_assignments = $true,
    [Alias("espAssignments")][Parameter()][string]$esp_assignments,
    [Parameter()][string]$filters,
    [Alias("interactiveInstall")][Parameter()][bool]$interactive_install = $false,
    [Alias("interactiveUninstall")][Parameter()][bool]$interactive_uninstall = $false,
    [Parameter()][string]$versions
  )
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/config/$id/"
  $body = @{} + $PSBoundParameters
  $body.Remove("id") | Out-Null
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
    Write-Error "Failed to update app config. $error_message"
  }  
}