function Assert-AFDependencyGraph {
  param([hashtable]$Inventory,[string]$SourceId,[AllowEmptyCollection()][object[]]$Desired=@())
  if (-not $Inventory.ContainsKey($SourceId)) { throw "Source application is missing from complete graph inventory." }
  $graph=@{}; $neighbours=@{}
  foreach ($key in $Inventory.Keys) {
    $relations = if ($key -eq $SourceId) { $Desired } else { @($Inventory[$key].Relationships) }
    $targets = @(ConvertTo-AFChildRelationshipBody -Relationships $relations | Where-Object {
      $_.'@odata.type' -eq '#microsoft.graph.mobileAppDependency'
    } | ForEach-Object { [string]$_.targetId })
    $graph[$key]=$targets
    if (-not $neighbours.ContainsKey($key)) { $neighbours[$key]=[Collections.Generic.HashSet[string]]::new() }
    foreach ($target in $targets) {
      if (-not $Inventory.ContainsKey($target)) { throw 'Dependency graph includes an unreadable or non-Win32 target.' }
      $null=$neighbours[$key].Add($target)
      if (-not $neighbours.ContainsKey($target)) { $neighbours[$target]=[Collections.Generic.HashSet[string]]::new() }
      $null=$neighbours[$target].Add($key)
    }
  }
  $visiting=@{}; $visited=@{}
  function Visit-AFGraph([string]$key) {
    if ($visiting.ContainsKey($key)) { throw 'Dependency mutation would create a cycle.' }
    if ($visited.ContainsKey($key)) { return }
    $visiting[$key]=$true
    foreach ($target in $graph[$key]) { Visit-AFGraph $target }
    $null=$visiting.Remove($key); $visited[$key]=$true
  }
  foreach ($key in $graph.Keys) { Visit-AFGraph $key }
  $covered=[Collections.Generic.HashSet[string]]::new()
  foreach ($key in $neighbours.Keys) {
    if ($covered.Contains($key)) { continue }
    $pending=[Collections.Generic.Stack[string]]::new(); $pending.Push($key)
    $component=[Collections.Generic.HashSet[string]]::new()
    while ($pending.Count) {
      $current=$pending.Pop()
      if (-not $component.Add($current)) { continue }
      foreach ($next in $neighbours[$current]) { $pending.Push($next) }
    }
    if ($component.Count -gt 100) { throw 'Connected dependency graph exceeds 100 applications.' }
    foreach ($node in $component) { $null=$covered.Add($node) }
  }
}

