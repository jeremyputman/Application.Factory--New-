function Set-AFApplicationClientGroups {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$configuration,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )
  $sections = @("assignment_available", "assignment_available_exceptions", "assignment_required", "assignment_required_exceptions", "assignment_uninstall", "assignment_uninstall_exceptions")
  $graph_header = @{
    "content-type"  = "application/json"
    "Authorization" = "Bearer $($global:AccessToken.AccessToken)"
  }
  $filter_split = $configuration.filters -split "::"
  $filters = @{}
  foreach ($filter in $filter_split) {
    $filter_details = $filter -split ";"
    $filters.Add($filter_details[0], @{name = $filter_details[1]; type = $filter_details[2] })
  }
  $originalWarningPreference = $WarningPreference
  $WarningPreference = 'SilentlyContinue'
  foreach ($section in $sections) {
    $details = $configuration.$section
    if ($details) {
      if ($script:enable_logging) {
        Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Setting group assignments for $section." -Level $LogLevel -Tag "Groups", $configuration.application.Name -Target "Application Factory Client"
      }
      foreach ($group in $details) {
        $params = @{
          "id" = $script:published_application.id
        }
        if ($filters.$($group.name)) {
          $params.Add("FilterName", $filters.$($group.name).name)
          $params.Add("FilterMode", $filters.$($group.name).type)
        }
        if ($configuration.download_foreground) {
          $params.Add("DeliveryOptimizationPriority", "foreground")
        }
        switch ($section) {
          "assignment_available" {
            $params.Add("Include", $true)
            $params.Add("Intent", "available")
          }
          "assignment_available_exceptions" {
            $params.Add("Exclude", $true)
            $params.Add("Intent", "available")
          }
          "assignment_required" {
            $params.Add("Include", $true)
            $params.Add("Intent", "required")
          }
          "assignment_required_exceptions" {
            $params.Add("Exclude", $true)
            $params.Add("Intent", "required")
          }
          "assignment_uninstall" {
            $params.Add("Include", $true)
            $params.Add("Intent", "uninstall")
          }
          "assignment_uninstall_exceptions" {
            $params.Add("Exclude", $true)
            $params.Add("Intent", "uninstall")
          }
        }
        if ($null -ne $group.name -and $group.name -notin @('All Users', 'All Devices')) {
          $uri = "https://graph.microsoft.com/beta/groups/?`$filter=displayName eq '$($group.name)'"
          $group_lookup = (Invoke-RestMethod -Method Get -Uri $uri -Headers $graph_header -StatusCodeVariable statusCode).value
          if(-not $group_lookup.id) { 
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Group '$($group.name)' not found in Entra AD. Skipping assignment." -Level Warning -Tag "Groups", $configuration.application.Name -Target "Application Factory Client"
            continue
          }
          $params.Add("GroupID", $group_lookup.id)
          Add-IntuneWin32AppAssignmentGroup @params 3>$null | Out-Null
        }
        elseif($group.name -in @('All Users', 'All Devices')) {
          $params.remove("Include")
          $params.remove("Exclude")
          if ($group.name -eq 'All Users') {
            Add-IntuneWin32AppAssignmentAllUsers @params 3>$null | Out-Null
          }
          else {
            Add-IntuneWin32AppAssignmentAllDevices @params 3>$null | Out-Null
          }
        }

      }
    }
  }
  $WarningPreference = $originalWarningPreference
}