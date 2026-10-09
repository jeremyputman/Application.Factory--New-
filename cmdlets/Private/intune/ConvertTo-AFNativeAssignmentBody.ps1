function ConvertTo-AFNativeAssignmentBody {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Assignment
  )

  Get-AFClientAssignmentKey -Assignment $Assignment | Out-Null

  if ([string]$Assignment.intent -notin @(
      "available",
      "required",
      "uninstall",
      "availableWithoutEnrollment"
    )) {
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

  $filterType = [string](
    $sourceTarget.deviceAndAppManagementAssignmentFilterType
  )

  if ([string]::IsNullOrWhiteSpace($filterType)) {
    $filterType = "none"
  }

  $filterType = $filterType.ToLowerInvariant()

  if ($filterType -notin @("none", "include", "exclude")) {
    throw "Unsupported assignment filter mode: $filterType"
  }

  $filterId = $null

  if ($filterType -ne "none") {
    $filterId = [string](
      $sourceTarget.deviceAndAppManagementAssignmentFilterId
    )

    $parsedFilterId = [guid]::Empty

    if (
      -not [guid]::TryParse($filterId, [ref]$parsedFilterId) -or
      $parsedFilterId -eq [guid]::Empty
    ) {
      throw "An include/exclude assignment filter requires a valid, nonempty GUID."
    }

    $filterId = $parsedFilterId.ToString()
  }

  # An unfiltered assignment must serialize the ID as JSON null,
  # rather than an empty string.
  $target.deviceAndAppManagementAssignmentFilterId = $filterId
  $target.deviceAndAppManagementAssignmentFilterType = $filterType

  $settings = $null

  if ($null -ne $Assignment.settings) {
    $settings = ConvertFrom-Json `
      -InputObject (
      ConvertTo-Json `
        -InputObject $Assignment.settings `
        -Depth 30
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

  # Exclude assignment IDs and source metadata from the payload.
  [PSCustomObject]@{
    "@odata.type" = "#microsoft.graph.mobileAppAssignment"
    intent        = [string]$Assignment.intent
    target        = [PSCustomObject]$target
    settings      = $settings
  }
}