function Test-AFNativeAssignmentMatches {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Expected,
    [Parameter(Mandatory)]$Actual
  )

  if (
    (Get-AFClientAssignmentKey -Assignment $Expected) -ne
    (Get-AFClientAssignmentKey -Assignment $Actual)
  ) {
    return $false
  }

  $expectedSettings = $null
  $actualSettings = $null

  if ($null -ne $Expected.settings) {
    $expectedSettings = ConvertFrom-Json `
      -InputObject (
      ConvertTo-Json -InputObject $Expected.settings -Depth 30
    ) `
      -AsHashtable
  }

  if ($null -ne $Actual.settings) {
    $actualSettings = ConvertFrom-Json `
      -InputObject (
      ConvertTo-Json -InputObject $Actual.settings -Depth 30
    ) `
      -AsHashtable
  }

  return (Test-AFNativeJsonSubset `
      -Expected $expectedSettings `
      -Actual $actualSettings)
}