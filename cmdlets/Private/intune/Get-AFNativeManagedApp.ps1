function Get-AFNativeManagedApp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][guid]$Id,
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version,
    [string]$ProtectedAppId
  )

  if ($Id -eq [guid]::Empty) {
    throw "An application ID is required."
  }

  if ($ProtectedAppId -and [string]$Id -eq $ProtectedAppId) {
    throw "Refusing to remove or unassign the protected application."
  }

  try {
    $app = Invoke-AFNativeGraphRequest `
      -Method GET `
      -Uri "deviceAppManagement/mobileApps/$Id"
  }
  catch {
    if ([int]$_.Exception.Data["HttpStatus"] -eq 404) {
      return $null
    }

    throw
  }

  $pattern = (
    '(?im)^\s*AppFactoryID:' +
    [regex]::Escape($ApplicationId) +
    '\s*$'
  )

  if (
    $app.'@odata.type' -ne "#microsoft.graph.win32LobApp" -or
    [string]$app.notes -notmatch $pattern -or
    [string]$app.displayVersion -cne $Version
  ) {
    throw "Application $Id does not match the expected AppFactory identity/version."
  }

  if (
    $null -eq $app.uploadState -or
    [int]$app.uploadState -ne 1 -or
    $app.publishingState -ne "published" -or
    -not $app.committedContentVersion
  ) {
    throw "Application $Id is not ready and published; cleanup stopped."
  }

  return $app
}