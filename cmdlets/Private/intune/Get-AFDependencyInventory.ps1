function Get-AFDependencyInventory {
  $filter = [uri]::EscapeDataString("isof('microsoft.graph.win32LobApp')")
  $apps = @(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps?%24filter=$filter" -ErrorAction Stop)
  $items = @{}
  foreach ($app in $apps) {
    if (-not $app.id) { throw 'Incomplete application inventory.' }
    $relationships = @(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps/$($app.id)/relationships" -ErrorAction Stop)
    foreach ($r in $relationships) {
      if (-not $r.targetId -or $r.targetType -cnotin @('parent','child')) {
        throw 'Incomplete or unknown relationship direction; inventory is unsafe.'
      }
    }
    $items[[string]$app.id] = [pscustomobject]@{ App=$app; Relationships=$relationships }
  }
  return $items
}

