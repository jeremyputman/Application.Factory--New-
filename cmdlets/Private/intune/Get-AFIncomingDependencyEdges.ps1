function Get-AFIncomingDependencyEdges {
  param([hashtable]$Inventory,[string]$TargetId)
  foreach ($node in $Inventory.Values) {
    foreach ($r in @($node.Relationships)) {
      if ($r.targetType -eq 'child' -and [string]$r.targetId -eq $TargetId) {
        [pscustomobject]@{App=$node.App; Relationship=$r; Relationships=@($node.Relationships)}
      }
    }
  }
}

