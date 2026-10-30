function Get-AFDependencyInventory {
  [CmdletBinding()]
  param([AllowEmptyCollection()][string[]]$RequiredAppIds=@())

  # Enumerate without an isof filter: newly published derived apps can lag
  # filtered list responses. Collection failures still stop the operation.
  $apps = @(Get-AFClientGraphCollection -Uri 'deviceAppManagement/mobileApps' -ErrorAction Stop)
  $listed = @{}
  $pending = [Collections.Generic.Queue[string]]::new()
  foreach ($app in $apps) {
    if (-not $app.id) { throw 'Incomplete application inventory.' }
    if ($app.'@odata.type' -ne '#microsoft.graph.win32LobApp') { continue }
    $listed[[string]$app.id] = $app
    $pending.Enqueue([string]$app.id)
  }
  foreach ($id in $RequiredAppIds) {
    $parsed=[guid]::Empty
    if (-not [guid]::TryParse($id,[ref]$parsed) -or $parsed -eq [guid]::Empty) {
      throw 'A required inventory application ID is invalid.'
    }
    $pending.Enqueue([string]$parsed)
  }

  $items = @{}
  while ($pending.Count) {
    $id=$pending.Dequeue()
    if ($items.ContainsKey($id)) { continue }
    $app = if ($listed.ContainsKey($id)) { $listed[$id] } else {
      # Directly verify known/published IDs and IDs discovered in relationships.
      # A 403/404 or wrong subtype is an error, never an invented empty node.
      Invoke-AFNativeGraphRequest -Method GET -Uri "deviceAppManagement/mobileApps/$id"
    }
    if ($null -eq $app -or [string]$app.id -ne $id -or
        $app.'@odata.type' -ne '#microsoft.graph.win32LobApp') {
      throw "Inventory could not verify Win32 application $id."
    }
    $relationships = @(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps/$id/relationships" -ErrorAction Stop)
    foreach ($r in $relationships) {
      if (-not $r.targetId -or $r.targetType -cnotin @('parent','child')) {
        throw 'Incomplete or unknown relationship direction; inventory is unsafe.'
      }
      # Hydrate relationship peers omitted from the app list as well.
      $pending.Enqueue([string]$r.targetId)
    }
    $items[$id] = [pscustomobject]@{ App=$app; Relationships=$relationships }
  }
  return $items
}
