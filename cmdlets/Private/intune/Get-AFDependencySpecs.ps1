function Get-AFDependencySpecs {
  param([Parameter(Mandatory)]$Configuration)
  if ($Configuration.PublicationRole -eq 'updater') { return }
  $property = $Configuration.PSObject.Properties['dependencies']
  if ($null -eq $property) { return } # Older API compatibility.
  if ($null -eq $property.Value -or $property.Value -isnot [array]) {
    throw 'dependencies must be a JSON array.'
  }
  $seen = @{}
  foreach ($rule in $property.Value) {
    if ($null -eq $rule) { throw 'Dependency must be an object.' }
    foreach ($name in $rule.PSObject.Properties.Name) {
      if ($name -notin @('application_id','dependency_type','version_policy','version')) {
        throw "Unsupported dependency field: $name"
      }
    }
    $id = [guid]::Empty
    if (-not [guid]::TryParse([string]$rule.application_id,[ref]$id) -or $id -eq [guid]::Empty) {
      throw 'Dependency application_id must be a UUID.'
    }
    if ($seen.ContainsKey([string]$id)) { throw 'Duplicate dependency application.' }
    $seen[[string]$id] = $true
    if ([string]$id -eq [string]$Configuration.application.id) { throw 'Self-dependency rejected.' }
    if ($rule.dependency_type -cnotin @('detect','autoInstall') -or
        $rule.version_policy -cnotin @('follow_config','pinned')) { throw 'Invalid dependency policy.' }
    if ($rule.version_policy -eq 'pinned' -and [string]::IsNullOrWhiteSpace([string]$rule.version)) {
      throw 'Pinned dependencies require a version.'
    }
    if ($rule.version_policy -eq 'follow_config' -and $rule.version) {
      throw 'Following dependencies cannot specify a literal version.'
    }
    $rule
  }
}

