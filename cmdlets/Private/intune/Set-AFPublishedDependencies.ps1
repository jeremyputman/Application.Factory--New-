function Set-AFPublishedDependencies {
  param($Configuration,[object[]]$Bindings,$Journal,[string]$JournalPath)
  foreach ($binding in $Bindings) {
    $target=Get-AFNativeManagedApp -Id ([guid]$binding.target_id) -ApplicationId $binding.application_id -Version $binding.target_version -ApplicationRole normal
    if ($null -eq $target -or [string]$target.committedContentVersion -cne $binding.content_version) {
      throw 'Resolved dependency target changed after preflight.'
    }
  }
  foreach ($entry in @($Journal.DependencyOperations | Where-Object { $_.State -ne 'Verified' })) {
    Invoke-AFDependencyOperation -Entry $entry -Journal $Journal -JournalPath $JournalPath
  }
  $app=Invoke-AFNativeGraphRequest -Method GET -Uri "deviceAppManagement/mobileApps/$($Journal.AppId)"
  Assert-AFDependencyScope -App $app -Configuration $Configuration
  $before=@(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps/$($Journal.AppId)/relationships")
  $manifest=Get-AFDependencyManifest -Notes ([string]$app.notes)
  $owned=@{}
  if ($manifest) {
    if ($manifest.configuration_id -ne [string]$Configuration.id -or $manifest.client_id -ne [string]$script:client_id) {
      throw 'Dependency manifest belongs to another configuration.'
    }
    foreach ($binding in @($manifest.bindings)) { $owned[[string]$binding.target_id]=$binding }
  }
  $desired=[Collections.Generic.List[object]]::new()
  foreach ($r in @(ConvertTo-AFChildRelationshipBody $before)) {
    # Only remove declared edges we can prove AppFactory previously managed.
    if ($r.'@odata.type' -eq '#microsoft.graph.mobileAppDependency' -and $owned.ContainsKey([string]$r.targetId)) {
      if ($owned[[string]$r.targetId].dependency_type -cne $r.dependencyType) { throw 'Managed dependency mode was changed externally.' }
      continue
    }
    $desired.Add($r)
  }
  foreach ($binding in $Bindings) {
    $existing=@($desired | Where-Object { $_.targetId -eq $binding.target_id -and $_.'@odata.type' -eq '#microsoft.graph.mobileAppDependency' })
    if ($existing.Count -gt 1) { throw 'Duplicate existing dependency targets must be resolved before publishing.' }
    if ($existing.Count -eq 1) {
      # Explicit GUI/API selection adopts this exact existing edge and its selected mode.
      $existing[0].dependencyType = [string]$binding.dependency_type
      continue
    }
    $desired.Add([pscustomobject]@{
      '@odata.type'='#microsoft.graph.mobileAppDependency'; targetType='child'
      targetId=[string]$binding.target_id; dependencyType=[string]$binding.dependency_type
    })
  }
  $newManifest=[ordered]@{schema=1; configuration_id=[string]$Configuration.id; client_id=[string]$script:client_id; bindings=@($Bindings)}
  $notes=New-AFDependencyNotes -Notes ([string]$app.notes) -Manifest $newManifest
  if ((Get-AFRelationshipSignature $before) -ceq (Get-AFRelationshipSignature $desired.ToArray()) -and $notes -ceq [string]$app.notes) { return }
  $entry=New-AFDependencyOperation -App $app -Before $before -Desired $desired.ToArray() -DesiredNotes $notes -Key "outgoing:$($Journal.AppId)"
  Add-AFDependencyOperation -Entry $entry -Journal $Journal -JournalPath $JournalPath
}

