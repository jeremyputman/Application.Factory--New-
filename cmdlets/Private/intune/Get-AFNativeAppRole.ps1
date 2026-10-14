function Get-AFNativeAppRole {
  [CmdletBinding()]
  param([AllowNull()][string]$Notes)
  if ([string]::IsNullOrWhiteSpace($Notes)) { return "normal" }
  $markers = [regex]::Matches($Notes, '(?im)^\s*AppFactoryRole:([^\r\n]*)$')
  if ($markers.Count -eq 0) { return "normal" }
  if ($markers.Count -ne 1) { throw "Application has duplicate AppFactoryRole markers." }
  $role = $markers[0].Groups[1].Value.Trim().ToLowerInvariant()
  if ($role -notin @("normal", "updater")) { throw "Application has an unsupported AppFactoryRole marker." }
  return $role
}
