function Get-AFClientProcessJournalPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version
  )

  # Separate clients, tenants, prefixes, applications, and versions.
  $identity = ConvertTo-Json -InputObject @(
    [string]$script:appregistration_tenant
    [string]$script:client_id
    [string]$script:app_prefix
    $ApplicationId
    $Version
  ) -Compress

  $sha = [Security.Cryptography.SHA256]::Create()

  try {
    $hash = $sha.ComputeHash(
      [Text.Encoding]::UTF8.GetBytes($identity)
    )
  }
  finally {
    $sha.Dispose()
  }

  $name = [Convert]::ToHexString($hash).ToLowerInvariant()
  $directory = Join-Path $script:working_folder "ClientProcessState"

  [IO.Directory]::CreateDirectory($directory) | Out-Null

  return Join-Path $directory "$name.json"
}