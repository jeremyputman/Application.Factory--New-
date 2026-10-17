function Invoke-AFReverseDependencyReconciliation {
  param($Configuration,[object[]]$PreviousApps,$Journal,[string]$JournalPath)
  if (-not $Configuration.reconcile_reverse_dependencies -or $Configuration.PublicationRole -eq 'updater') { return }
  foreach ($entry in @($Journal.DependencyOperations | Where-Object { $null -ne $_ -and $_.State -ne 'Verified' })) {
    Invoke-AFDependencyOperation -Entry $entry -Journal $Journal -JournalPath $JournalPath
  }
  foreach ($old in $PreviousApps) {
    if ([string]$old.id -eq [string]$Journal.AppId) { continue }
    $inventory=Get-AFDependencyInventory
    foreach ($parent in @(Get-AFIncomingDependencyEdges -Inventory $inventory -TargetId ([string]$old.id))) {
      if ($parent.Relationship.'@odata.type' -ne '#microsoft.graph.mobileAppDependency') { continue }
      $binding=Get-AFFollowingBinding -Parent $parent -TargetId ([string]$old.id)
      if ($null -eq $binding -or $binding.application_id -ne [string]$Configuration.application.id -or
          $binding.configuration_id -ne [string]$Configuration.id) { continue }
      $newApp=Get-AFNativeManagedApp -Id ([guid]$Journal.AppId) -ApplicationId ([string]$Configuration.application.id) -Version ([string]$Journal.Version) -ApplicationRole normal
      if ($null -eq $newApp) { throw 'Replacement disappeared during reverse reconciliation.' }
      $desired=@(ConvertTo-AFChildRelationshipBody $parent.Relationships)
      foreach ($r in $desired) {
        if ($r.'@odata.type' -eq '#microsoft.graph.mobileAppDependency' -and $r.targetId -eq [string]$old.id) {
          if (@($desired | Where-Object { $_.targetId -eq [string]$Journal.AppId -and $_.'@odata.type' -eq '#microsoft.graph.mobileAppDependency' }).Count) {
            throw 'Parent already references the replacement; resolve the duplicate explicitly.'
          }
          $r.targetId=[string]$Journal.AppId
          $r.PSObject.Properties.Remove('id')
        }
      }
      $manifest=Get-AFDependencyManifest -Notes ([string]$parent.App.notes)
      $savedBinding=@($manifest.bindings | Where-Object { $_.target_id -eq [string]$old.id })[0]
      $savedBinding.target_id=[string]$Journal.AppId
      $savedBinding.target_version=[string]$Journal.Version
      $savedBinding.content_version=[string]$newApp.committedContentVersion
      $notes=New-AFDependencyNotes -Notes ([string]$parent.App.notes) -Manifest $manifest
      $entry=New-AFDependencyOperation -App $parent.App -Before $parent.Relationships -Desired $desired -DesiredNotes $notes -Key "reverse:$($parent.App.id):$($old.id)"
      Add-AFDependencyOperation -Entry $entry -Journal $Journal -JournalPath $JournalPath
    }
  }
}

