function Test-AFNativeDetectionRulesMatch {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ExpectedRules,
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ActualRules
  )

  if ($ExpectedRules.Count -ne $ActualRules.Count) { return $false }
  $used = @{}

  foreach ($expectedRule in $ExpectedRules) {
    $expected = ConvertTo-Json -InputObject $expectedRule -Depth 30 |
    ConvertFrom-Json -AsHashtable
    $matched = $false

    for ($index = 0; $index -lt $ActualRules.Count; $index++) {
      if ($used.ContainsKey($index)) { continue }
      $actual = ConvertTo-Json -InputObject $ActualRules[$index] -Depth 30 |
      ConvertFrom-Json -AsHashtable

      if (Test-AFNativeJsonSubset -Expected $expected -Actual $actual) {
        $used[$index] = $true
        $matched = $true
        break
      }
    }

    if (-not $matched) { return $false }
  }

  return $true
}
