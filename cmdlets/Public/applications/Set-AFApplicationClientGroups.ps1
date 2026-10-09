function Set-AFApplicationClientGroups {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][PSCustomObject]$configuration,
    [Parameter()]$Plan
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

  if ($null -eq $Plan) {
    $Plan = Get-AFClientAssignmentPlan `
      -Configuration $configuration `
      -SeedAppId $publishedId
  }

  foreach ($assignment in @($Plan.Assignments)) {
    Set-AFNativeAppAssignment `
      -AppId $publishedId `
      -Assignment $assignment
  }

  Assert-AFClientAssignments `
    -AppId $publishedId `
    -Plan $Plan
}