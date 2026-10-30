function Test-AFNativeRequirementRulesMatch {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedRules,
    [Parameter()][AllowNull()][AllowEmptyCollection()][object[]]$ActualRules
  )

  function ConvertTo-ComparableRequirements {
    param([AllowNull()][object[]]$Rules)

    foreach ($rule in $Rules) {
      if ($null -eq $rule) { continue }

      $copy = ConvertTo-Json -InputObject $rule -Depth 30 |
      ConvertFrom-Json -AsHashtable

      if (
        $copy.detectionType -in @("exists", "doesNotExist") -and
        [string]::IsNullOrEmpty([string]$copy.detectionValue)
      ) {
        $copy.detectionValue = $null
      }

      $copy
    }
  }

  $expected = @(ConvertTo-ComparableRequirements -Rules $ExpectedRules)
  $actual = @(ConvertTo-ComparableRequirements -Rules $ActualRules)

  # Existing comparator checks count and matches objects without relying
  # on their ordering. Its implementation is also suitable for requirements.
  return (Test-AFNativeDetectionRulesMatch `
      -ExpectedRules $expected `
      -ActualRules $actual)
}