function Resolve-AFDependencyBindings {
  param([Parameter(Mandatory)]$Configuration,[object[]]$Catalog)
  $specs = @(Get-AFDependencySpecs -Configuration $Configuration)
  if ($specs.Count -eq 0) { return }
  $inventory = Get-AFDependencyInventory
  foreach ($rule in $specs) {
    $configs = @($Catalog | Where-Object { [string]$_.application.id -eq [string]$rule.application_id })
    if ($configs.Count -ne 1) { throw 'Dependency requires one enabled same-client configuration.' }
    $targetConfig = $configs[0]
    $version = if ($rule.version_policy -eq 'pinned') { [string]$rule.version } else { Get-AFDependencyVersion $targetConfig }
    $marker = '(?im)^\s*AppFactoryID:' + [regex]::Escape([string]$rule.application_id) + '\s*$'
    $matches = @($inventory.Values.App | Where-Object {
      [string]$_.notes -match $marker -and [string]$_.displayVersion -ceq $version -and
      (Get-AFNativeAppRole -Notes ([string]$_.notes)) -eq 'normal'
    })
    if ($matches.Count -ne 1) { throw "Dependency $($rule.application_id) version $version requires one exact published target; found $($matches.Count)." }
    $target = Get-AFNativeManagedApp -Id ([guid]$matches[0].id) -ApplicationId ([string]$rule.application_id) -Version $version -ApplicationRole normal
    if ($null -eq $target) { throw 'Dependency target disappeared.' }
    Assert-AFDependencyScope -App $target -Configuration $targetConfig
    [pscustomobject]@{
      application_id=[string]$rule.application_id; target_id=[string]$target.id
      target_version=$version; dependency_type=[string]$rule.dependency_type
      version_policy=[string]$rule.version_policy; version=[string]$rule.version
      content_version=[string]$target.committedContentVersion
      configuration_id=[string]$targetConfig.id
    }
  }
}

