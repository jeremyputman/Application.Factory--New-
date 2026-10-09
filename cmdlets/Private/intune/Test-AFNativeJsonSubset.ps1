function Test-AFNativeJsonSubset {
  [CmdletBinding()]
  param(
    [AllowNull()]$Expected,
    [AllowNull()]$Actual
  )

  if ($null -eq $Expected) {
    return ($null -eq $Actual)
  }

  if ($Expected -is [System.Collections.IDictionary]) {
    if ($Actual -isnot [System.Collections.IDictionary]) {
      return $false
    }

    foreach ($name in $Expected.Keys) {
      if ($name -eq "@odata.type") {
        if (
          ([string]$Expected[$name]).TrimStart('#') -ine
          ([string]$Actual[$name]).TrimStart('#')
        ) {
          return $false
        }

        continue
      }

      # A missing optional property and an explicit null are equivalent.
      if ($null -eq $Expected[$name] -and -not $Actual.Contains($name)) {
        continue
      }

      if (-not $Actual.Contains($name)) {
        return $false
      }

      if (-not (Test-AFNativeJsonSubset `
            -Expected $Expected[$name] `
            -Actual $Actual[$name])) {
        return $false
      }
    }

    return $true
  }

  if ($Expected -is [System.Array]) {
    if ($Actual -isnot [System.Array]) {
      return $false
    }

    if ($Expected.Count -ne $Actual.Count) {
      return $false
    }

    for ($index = 0; $index -lt $Expected.Count; $index++) {
      if (-not (Test-AFNativeJsonSubset `
            -Expected $Expected[$index] `
            -Actual $Actual[$index])) {
        return $false
      }
    }

    return $true
  }

  # JSON dates can be returned with equivalent timezone representations.
  $expectedText = [string]$Expected
  $actualText = [string]$Actual

  if (
    $expectedText -match '^\d{4}-\d{2}-\d{2}T' -and
    $actualText -match '^\d{4}-\d{2}-\d{2}T'
  ) {
    $expectedDate = [DateTimeOffset]::MinValue
    $actualDate = [DateTimeOffset]::MinValue

    if (
      [DateTimeOffset]::TryParse($expectedText, [ref]$expectedDate) -and
      [DateTimeOffset]::TryParse($actualText, [ref]$actualDate)
    ) {
      return ($expectedDate -eq $actualDate)
    }
  }

  return ($Expected -ceq $Actual)
}
