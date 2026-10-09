function Assert-AFClientPublishedApp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version,
    [ValidateRange(0, 3600)][int]$TimeoutSeconds = 120
  )

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
  $identityPattern = (
    '(?im)^\s*AppFactoryID:' +
    [regex]::Escape($ApplicationId) +
    '\s*$'
  )

  do {
    $app = Invoke-AFNativeGraphRequest `
      -Method GET `
      -Uri "deviceAppManagement/mobileApps/$AppId"

    if (
      $app.'@odata.type' -ne "#microsoft.graph.win32LobApp" -or
      [string]$app.notes -notmatch $identityPattern -or
      [string]$app.displayVersion -cne $Version
    ) {
      throw "Application $AppId does not match the requested app/version."
    }

    if (
      $null -ne $app.uploadState -and
      [int]$app.uploadState -eq 1 -and
      $app.publishingState -eq "published" -and
      -not [string]::IsNullOrWhiteSpace(
        [string]$app.committedContentVersion
      )
    ) {
      return $app
    }

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw (
    "Application $AppId is not ready and published. " +
    "UploadState=$($app.uploadState); " +
    "PublishingState=$($app.publishingState)."
  )
}