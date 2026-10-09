function ConvertTo-AFNativeAssignmentBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Assignment
  )

  # Validate supported target types using the existing key helper.
  Get-AFClientAssignmentKey -Assignment $Assignment | Out-Null

  if (
    [string]$Assignment.intent -notin @(
      "available",
      "required",
      "uninstall",
      "availableWithoutEnrollment"
    )
  ) {
    throw "Unsupported assignment intent: $($Assignment.intent)"
  }

  $sourceTarget = $Assignment.target
  $target = @{
    "@odata.type" = "#" + (
      [string]$sourceTarget.'@odata.type'
    ).TrimStart('#')
  }

  if ($sourceTarget.groupId) {
    $target.groupId = [string]$sourceTarget.groupId
  }

  $filterType = [string]$sourceTarget.deviceAndAppManagementAssignmentFilterType

  if (-not $filterType) {
    $filterType = "none"
  }

  if ($filterType -notin @("none", "include", "exclude")) {
    throw "Unsupported assignment filter mode: $filterType"
  }

  $filterId = [string]$sourceTarget.deviceAndAppManagementAssignmentFilterId

  if ($filterType -ne "none" -and -not $filterId) {
    throw "An include/exclude assignment filter requires a filter ID."
  }

  if ($filterType -eq "none") {
    $filterId = ""
  }

  $target.deviceAndAppManagementAssignmentFilterId = $filterId
  $target.deviceAndAppManagementAssignmentFilterType =
  $filterType.ToLowerInvariant()

  $settings = $null

  if ($null -ne $Assignment.settings) {
    $settings = ConvertFrom-Json `
      -InputObject (
      ConvertTo-Json -InputObject $Assignment.settings -Depth 30
    ) `
      -AsHashtable

    $settingsType = (
      [string]$settings["@odata.type"]
    ).TrimStart('#')

    if (
      $settingsType -ne
      "microsoft.graph.win32LobAppAssignmentSettings"
    ) {
      throw "Unsupported assignment settings type: $settingsType"
    }

    $settings["@odata.type"] =
    "#microsoft.graph.win32LobAppAssignmentSettings"

    # Retain the documented Win32 settings, including nested settings.
    $allowedSettings = @(
      "@odata.type",
      "notifications",
      "restartSettings",
      "installTimeSettings",
      "deliveryOptimizationPriority",
      "autoUpdateSettings"
    )

    foreach ($name in @($settings.Keys)) {
      if ($name -in @("@odata.context", "@odata.etag")) {
        $settings.Remove($name)
      }
      elseif ($name -notin $allowedSettings) {
        throw (
          "Unrecognized Win32 assignment setting '$name'. " +
          "Stopped rather than silently dropping it."
        )
      }
    }
  }

  # Do not copy assignment IDs or source/sourceId from another app.
  return [PSCustomObject]@{
    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
    intent        = [string]$Assignment.intent
    target        = [PSCustomObject]$target
    settings      = $settings
  }
}