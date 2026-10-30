function Get-AFClientAssignmentKey {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Assignment
  )

  $target = $Assignment.target
  $type = ([string]$target.'@odata.type').TrimStart('#')

  if ($type -notin @(
      "microsoft.graph.groupAssignmentTarget",
      "microsoft.graph.exclusionGroupAssignmentTarget",
      "microsoft.graph.allDevicesAssignmentTarget",
      "microsoft.graph.allLicensedUsersAssignmentTarget"
    )) {
    throw "Unsupported assignment target type: $type"
  }

  if (
    $type -in @(
      "microsoft.graph.groupAssignmentTarget",
      "microsoft.graph.exclusionGroupAssignmentTarget"
    ) -and
    -not $target.groupId
  ) {
    throw "Group assignment has no group ID."
  }

  $filterId = [string]$target.deviceAndAppManagementAssignmentFilterId
  $filterType = [string]$target.deviceAndAppManagementAssignmentFilterType

  if (-not $filterType) {
    $filterType = "none"
  }

  return (
    @(
      [string]$Assignment.intent
      $type
      [string]$target.groupId
      $filterId
      $filterType
    ) -join "|"
  ).ToLowerInvariant()
}