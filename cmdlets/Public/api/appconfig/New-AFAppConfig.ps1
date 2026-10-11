<#
.SYNOPSIS
    Creates a new application configuration via API.
.DESCRIPTION
    Sends a POST request to the API to create a new application configuration with the provided parameters.
.PARAMETER application
    The name of the application to configure. (Mandatory)
.PARAMETER client
    The client name for the configuration. (Mandatory)
.PARAMETER assignment_required
    Array of required assignment group names.
.PARAMETER assignment_required_exceptions
    Array of required assignment exception group names.
.PARAMETER assignment_available
    Array of available assignment group names.
.PARAMETER assignment_available_exceptions
    Array of available assignment exception group names.
.PARAMETER assignment_uninstall
    Array of uninstall assignment group names.
.PARAMETER assignment_uninstall_exceptions
    Array of uninstall assignment exception group names.
.PARAMETER enabled
    Boolean to enable adding to Intune. Default: $false
.PARAMETER download_foreground
    Boolean to enable foreground download. Default: $false
.PARAMETER keep_previous_versions
    Number of previous versions to keep. Default: 0
.PARAMETER copy_previous_assignments
    Boolean to copy previous assignments. Default: $false
.PARAMETER unassign_previous_assignments
    Boolean to unassign previous assignments. Default: $true
.PARAMETER esp_assignments
    ESP assignment profiles string.
.PARAMETER filters
    Filter string for configuration.
.PARAMETER interactive_install
    Boolean to enable interactive install. Default: $false
.PARAMETER interactive_uninstall
    Boolean to enable interactive uninstall. Default: $false
.PARAMETER versions
    Version string for configuration.
.PARAMETER replace_in_place
    Replace the installer on the existing managed Intune app. False creates a new app.
.OUTPUTS
    The response from the API call.
.EXAMPLE
    New-AFAppConfig -application 'App1' -client 'Client1' -assignment_required @('GroupA') -enabled $true
#>
function New-AFAppConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$application,
    [Parameter(Mandatory = $true)][string]$client,
    [Alias("assignmentRequired", "RequiredAssignments")][Parameter()][string[]]$assignment_required,
    [Alias("assignmentRequiredExceptions", "RequiredExceptions")][Parameter()][string[]]$assignment_required_exceptions,
    [Alias("assignmentAvailable", "AvailableAssignments")][Parameter()][string[]]$assignment_available,
    [Alias("assignmentAvailableExceptions", "AvailableExceptions")][Parameter()][string[]]$assignment_available_exceptions,
    [Alias("assignmentUninstall", "UninstallAssignments")][Parameter()][string[]]$assignment_uninstall,
    [Alias("assignmentUninstallExceptions", "UninstallExceptions")][Parameter()][string[]]$assignment_uninstall_exceptions,
    [Alias("AddToIntune")][Parameter()][bool]$enabled = $false,
    [Alias("downloadForeground", "foreground")][Parameter()][bool]$download_foreground = $false,
    [Alias("keepPreviousVersions", "KeepPrevious")][Parameter()][int]$keep_previous_versions = 0,
    [Alias("copyPreviousAssignments", "CopyPrevious")][Parameter()][bool]$copy_previous_assignments = $false,
    [Alias("unassignPreviousAssignments", "UnassignPrevious")][Parameter()][bool]$unassign_previous_assignments = $true,
    [Alias("espAssignments", "espprofiles")][Parameter()][string]$esp_assignments,
    [Parameter()][string]$filters,
    [Alias("interactiveInstall")][Parameter()][bool]$interactive_install = $false,
    [Alias("interactiveUninstall")][Parameter()][bool]$interactive_uninstall = $false,
    [Parameter()][string]$versions,
    [Alias("replaceInPlace")][Parameter()][bool]$replace_in_place
  )

  # Check for required API header
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare request body and endpoint
  $body = $PSBoundParameters
  $endpoint = "$($script:api_uri)api/v1/config/"
  # Attempt to send the API request
  try {
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -ContentType "application/json" -body $($body | ConvertTo-JSON -Depth 5) -Method Post
    return $response
  }
  catch {
    # Handle and report API errors
    if (($_.ErrorDetails.Message | ConvertFrom-Json).detail) {
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else {
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to create app config. $error_message"
  }  
}
