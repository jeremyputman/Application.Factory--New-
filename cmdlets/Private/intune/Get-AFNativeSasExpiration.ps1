function Get-AFNativeSasExpiration {
  [CmdletBinding()]
  param([Parameter(Mandatory)]$File)

  $uri = [uri]$File.azureStorageUri

  if ($uri.Scheme -ne "https" -or -not $uri.Query) {
    throw "Intune returned an invalid Azure SAS URI."
  }

  $expirations = [Collections.Generic.List[DateTimeOffset]]::new()

  if ($File.azureStorageUriExpirationDateTime) {
    $expirations.Add(
      [DateTimeOffset]::Parse(
        [string]$File.azureStorageUriExpirationDateTime
      )
    )
  }

  foreach ($part in $uri.Query.TrimStart('?').Split('&')) {
    $pair = $part.Split('=', 2)

    if ($pair.Count -eq 2 -and $pair[0] -ieq "se") {
      $expirations.Add(
        [DateTimeOffset]::Parse(
          [uri]::UnescapeDataString($pair[1])
        )
      )
    }
  }

  if ($expirations.Count -eq 0) {
    throw "Intune SAS URI does not provide a usable expiration."
  }

  # Use the earlier expiration if the URI and Graph property differ.
  return ($expirations | Sort-Object | Select-Object -First 1)
}