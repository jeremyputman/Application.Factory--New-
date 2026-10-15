function Get-AFDependencyManifest {
  param([string]$Notes)
  $lines = @($Notes -split '\r?\n' | Where-Object { $_ -match '^AppFactoryDependencies:' })
  if ($lines.Count -eq 0) { return $null }
  if ($lines.Count -ne 1) { throw 'Duplicate dependency manifest.' }
  try {
    $encoded = $lines[0].Substring('AppFactoryDependencies:'.Length)
    $manifest = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded)) |
      ConvertFrom-Json -Depth 30 -DateKind String -ErrorAction Stop
    if ($manifest.schema -ne 1 -or -not $manifest.configuration_id -or
        -not $manifest.client_id -or $null -eq $manifest.bindings) { throw 'Unknown schema.' }
    return $manifest
  } catch { throw "Invalid dependency manifest; no policy will be inferred. $($_.Exception.Message)" }
}

