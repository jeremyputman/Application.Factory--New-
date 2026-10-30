function ConvertTo-AFChildRelationshipBody {
  param([AllowEmptyCollection()][object[]]$Relationships=@())
  foreach ($r in $Relationships) {
    if ($r.targetType -cnotin @('parent','child')) { throw 'Unknown relationship direction.' }
    if ($r.targetType -eq 'parent') { continue }
    $item = [ordered]@{ '@odata.type'=[string]$r.'@odata.type'; targetId=[string]$r.targetId; targetType='child' }
    switch ($r.'@odata.type') {
      '#microsoft.graph.mobileAppDependency' {
        if ($r.dependencyType -cnotin @('detect','autoInstall')) { throw 'Unknown dependency mode.' }
        $item.dependencyType = [string]$r.dependencyType
      }
      '#microsoft.graph.mobileAppSupersedence' {
        if ($r.supersedenceType -cnotin @('update','replace')) { throw 'Unknown supersedence mode.' }
        $item.supersedenceType = [string]$r.supersedenceType
      }
      default { throw 'Unsupported relationship subtype; no write is safe.' }
    }
    if ($r.id) { $item.id = [string]$r.id }
    [pscustomobject]$item
  }
}

