function Wait-AFNativeContentFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FileUri,
    [Parameter(Mandatory)][ValidateSet("AzureStorageUriRequest", "AzureStorageUriRenewal", "CommitFile")][string]$Stage,
    [string]$PreviousSasUri,
    [ValidateRange(30, 3600)][int]$TimeoutSeconds = 900
  )

  $prefix = $Stage.Substring(0, 1).ToLowerInvariant() +
  $Stage.Substring(1)

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
  $lastState = ""

  while ([DateTimeOffset]::UtcNow -lt $deadline) {
    $file = Invoke-AFNativeGraphRequest -Method GET -Uri $FileUri
    $lastState = [string]$file.uploadState

    Write-Verbose "Intune $Stage state: $lastState"

    if ($lastState -eq "${prefix}Success") {
      if ($Stage -eq "CommitFile") {
        if ($file.isCommitted -eq $true) {
          return $file
        }
      }
      elseif (-not [string]::IsNullOrWhiteSpace(
          [string]$file.azureStorageUri
        )) {
        $fresh = (
          -not $PreviousSasUri -or
          [string]$file.azureStorageUri -cne $PreviousSasUri
        )

        $expiration = Get-AFNativeSasExpiration -File $file

        if (
          $fresh -and
          $expiration -gt [DateTimeOffset]::UtcNow.AddMinutes(2)
        ) {
          return $file
        }
      }
    }

    if (
      $lastState -in @(
        "${prefix}Failed",
        "${prefix}TimedOut",
        "error"
      )
    ) {
      throw (
        "Intune file processing failed. " +
        "Stage=$Stage; State=$lastState; File=$FileUri"
      )
    }

    Start-Sleep -Seconds 5
  }

  throw (
    "Timed out waiting for Intune file processing. " +
    "Stage=$Stage; LastState=$lastState; File=$FileUri"
  )
}