<#
.SYNOPSIS
    Updates an application configuration via API.
.DESCRIPTION
    Sends a PATCH request to the API to update the application configuration with the specified parameters.
.PARAMETER id
    The unique identifier of the application configuration to update. (Mandatory)
.PARAMETER application
    The name of the application to configure.
.PARAMETER client
    The client name for the configuration.
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
.OUTPUTS
    The response from the API call.
.EXAMPLE
    Set-AFAppConfig -id '12345' -application 'App1' -client 'Client1' -assignment_required @('GroupA') -enabled $true
#>
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
  # Check for required API header
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Prepare endpoint and request body for API call
  $endpoint = "$($script:api_uri)api/v1/config/$id/"
  $body = @{} + $PSBoundParameters
  $body.Remove("id") | Out-Null
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
    Write-Error "Failed to update app config. $error_message"
  }  
}