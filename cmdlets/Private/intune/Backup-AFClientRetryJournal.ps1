function Backup-AFClientRetryJournal {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$ExpectedHash
  )

  if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash -cne $ExpectedHash) {
    throw "The failed journal changed during recovery. No retry will be started."
  }

  $directory = Join-Path ([IO.Path]::GetDirectoryName($Path)) "Archive"
  $null = [IO.Directory]::CreateDirectory($directory)
  $name = [IO.Path]::GetFileNameWithoutExtension($Path) + "." +
    [DateTimeOffset]::UtcNow.ToString("yyyyMMddTHHmmssfffZ") + "." +
    [guid]::NewGuid().ToString("N") + ".json"
  $destination = Join-Path $directory $name

  # Copy first: a failed download, backup, or atomic status write must retain the active journal.
  [IO.File]::Copy($Path, $destination, $false)
  if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256 -ErrorAction Stop).Hash -cne $ExpectedHash) {
    throw "The recovery journal backup could not be verified. No retry will be started."
  }
  return $destination
}

