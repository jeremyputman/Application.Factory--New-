function Copy-AFApplicationClientGroups {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)]$intune_apps
  )
  $last_application = $intune_apps | Sort-Object createdDateTime -descending | Select-Object id, displayname, *date* -first 1
  $assignments = Get-IntuneWin32AppAssignment -id $last_application.id
  $filter_split = $configuration.filters -split "::"
  $filters = @{}
  foreach ($filter in $filter_split) {
    $filter_details = $filter -split ";"
    $filters.Add($filter_details[0], @{name = $filter_details[1]; type = $filter_details[2] })
  }
  foreach ($assignment in $assignments) {
    if(-not $assignment.GroupName){continue}
    $params = @{
      "id"      = $script:published_application.id
      "intent"  = $assignment.intent
      "groupid" = $assignment.GroupID
    }
    if ($filters.$($assignment.GroupName)) {
      $params.Add("FilterName", $filters.$($assignment.GroupName).name)
      $params.Add("FilterMode", $filters.$($assignment.GroupName).type)
    }
    if ($assignment.DeliveryOptimizationPriority) {
      $params.Add("DeliveryOptimizationPriority", "foreground")
    }
    if ($assignment.GroupMode -eq "Include" -and $assignment.Type -match "groupAssignmentTarget") {
      $params.Add("Include", $true)
    }
    elseif ($assignment.GroupMode -eq "Exclude" -and $assignment.Type -match "groupAssignmentTarget") {
      $params.Add("Exclude", $true)
    }
    if ($assignment.Type -match "allDevicesAssignmentTarget") {
      $params.remove("groupid")
      Add-IntuneWin32AppAssignmentAllDevices @params | Out-Null
    }
    elseif ($assignment.Type -match "allLicensedUsersAssignmentTarget") {
      $params.remove("groupid")
      Add-IntuneWin32AppAssignmentAllUsers @params | Out-Null
    }
    else {
      Add-IntuneWin32AppAssignmentGroup @params | Out-Null
    }

  }  

}