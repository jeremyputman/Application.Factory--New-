function Get-AFClientUniqueGraphObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Resource,
    [Parameter(Mandatory)][string]$DisplayName
  )

  if ($Resource.Trim('/') -eq 'deviceManagement/assignmentFilters') {
    # Read all pages, then match the name locally.
    $items = @(
      Get-AFClientGraphCollection -Uri 'deviceManagement/assignmentFilters' |
      Where-Object {
        [string]::Equals(
          [string]$_.displayName,
          $DisplayName,
          [StringComparison]::OrdinalIgnoreCase
        )
      }
    )
  }
  else {
    $escapedName = $DisplayName.Replace("'", "''")
    $filter = [uri]::EscapeDataString("displayName eq '$escapedName'")

    $items = @(
      Get-AFClientGraphCollection -Uri "$Resource`?`$filter=$filter"
    )
  }

  if ($items.Count -ne 1) {
    throw (
      "Expected exactly one '$DisplayName' in '$Resource'; " +
      "found $($items.Count)."
    )
  }

  return $items[0]
}