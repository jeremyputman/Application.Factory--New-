function Copy-AFApplicationClientGroups {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$intune_apps,
    [Parameter(Mandatory)][PSCustomObject]$configuration
  )

  $publishedId = [string]$script:published_application.id

  if (-not $publishedId) {
    throw "A published application ID is required."
  }

  Assert-AFClientPublishedApp `
    -AppId $publishedId `
    -ApplicationId ([string]$configuration.application.id) `
    -Version ([string]$script:published_version) `
    -TimeoutSeconds 0 | Out-Null

  $sources = @(
    $intune_apps | Where-Object {
      $_ -and [string]$_.id -ne $publishedId
    }
  )

  if ($sources.Count -eq 0) {
    return
  }

  $plan = Get-AFClientAssignmentPlan `
    -Configuration $configuration `
    -PreviousApps $sources `
    -CopyOnly

  foreach ($assignment in @($plan.Assignments)) {
    Set-AFNativeAppAssignment `
      -AppId $publishedId `
      -Assignment $assignment
  }
}