function Wait-AFNativeContentFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FileUri,
    [Parameter(Mandatory)][ValidateSet("AzureStorageUriRequest","AzureStorageUriRenewal","CommitFile")]
    [string]$Stage,
    [string]$PreviousSasUri,
    [ValidateRange(30, 3600)][int]$TimeoutSeconds = 900
  )

  $prefix = $Stage.Substring(0, 1).ToLowerInvariant() +
  $Stage.Substring(1)

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
  $lastState = ""
  $lastReason = "No successful response observed."

  while ([DateTimeOffset]::UtcNow -lt $deadline) {
    $file = Invoke-AFNativeGraphRequest `
      -Method GET `
      -Uri $FileUri

    $lastState = [string]$file.uploadState

    Write-Verbose "Intune $Stage state: $lastState"

    if ($lastState -in @(
        "${prefix}Failed",
        "${prefix}TimedOut",
        "error"
      )) {
      throw (
        "Intune file processing failed. " +
        "Stage=$Stage; State=$lastState; File=$FileUri"
      )
    }

    if ($lastState -eq "${prefix}Success") {
      if ($Stage -eq "CommitFile") {
        if ($file.isCommitted -eq $true) {
          return $file
        }

        $lastReason = "Success state returned without isCommitted=true."
      }
      elseif ([string]::IsNullOrWhiteSpace(
          [string]$file.azureStorageUri
        )) {
        $lastReason = "Success state returned without a SAS URI."
      }
      else {
        $expiration = Get-AFNativeSasExpiration -File $file

        if (
          $expiration -gt
          [DateTimeOffset]::UtcNow.AddMinutes(2)
        ) {
          if (
            $Stage -eq "AzureStorageUriRenewal" -and
            $PreviousSasUri -and
            [string]$file.azureStorageUri -ceq $PreviousSasUri
          ) {
            Write-Verbose (
              "Intune reports renewal success with an " +
              "unchanged SAS URI and sufficient validity."
            )
          }

          return $file
        }

        $lastReason = (
          "Success state returned with insufficient SAS validity. " +
          "ExpirationUtc=$($expiration.ToUniversalTime().ToString('o'))"
        )

        Write-Verbose $lastReason
      }
    }

    Start-Sleep -Seconds 5
  }

  throw (
    "Timed out waiting for Intune file processing. " +
    "Stage=$Stage; LastState=$lastState; " +
    "Reason=$lastReason; File=$FileUri"
  )
}