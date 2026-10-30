function Invoke-AFDependencyOperation {
  param([Parameter(Mandatory)]$Entry,[Parameter(Mandatory)]$Journal,
    [Parameter(Mandatory)][string]$JournalPath,[ValidateRange(0,120)][int]$TimeoutSeconds=60)
  $uri="deviceAppManagement/mobileApps/$($Entry.SourceAppId)"
  $app=Invoke-AFNativeGraphRequest -Method GET -Uri $uri
  if ($app.'@odata.type' -ne '#microsoft.graph.win32LobApp' -or
      [string]$app.displayVersion -cne $Entry.SourceVersion -or
      [string]$app.committedContentVersion -cne $Entry.SourceContentVersion -or
      $app.publishingState -ne 'published' -or [int]$app.uploadState -ne 1) {
    throw 'Dependency source identity/content changed; mutation stopped.'
  }
  if ([string]$app.notes -cne $Entry.BeforeNotes -and [string]$app.notes -cne $Entry.DesiredNotes) {
    throw 'Application notes changed concurrently; dependency mutation stopped.'
  }
  $actual=@(Get-AFClientGraphCollection -Uri "$uri/relationships")
  $desiredSignature=Get-AFRelationshipSignature $Entry.DesiredRelationships
  if ((Get-AFRelationshipSignature $actual) -cne $desiredSignature) {
    if ((Get-AFRelationshipSignature $actual) -cne (Get-AFRelationshipSignature $Entry.BeforeRelationships)) {
      throw 'Relationships changed concurrently; dependency mutation stopped.'
    }
    # Refresh every app, including unmanaged sources, before checking the graph.
    $requiredIds=@([string]$Entry.SourceAppId)+@($Entry.DesiredRelationships | ForEach-Object { [string]$_.targetId })
    $inventory=Get-AFDependencyInventory -RequiredAppIds $requiredIds
    Assert-AFDependencyGraph -Inventory $inventory -SourceId $Entry.SourceAppId -Desired $Entry.DesiredRelationships
    # Inventory can take time: compare the source again immediately before writing.
    $freshSource=Invoke-AFNativeGraphRequest -Method GET -Uri $uri
    $freshRelations=@(Get-AFClientGraphCollection -Uri "$uri/relationships")
    if ([string]$freshSource.displayVersion -cne $Entry.SourceVersion -or
        [string]$freshSource.committedContentVersion -cne $Entry.SourceContentVersion -or
        [string]$freshSource.notes -cne [string]$app.notes -or
        (Get-AFRelationshipSignature $freshRelations) -cne (Get-AFRelationshipSignature $Entry.BeforeRelationships)) {
      throw 'Source changed while the dependency graph was being validated.'
    }
    $Entry.State='WriteStarted'
    Save-AFClientProcessJournal -Path $JournalPath -Journal $Journal
    $writeError=''
    try {
      Invoke-AFNativeGraphRequest -Method POST -Uri "$uri/updateRelationships" -Body @{
        relationships=@($Entry.DesiredRelationships)
      } -MaxAttempts 1 | Out-Null
    } catch { $writeError=$_.Exception.Message }
    $deadline=[DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
      $actual=@(Get-AFClientGraphCollection -Uri "$uri/relationships")
      if ((Get-AFRelationshipSignature $actual) -ceq $desiredSignature) { break }
      if ([DateTimeOffset]::UtcNow -ge $deadline) {
        throw "Dependency relationship write is unconfirmed. $writeError"
      }
      Start-Sleep -Seconds 3
    } while ($true)
  }
  if ($Entry.DesiredNotes -cne [string]$app.notes) {
    $Entry.State='RelationshipsVerified'
    Save-AFClientProcessJournal -Path $JournalPath -Journal $Journal
    $fresh=Invoke-AFNativeGraphRequest -Method GET -Uri $uri
    if ([string]$fresh.notes -cne $Entry.BeforeNotes -and [string]$fresh.notes -cne $Entry.DesiredNotes) {
      throw 'Notes changed concurrently after relationship verification.'
    }
    if ([string]$fresh.notes -cne $Entry.DesiredNotes) {
      # Notes are supported in v1.0. The beta endpoint can reject an otherwise
      # valid notes-only PATCH with ModelValidationFailure. Relationships and
      # verification remain on beta; do not replay broader app metadata.
      $noteError=''
      try {
        Invoke-AFNativeGraphRequest -Method PATCH -Uri ("https://graph.microsoft.com/v1.0/$uri") -Body @{ '@odata.type'='#microsoft.graph.win32LobApp'; notes=$Entry.DesiredNotes } -MaxAttempts 1 | Out-Null
      } catch { $noteError=$_.Exception.Message }
      $confirmed=Invoke-AFNativeGraphRequest -Method GET -Uri $uri
      if ([string]$confirmed.notes -cne $Entry.DesiredNotes) { throw "Dependency policy write unconfirmed. $noteError" }
    }
  }
  $actual=@(Get-AFClientGraphCollection -Uri "$uri/relationships")
  if ((Get-AFRelationshipSignature $actual) -cne $desiredSignature) { throw 'Relationships changed after policy verification.' }
  $Entry.State='Verified'; $Entry.Error=''
  Save-AFClientProcessJournal -Path $JournalPath -Journal $Journal
}

