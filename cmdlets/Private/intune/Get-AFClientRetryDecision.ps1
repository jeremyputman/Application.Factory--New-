function Get-AFClientRetryDecision {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)]$Configuration
  )

  $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
  $saved = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop |
    ConvertFrom-Json -DateKind String -ErrorAction Stop
  $role = [string]$Configuration.PublicationRole
  $savedRole = "normal"
  if ($saved.PSObject.Properties["PublicationRole"]) { $savedRole = [string]$saved.PublicationRole }

  if ($saved.State -ne "Failed" -or
      [string]$saved.ApplicationId -ne [string]$Configuration.application.id -or
      [string]$saved.ConfigurationId -ne [string]$Configuration.id -or
      [string]$saved.ClientId -ne [string]$script:client_id -or
      [string]$saved.TenantId -ne [string]$script:appregistration_tenant -or
      [string]$saved.AppPrefix -cne [string]$script:app_prefix -or
      $savedRole -ne $role -or
      $saved.Operation -notin @("Create", "ReplaceInPlace", "ReconcileOnly")) {
    throw "The failed journal does not match the current publishing configuration."
  }

  $expectedPath = Get-AFClientProcessJournalPath -ApplicationId $saved.ApplicationId -Version $saved.Version -ApplicationRole $role
  if ([IO.Path]::GetFullPath($Path) -ne [IO.Path]::GetFullPath($expectedPath)) {
    throw "The failed journal has an invalid identity or filename."
  }
  $id = [guid]::Empty
  if (-not [guid]::TryParse([string]$saved.AppId, [ref]$id) -or $id -eq [guid]::Empty) {
    throw "The failed attempt has no valid Intune AppId. Inspect Intune before retrying; creation may have succeeded."
  }

  $app = $null
  try {
    $app = Invoke-AFNativeGraphRequest -Method GET -Uri "deviceAppManagement/mobileApps/$id"
    if ($null -eq $app) { throw "Intune returned an empty application response." }
  }
  catch {
    # Only an explicit 404 establishes absence. Never infer absence from other failures.
    if ($_.Exception.Data["HttpStatus"] -ne 404) { throw }
  }

  if ($null -ne $app) {
    # Reuse all existing published-app and resume checks; never upload into a partial app.
    $null = Assert-AFClientPublishedApp -AppId $saved.AppId -ApplicationId $saved.ApplicationId -Version $saved.Version -ApplicationRole $role -TimeoutSeconds 0
    return [pscustomobject]@{ Action = "Resume"; JournalHash = $hash }
  }

  if ($saved.Operation -ne "Create" -or $Configuration.replace_in_place) {
    throw "Intune app $id is missing, but this was not a create-only attempt. Inspect the saved operation; automatic recreation is blocked."
  }

  # A different app ID may already represent this version. Never create another one.
  $filter = [uri]::EscapeDataString("isof('microsoft.graph.win32LobApp') and contains(notes,'AppFactoryID:')")
  $inventory = @(Get-AFClientGraphCollection -Uri "deviceAppManagement/mobileApps?%24filter=$filter")
  $pattern = '(?im)^\s*AppFactoryID:' + [regex]::Escape([string]$saved.ApplicationId) + '\s*$'
  $sameVersion = @($inventory | Where-Object {
    [string]$_.notes -match $pattern -and
    [string]$_.displayVersion -ceq [string]$saved.Version -and
    (Get-AFNativeAppRole -Notes ([string]$_.notes)) -eq $role
  })
  if ($sameVersion.Count -gt 0) {
    throw "Another Intune application already represents this app/version/role. Inspect it before retrying."
  }

  return [pscustomobject]@{ Action = "Restart"; JournalHash = $hash }
}

