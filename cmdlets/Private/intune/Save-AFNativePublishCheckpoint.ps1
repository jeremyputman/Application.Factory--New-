function Save-AFNativePublishCheckpoint {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Collections.IDictionary]$Status
  )

  $variable = Get-Variable `
    -Name af_native_publication_journal `
    -Scope Script `
    -ErrorAction SilentlyContinue

  # Standalone publishing has no client-process journal attached.
  if (
    $null -eq $variable -or
    $null -eq $variable.Value -or
    -not $variable.Value.Enabled
  ) {
    return
  }

  $context = $variable.Value
  $journal = $context.Journal

  if (
    $journal -isnot [System.Collections.IDictionary] -or
    [string]::IsNullOrWhiteSpace([string]$context.Path)
  ) {
    throw "Native publication journal context is invalid."
  }

  if (
    [string]$journal.ApplicationId -ne
    [string]$Status.AppFactoryId -or
    [string]$journal.Version -cne
    [string]$script:published_version -or
    [string]$journal.TenantId -ne
    [string]$script:appregistration_tenant -or
    [string]$journal.ClientId -ne
    [string]$script:client_id
  ) {
    throw "Native publication checkpoint identity does not match its journal."
  }

  foreach ($field in @("AppId", "ContentVersionId", "FileId")) {
    $incoming = [string]$Status[$field]
    $existing = [string]$journal[$field]

    if (
      $existing -and
      $incoming -and
      $existing -ne $incoming
    ) {
      throw "Native checkpoint would replace a different $field."
    }

    if ($incoming) {
      $journal[$field] = $incoming
    }
  }

  $journal.State = "PublishStarted"
  $journal.Stage = "Publish"
  $journal.UploadStage = [string]$Status.Stage
  $journal.WorkDirectory = [string]$Status.WorkDirectory

  # Only diagnostic fields are saved—not SAS URLs or encryption keys.
  Save-AFClientProcessJournal `
    -Path ([string]$context.Path) `
    -Journal $journal

  Write-Verbose (
    "Native publish checkpoint saved. " +
    "UploadStage=$($journal.UploadStage); " +
    "AppId=$($journal.AppId); " +
    "ContentVersionId=$($journal.ContentVersionId); " +
    "FileId=$($journal.FileId)"
  )
}