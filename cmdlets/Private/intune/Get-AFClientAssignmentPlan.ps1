function Get-AFClientAssignmentPlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][PSCustomObject]$Configuration,
    [object[]]$PreviousApps = @(),
    [switch]$CopyOnly,
    [string]$SeedAppId
  )

  $rows = @{}

  $sourceId = $SeedAppId

  if (
    -not $sourceId -and
    ($CopyOnly -or $Configuration.copy_previous_assignments) -and
    $PreviousApps.Count -gt 0
  ) {
    $source = $PreviousApps |
    Sort-Object createdDateTime -Descending |
    Select-Object -First 1

    $sourceId = [string]$source.id
  }

  if ($sourceId) {
    foreach ($assignment in @(
        Get-AFClientGraphCollection -Uri (
          "deviceAppManagement/mobileApps/$sourceId/assignments"
        )
      )) {
      $body = ConvertTo-AFNativeAssignmentBody -Assignment $assignment

      if (
        $Configuration.download_foreground -and
        $null -ne $body.settings
      ) {
        $body.settings["deliveryOptimizationPriority"] = "foreground"
      }

      $baseKey = Get-AFNativeAssignmentBaseKey -Assignment $body

      if ($rows.ContainsKey($baseKey)) {
        throw "Source application has duplicate target/intent assignments: $baseKey"
      }

      $rows[$baseKey] = $body
    }
  }

  if (-not $CopyOnly) {
    $sections = [ordered]@{
      assignment_available            = @("available", $false)
      assignment_available_exceptions = @("available", $true)
      assignment_required             = @("required", $false)
      assignment_required_exceptions  = @("required", $true)
      assignment_uninstall            = @("uninstall", $false)
      assignment_uninstall_exceptions = @("uninstall", $true)
    }

    foreach ($section in $sections.Keys) {
      foreach ($group in @($Configuration.$section)) {
        if ($null -eq $group) {
          continue
        }

        $name = [string]$group.name

        if ([string]::IsNullOrWhiteSpace($name)) {
          throw "An assignment in '$section' has no group name."
        }

        $exclude = [bool]$sections[$section][1]

        if (
          $exclude -and
          $name -in @("All Users", "All Devices")
        ) {
          throw "Use an exclusion group instead of excluding '$name'."
        }

        $target = @{
          deviceAndAppManagementAssignmentFilterId   = ""
          deviceAndAppManagementAssignmentFilterType = "none"
        }

        switch ($name) {
          "All Users" {
            $target["@odata.type"] =
            "#microsoft.graph.allLicensedUsersAssignmentTarget"
          }
          "All Devices" {
            $target["@odata.type"] =
            "#microsoft.graph.allDevicesAssignmentTarget"
          }
          default {
            $lookup = Get-AFClientUniqueGraphObject `
              -Resource "groups" `
              -DisplayName $name

            $target.groupId = [string]$lookup.id

            $target["@odata.type"] = if ($exclude) {
              "#microsoft.graph.exclusionGroupAssignmentTarget"
            }
            else {
              "#microsoft.graph.groupAssignmentTarget"
            }
          }
        }

        $body = [PSCustomObject]@{
          "@odata.type" = "#microsoft.graph.mobileAppAssignment"
          intent        = [string]$sections[$section][0]
          target        = [PSCustomObject]$target
          settings      = $null
        }

        $baseKey = Get-AFNativeAssignmentBaseKey -Assignment $body

        if ($rows.ContainsKey($baseKey)) {
          $existing = $rows[$baseKey]

          # Preserve the copied filter unless explicitly overridden.
          $body.target.deviceAndAppManagementAssignmentFilterId =
          $existing.target.deviceAndAppManagementAssignmentFilterId

          $body.target.deviceAndAppManagementAssignmentFilterType =
          $existing.target.deviceAndAppManagementAssignmentFilterType

          $body.settings = $existing.settings
        }
        elseif (-not $exclude) {
          $body.settings = @{
            "@odata.type"                =
            "#microsoft.graph.win32LobAppAssignmentSettings"
            notifications                = "showAll"
            deliveryOptimizationPriority = "notConfigured"
          }
        }

        if (
          $Configuration.download_foreground -and
          $null -ne $body.settings
        ) {
          $body.settings["deliveryOptimizationPriority"] = "foreground"
        }

        $rows[$baseKey] = ConvertTo-AFNativeAssignmentBody `
          -Assignment $body
      }
    }
  }

  $unfilteredAssignments = @(
    foreach ($key in @($rows.Keys | Sort-Object)) {
      $rows[$key]
    }
  )

  $assignments = @(
    Set-AFClientAssignmentPlanFilters `
      -Configuration $Configuration `
      -Assignments $unfilteredAssignments
  )

  [PSCustomObject]@{
    SourceAppId  = $sourceId
    Assignments  = $assignments
    ExpectedKeys = @(
      $assignments |
      ForEach-Object {
        Get-AFClientAssignmentKey -Assignment $_
      } |
      Sort-Object -Unique
    )
  }
}