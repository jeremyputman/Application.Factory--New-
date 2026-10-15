function Assert-AFDependencyScope {
  param([Parameter(Mandatory)]$App,[Parameter(Mandatory)]$Configuration)
  if (-not $Configuration.id) { throw 'Dependency publishing requires configuration IDs from the updated API.' }
  $clientLines = @([string]$App.notes -split '\r?\n' | Where-Object { $_ -match '^AppFactoryClient:' })
  $configLines = @([string]$App.notes -split '\r?\n' | Where-Object { $_ -match '^AppFactoryConfig:' })
  # Legacy objects can only be adopted by an exact, unique identity/version match.
  if ($clientLines.Count -gt 1 -or $configLines.Count -gt 1 -or
      ($clientLines.Count -eq 1 -and $clientLines[0] -cne "AppFactoryClient:$script:client_id") -or
      ($configLines.Count -eq 1 -and $configLines[0] -cne "AppFactoryConfig:$($Configuration.id)")) {
    throw 'Application belongs to another publishing configuration.'
  }
}

