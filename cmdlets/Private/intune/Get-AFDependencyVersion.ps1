function Get-AFDependencyVersion {
  param([Parameter(Mandatory)]$Configuration)
  foreach ($value in @($Configuration.versions.raw_version,
      $Configuration.application.latest_version.raw_version,
      $Configuration.version.raw_version)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$value)) { return [string]$value }
  }
  throw 'A configured dependency version is required.'
}

