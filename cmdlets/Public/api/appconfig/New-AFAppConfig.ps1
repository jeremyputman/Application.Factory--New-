function New-AFAppConfig{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$application,
    [Parameter(Mandatory=$true)][string]$client,
    [Alias("assignmentRequired","RequiredAssignments")][Parameter()][string[]]$assignment_required,
    [Alias("assignmentRequiredExceptions", "RequiredExceptions")][Parameter()][string[]]$assignment_required_exceptions,
    [Alias("assignmentAvailable", "AvailableAssignments")][Parameter()][string[]]$assignment_available,
    [Alias("assignmentAvailableExceptions","AvailableExceptions")][Parameter()][string[]]$assignment_available_exceptions,
    [Alias("assignmentUninstall","UninstallAssignments")][Parameter()][string[]]$assignment_uninstall,
    [Alias("assignmentUninstallExceptions","UninstallExceptions")][Parameter()][string[]]$assignment_uninstall_exceptions,
    [Alias("AddToIntune")][Parameter()][bool]$enabled = $false,
    [Alias("downloadForeground","foreground")][Parameter()][bool]$download_foreground = $false,
    [Alias("keepPreviousVersions","KeepPrevious")][Parameter()][int]$keep_previous_versions = 0,
    [Alias("copyPreviousAssignments","CopyPrevious")][Parameter()][bool]$copy_previous_assignments = $false,
    [Alias("unassignPreviousAssignments","UnassignPrevious")][Parameter()][bool]$unassign_previous_assignments = $true,
    [Alias("espAssignments","espprofiles")][Parameter()][string]$esp_assignments,
    [Parameter()][string]$filters,
    [Alias("interactiveInstall")][Parameter()][bool]$interactive_install = $false,
    [Alias("interactiveUninstall")][Parameter()][bool]$interactive_uninstall = $false,
    [Parameter()][string]$versions
  )

  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $body = $PSBoundParameters
  $endpoint = "$($script:api_uri)api/v1/config/"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($body | ConvertTo-JSON -Depth 5) -Method Post
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to create app config. $error_message"
  }  
}
