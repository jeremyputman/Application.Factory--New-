function Clear-AFRetiringDependencies {
  param($Previous,$Configuration,$Journal,[string]$JournalPath)
  Assert-AFDependencyCleanupSafe -Id ([guid]$Previous.id) -AllowOutgoingDependencies
  $app=Get-AFNativeManagedApp -Id ([guid]$Previous.id) -ApplicationId ([string]$Configuration.application.id) -Version ([string]$Previous.displayVersion) -ApplicationRole ([string]$Configuration.PublicationRole) -ProtectedAppId ([string]$Journal.AppId)
  if ($null -eq $app) { return }
  Assert-AFDependencyScope -App $app -Configuration $Configuration
  $relationships=@(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps/$($Previous.id)/relationships")
  if ($relationships.Count -eq 0) { return }
  # Only detach edges represented by a matching durable manifest.
  $manifest=Get-AFDependencyManifest -Notes ([string]$app.notes)
  if ($null -eq $manifest -or $manifest.configuration_id -ne [string]$Configuration.id -or
      $manifest.client_id -ne [string]$script:client_id) { throw 'Outgoing dependency ownership is unknown.' }
  $expected=@($manifest.bindings | ForEach-Object {
    [pscustomobject]@{'@odata.type'='#microsoft.graph.mobileAppDependency';targetType='child';targetId=$_.target_id;dependencyType=$_.dependency_type}
  })
  if ((Get-AFRelationshipSignature $relationships) -cne (Get-AFRelationshipSignature $expected)) {
    throw 'Retiring dependency relationships differ from the saved policy.'
  }
  $manifest.bindings=@()
  $notes=New-AFDependencyNotes -Notes ([string]$app.notes) -Manifest $manifest
  $entry=New-AFDependencyOperation -App $app -Before $relationships -Desired @() -DesiredNotes $notes -Key "detach:$($Previous.id)" -Kind Detach
  Add-AFDependencyOperation -Entry $entry -Journal $Journal -JournalPath $JournalPath
  Assert-AFDependencyCleanupSafe -Id ([guid]$Previous.id)
}
