function Save-AFClientProcessJournal {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][System.Collections.IDictionary]$Journal
  )

  $Journal.UpdatedUtc = [DateTimeOffset]::UtcNow.ToString("o")
  $temporaryPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"

  try {
    $json = ConvertTo-Json -InputObject $Journal -Depth 20
    [IO.File]::WriteAllText(
      $temporaryPath,
      $json,
      [Text.UTF8Encoding]::new($false)
    )

    [IO.File]::Move($temporaryPath, $Path, $true)
  }
  finally {
    if ([IO.File]::Exists($temporaryPath)) {
      [IO.File]::Delete($temporaryPath)
    }
  }
}