function Get-AFNativeAppRole {
  [CmdletBinding()]
  param([AllowNull()][string]$Notes)
  if ([string]::IsNullOrWhiteSpace($Notes)) { return "normal" }
  # In .NET multiline regex, $ is before LF, not before a preceding CR.
  # Allow CR explicitly; horizontal whitespace must not consume other lines.
  $markers = [regex]::Matches($Notes, '(?im)^[\t ]*AppFactoryRole:([^\r\n]*)\r?$')
  if ($markers.Count -eq 0) { return "normal" }
  if ($markers.Count -ne 1) { throw "Application has duplicate AppFactoryRole markers." }
  $role = $markers[0].Groups[1].Value.Trim().ToLowerInvariant()
  if ($role -notin @("normal", "updater")) { throw "Application has an unsupported AppFactoryRole marker." }
  return $role
}
