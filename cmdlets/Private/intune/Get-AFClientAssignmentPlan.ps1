function Get-AFClientAssignmentPlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][PSCustomObject]$Configuration,
    [object[]]$PreviousApps = @(),
    [switch]$CopyOnly,
    [string]$SeedAppId
  )

  $filters = @{}
  $rows = @{}

  if (-not [string]::IsNullOrWhiteSpace(
      [string]$Configuration.filters
    )) {
    foreach ($entry in (
        [string]$Configuration.filters -split "::"
      )) {
      $parts = @(
        $entry -split ";" | ForEach-Object { $_.Trim() }
      )

      if (
        $parts.Count -ne 3 -or
        -not $parts[0] -or
        -not $parts[1] -or
        $parts[2] -notin @("include", "exclude")
      ) {
        throw "Invalid assignment filter entry: $entry"
      }

      if ($filters.ContainsKey($parts[0])) {
        throw "Duplicate assignment filter for '$($parts[0])'."
      }

      $filter = Get-AFClientUniqueGraphObject `
        -Resource "deviceManagement/assignmentFilters" `
        -DisplayName $parts[1]

      $filters[$parts[0]] = @{
        Id   = [string]$filter.id
        Type = $parts[2].ToLowerInvariant()
      }
    }
  }

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
      $type = ([string]$body.target.'@odata.type').TrimStart('#')
      $targetName = ""

      switch ($type) {
        "microsoft.graph.groupAssignmentTarget" {
          $group = Invoke-AFNativeGraphRequest `
            -Method GET `
            -Uri "groups/$($body.target.groupId)"

          $targetName = [string]$group.displayName
        }
        "microsoft.graph.exclusionGroupAssignmentTarget" {
          $group = Invoke-AFNativeGraphRequest `
            -Method GET `
            -Uri "groups/$($body.target.groupId)"

          $targetName = [string]$group.displayName
        }
        "microsoft.graph.allDevicesAssignmentTarget" {
          $targetName = "All Devices"
        }
        "microsoft.graph.allLicensedUsersAssignmentTarget" {
          $targetName = "All Users"
        }
      }

      if ($filters.ContainsKey($targetName)) {
        $body.target.deviceAndAppManagementAssignmentFilterId =
        $filters[$targetName].Id

        $body.target.deviceAndAppManagementAssignmentFilterType =
        $filters[$targetName].Type
      }

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

        if ($filters.ContainsKey($name)) {
          $body.target.deviceAndAppManagementAssignmentFilterId =
          $filters[$name].Id

          $body.target.deviceAndAppManagementAssignmentFilterType =
          $filters[$name].Type
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

  $assignments = @(
    foreach ($key in @($rows.Keys | Sort-Object)) {
      $rows[$key]
    }
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