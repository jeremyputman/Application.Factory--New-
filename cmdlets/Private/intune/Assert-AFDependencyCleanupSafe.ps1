function Assert-AFDependencyCleanupSafe {
  param([Parameter(Mandatory)][guid]$Id, [switch]$AllowOutgoingDependencies)
  
  $inventoryTimer = [Diagnostics.Stopwatch]::StartNew()
  try {
    $inventory = Get-AFDependencyInventory
  }
  finally {
    $inventoryTimer.Stop()
    Write-AFLogEntry `
      -Message "Cleanup safety inventory for $Id took $([Math]::Round($inventoryTimer.Elapsed.TotalSeconds, 1)) seconds." `
      -Tag "Process", "Cleanup" `
      -ErrorAction Continue -WarningAction Continue
  }

  if (-not $inventory.ContainsKey([string]$Id)) {
    try { Invoke-AFNativeGraphRequest -Method GET -Uri "deviceAppManagement/mobileApps/$Id" | Out-Null }
    catch {
      if ([int]$_.Exception.Data["HttpStatus"] -eq 404) { return }
      throw
    }
    throw 'Cleanup target is missing from inventory but still exists; cleanup stopped.'
  }
  if (@(Get-AFIncomingDependencyEdges -Inventory $inventory -TargetId ([string]$Id)).Count) {
    throw 'Incoming dependency or supersedence references still exist.'
  }
  foreach ($r in @($inventory[[string]$Id].Relationships)) {
    if (-not $AllowOutgoingDependencies -or $r.targetType -ne 'child' -or
      $r.'@odata.type' -ne '#microsoft.graph.mobileAppDependency') {
      throw 'Application still participates in a dependency or supersedence relationship.'
    }
  }
  $esps = @(Get-AFClientGraphCollection -Uri 'deviceManagement/deviceEnrollmentConfigurations' -ErrorAction Stop)
  foreach ($esp in $esps) {
    if ($esp.'@odata.type' -eq '#microsoft.graph.windows10EnrollmentCompletionPageConfiguration' -and
      [string]$Id -in @($esp.selectedMobileAppIds)) {
      throw "ESP '$($esp.displayName)' still references this application."
    }
  }
}

