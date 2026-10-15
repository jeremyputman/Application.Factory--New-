function Get-AFFollowingBinding {
  param($Parent,[string]$TargetId)
  $manifest=Get-AFDependencyManifest -Notes ([string]$Parent.App.notes)
  if ($null -eq $manifest -or $manifest.client_id -ne [string]$script:client_id) { return $null }
  $bindingMatches=@($manifest.bindings | Where-Object { $_.target_id -eq $TargetId })
  if ($bindingMatches.Count -ne 1 -or $bindingMatches[0].version_policy -ne 'follow_config' -or
      $bindingMatches[0].dependency_type -cne $Parent.Relationship.dependencyType) { return $null }
  $marker='(?im)^\s*AppFactoryConfig:'+ [regex]::Escape([string]$manifest.configuration_id)+'\s*$'
  if ([string]$Parent.App.notes -notmatch $marker -or
      (Get-AFNativeAppRole -Notes ([string]$Parent.App.notes)) -ne 'normal') { return $null }
  return $bindingMatches[0]
}

