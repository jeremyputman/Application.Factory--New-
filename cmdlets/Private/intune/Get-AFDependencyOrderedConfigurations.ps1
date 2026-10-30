function Get-AFDependencyOrderedConfigurations {
  param([object[]]$Configurations,[object[]]$Catalog)
  $all = @{}; $selected = @{}; $visited = @{}; $visiting = @{}
  $ordered = [Collections.Generic.List[object]]::new()
  foreach ($c in $Catalog) {
    $key = [string]$c.application.id
    if ($all.ContainsKey($key)) { throw 'Duplicate client application configuration.' }
    $all[$key] = $c
  }
  foreach ($c in $Configurations) { $selected[[string]$c.application.id] = $c }
  function Visit-DependencyConfiguration([string]$key) {
    if ($visiting.ContainsKey($key)) { throw 'Dependency configuration contains a cycle.' }
    if ($visited.ContainsKey($key)) { return }
    $visiting[$key] = $true
    foreach ($rule in @(Get-AFDependencySpecs -Configuration $all[$key])) {
      $target = [string]$rule.application_id
      if (-not $all.ContainsKey($target)) { throw "Dependency $target has no enabled client configuration." }
      Visit-DependencyConfiguration $target
    }
    $null=$visiting.Remove($key)
    $visited[$key] = $true
    if ($selected.ContainsKey($key)) { $ordered.Add($selected[$key]) }
  }
  foreach ($key in $selected.Keys) { Visit-DependencyConfiguration $key }
  $ordered.ToArray()
}

