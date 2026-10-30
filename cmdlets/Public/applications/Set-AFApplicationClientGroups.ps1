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

  $role = "normal"

  if ($configuration.PSObject.Properties["PublicationRole"]) {
    $role = [string]$configuration.PublicationRole
  }

  if ($role -notin @("normal", "updater")) {
    throw "Unsupported publication role for assignment processing."
  }

  Assert-AFClientPublishedApp `
    -ApplicationRole $role `
    -AppId $publishedId `
    -ApplicationId ([string]$configuration.application.id) `
    -Version ([string]$script:published_version) `
    -TimeoutSeconds 0 |
  Out-Null

  if ($null -eq $Plan) {
    $Plan = Get-AFClientAssignmentPlan `
      -Configuration $configuration `
      -SeedAppId $publishedId
  }

  Write-AFLogEntry `
    -Message "[$($configuration.application.Name)][$role] :: Applying $(@($Plan.Assignments).Count) planned assignments to $publishedId." `
    -Tag "Groups", ([string]$configuration.application.Name) `
    -ErrorAction Continue -WarningAction Continue

  foreach ($assignment in @($Plan.Assignments)) {
    Set-AFNativeAppAssignment `
      -AppId $publishedId `
      -Assignment $assignment
  }

  Assert-AFClientAssignments `
    -AppId $publishedId `
    -Plan $Plan

  Write-AFLogEntry `
    -Message "[$($configuration.application.Name)][$role] :: Assignment plan verified for $publishedId." `
    -Tag "Groups", ([string]$configuration.application.Name) `
    -ErrorAction Continue -WarningAction Continue
}
