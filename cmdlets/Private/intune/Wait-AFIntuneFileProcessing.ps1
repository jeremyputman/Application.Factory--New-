function Wait-AFIntuneFileProcessing {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)][string]$ContentVersionId,
    [Parameter(Mandatory)][string]$FileId,
    [Parameter(Mandatory)][ValidateSet("AzureStorageUriRequest", "AzureStorageUriRenewal", "CommitFile")][string]$Stage,
    [Parameter()][ValidateRange(30, 3600)][int]$TimeoutSeconds = 900
  )

  $uri = "deviceAppManagement/mobileApps/$AppId/microsoft.graph.win32LobApp/contentVersions/$ContentVersionId/files/$FileId"

  $successState = "$($Stage.Substring(0,1).ToLower())$($Stage.Substring(1))Success"
  $pendingState = "$($Stage.Substring(0,1).ToLower())$($Stage.Substring(1))Pending"
  $failedState = "$($Stage.Substring(0,1).ToLower())$($Stage.Substring(1))Failed"
  $timedOutState = "$($Stage.Substring(0,1).ToLower())$($Stage.Substring(1))TimedOut"

  $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
  $pollCount = 0

  while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
    $pollCount++

    $file = Invoke-AFGraphRequest `
      -Method GET `
      -Uri $uri `
      -ApiVersion beta

    $state = [string]$file.uploadState

    if ($script:enable_logging) {
      Write-AFLogEntry `
        -Message "[Application Factory] :: Intune upload stage '$Stage': $state (poll $pollCount)." `
        -Tag "Intune"
    }

    switch ($state) {
      $successState {
        $stopwatch.Stop()
        return $file
      }

      $failedState {
        $stopwatch.Stop()

        throw @"
Intune upload stage failed.
Stage: $Stage
State: $state
Application ID: $AppId
Content Version ID: $ContentVersionId
File ID: $FileId
"@
      }

      $timedOutState {
        $stopwatch.Stop()

        throw @"
Intune reported that the upload stage timed out.
Stage: $Stage
State: $state
Application ID: $AppId
Content Version ID: $ContentVersionId
File ID: $FileId
"@
      }

      $pendingState {
        # Expected. Continue polling.
      }

      default {
        # Don't fail immediately on a state Microsoft adds later.
        # Record it and continue until our timeout.
        if ($script:enable_logging) {
          Write-AFLogEntry `
            -Message "[Application Factory] :: Unexpected Intune upload state '$state' while waiting for '$Stage'." `
            -Level "Warning" `
            -Tag "Intune"
        }
      }
    }

    if ($pollCount -le 5) {
      $delay = 2
    }
    elseif ($pollCount -le 15) {
      $delay = 5
    }
    else {
      $delay = 10
    }

    Start-Sleep -Seconds $delay
  }

  $stopwatch.Stop()

  throw @"
Timed out waiting for Intune upload processing.
Stage: $Stage
Timeout: $TimeoutSeconds seconds
Application ID: $AppId
Content Version ID: $ContentVersionId
File ID: $FileId
"@
}