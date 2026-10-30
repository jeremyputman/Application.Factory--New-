function Assert-AFInPlaceDependenciesSafe {
  param($App)
  $inventory=Get-AFDependencyInventory
  foreach ($parent in @(Get-AFIncomingDependencyEdges -Inventory $inventory -TargetId ([string]$App.id))) {
    if ($parent.Relationship.'@odata.type' -ne '#microsoft.graph.mobileAppDependency' -or
        $null -eq (Get-AFFollowingBinding -Parent $parent -TargetId ([string]$App.id))) {
      throw 'In-place replacement would change a pinned, unmanaged, or superseded target; publish a separate app instead.'
    }
  }
}

