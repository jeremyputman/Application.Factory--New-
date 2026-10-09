function Get-AFClientAssignmentPlan {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][PSCustomObject]$Configuration,
    [object[]]$PreviousApps = @()
  )

  $filters = @{}
  $expected = [Collections.Generic.List[string]]::new()
  $baseTargets = @{}

  # Parse the existing GroupName;FilterName;Mode format.
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

  $assignments = [Collections.Generic.List[object]]::new()

  # Capture the source assignments before publishing or removing anything.
  if (
    $Configuration.copy_previous_assignments -and
    $PreviousApps.Count -gt 0
  ) {
    $source = $PreviousApps |
    Sort-Object createdDateTime -Descending |
    Select-Object -First 1

    foreach ($assignment in @(
        Get-AFClientGraphCollection -Uri (
          "deviceAppManagement/mobileApps/$($source.id)/assignments"
        )
      )) {
      # Clone the object before applying configured filter overrides.
      $copy = $assignment |
      ConvertTo-Json -Depth 20 |
      ConvertFrom-Json

      $type = ([string]$copy.target.'@odata.type').TrimStart('#')
      $targetName = ""

      switch ($type) {
        "microsoft.graph.groupAssignmentTarget" {
          $group = Invoke-AFNativeGraphRequest `
            -Method GET `
            -Uri "groups/$($copy.target.groupId)"

          $targetName = [string]$group.displayName
        }
        "microsoft.graph.exclusionGroupAssignmentTarget" {
          $group = Invoke-AFNativeGraphRequest `
            -Method GET `
            -Uri "groups/$($copy.target.groupId)"

          $targetName = [string]$group.displayName
        }
        "microsoft.graph.allDevicesAssignmentTarget" {
          $targetName = "All Devices"
        }
        "microsoft.graph.allLicensedUsersAssignmentTarget" {
          $targetName = "All Users"
        }
        default {
          throw "Cannot verify copied assignment type '$type'."
        }
      }

      if ($filters.ContainsKey($targetName)) {
        $copy.target | Add-Member `
          -NotePropertyName deviceAndAppManagementAssignmentFilterId `
          -NotePropertyValue $filters[$targetName].Id `
          -Force

        $copy.target | Add-Member `
          -NotePropertyName deviceAndAppManagementAssignmentFilterType `
          -NotePropertyValue $filters[$targetName].Type `
          -Force
      }

      $assignments.Add($copy)
    }
  }

  $sections = @{
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
        throw (
          "The existing assignment helper does not support " +
          "excluding '$name'. Use an exclusion group."
        )
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

      if ($filters.ContainsKey($name)) {
        $target.deviceAndAppManagementAssignmentFilterId =
        $filters[$name].Id

        $target.deviceAndAppManagementAssignmentFilterType =
        $filters[$name].Type
      }

      $assignments.Add([PSCustomObject]@{
          intent = [string]$sections[$section][0]
          target = [PSCustomObject]$target
        })
    }
  }

  foreach ($assignment in $assignments) {
    $key = Get-AFClientAssignmentKey -Assignment $assignment
    $baseKey = (
      $key.Split("|")[0..2] -join "|"
    )

    if (
      $baseTargets.ContainsKey($baseKey) -and
      $baseTargets[$baseKey] -ne $key
    ) {
      throw (
        "Copied and configured assignments specify conflicting " +
        "filters for the same target and intent: $baseKey"
      )
    }

    $baseTargets[$baseKey] = $key
    $expected.Add($key)
  }

  [PSCustomObject]@{
    ExpectedKeys = @($expected | Sort-Object -Unique)
  }
}