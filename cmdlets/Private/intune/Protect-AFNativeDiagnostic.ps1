function Protect-AFNativeDiagnostic {
  [CmdletBinding()]
  param([AllowNull()][string]$Text)

  if ([string]::IsNullOrEmpty($Text)) {
    return ""
  }

  # Remove URL query strings, including SAS credentials.
  $safe = [regex]::Replace($Text, '(?i)(https?://[^\s?"<>]+)\?[^\s"<>]+', '$1?[REDACTED]')

  # Remove encryption fields if a response happens to echo them.
  $safe = [regex]::Replace($safe, '(?i)("(?:encryptionKey|macKey|initializationVector|mac|fileDigest)"\s*:\s*")[^"]*', '$1[REDACTED]')

  return $safe
}