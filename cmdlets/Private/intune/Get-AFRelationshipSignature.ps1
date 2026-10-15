function Get-AFRelationshipSignature {
  param([AllowEmptyCollection()][object[]]$Relationships=@())
  $keys = @(ConvertTo-AFChildRelationshipBody -Relationships $Relationships | ForEach-Object {
    "$($_.'@odata.type')|$($_.targetId)|$($_.dependencyType)|$($_.supersedenceType)"
  } | Sort-Object)
  return ConvertTo-Json -InputObject $keys -Compress
}

