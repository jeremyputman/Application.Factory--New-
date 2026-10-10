function Get-AFNativeSasExpiration {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$File
  )

  $uri = [uri]$File.azureStorageUri

  if ($uri.Scheme -ne "https" -or -not $uri.Query) {
    throw "Intune returned an invalid Azure SAS URI."
  }

  $expirations = [Collections.Generic.List[DateTimeOffset]]::new()
  $culture = [Globalization.CultureInfo]::InvariantCulture
  $styles = [Globalization.DateTimeStyles]::AssumeUniversal

  $graphExpiry = $File.azureStorageUriExpirationDateTime

  if ($null -ne $graphExpiry -and "$graphExpiry" -ne "") {
    if ($graphExpiry -is [DateTimeOffset]) {
      $parsed = $graphExpiry
    }
    elseif ($graphExpiry -is [DateTime]) {
      $date = $graphExpiry

      if ($date.Kind -eq [DateTimeKind]::Unspecified) {
        $date = [DateTime]::SpecifyKind(
          $date,
          [DateTimeKind]::Utc
        )
      }

      # Preserve the DateTime's UTC/local information.
      $parsed = [DateTimeOffset]::new($date)
    }
    else {
      $parsed = [DateTimeOffset]::Parse(
        [string]$graphExpiry,
        $culture,
        $styles
      )
    }

    $expirations.Add($parsed.ToUniversalTime())
  }

  foreach ($part in $uri.Query.TrimStart('?').Split('&')) {
    $pair = $part.Split('=', 2)

    if ($pair.Count -eq 2 -and $pair[0] -ieq "se") {
      $parsed = [DateTimeOffset]::Parse(
        [uri]::UnescapeDataString($pair[1]),
        $culture,
        $styles
      )

      $expirations.Add($parsed.ToUniversalTime())
    }
  }

  if ($expirations.Count -eq 0) {
    throw "Intune SAS URI does not provide a usable expiration."
  }

  # Honor the earlier expiry supplied by Graph or the signed URL.
  return ($expirations | Sort-Object | Select-Object -First 1)
}