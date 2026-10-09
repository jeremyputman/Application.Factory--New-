function Invoke-AFNativeStoragePut {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$Context,
    [Parameter(Mandatory)][string]$Query,
    [Parameter(Mandatory)][byte[]]$Bytes,
    [string]$ContentType = "application/octet-stream"
  )

  $md5 = [Security.Cryptography.MD5]::Create()

  try {
    $contentMd5 = [Convert]::ToBase64String(
      $md5.ComputeHash($Bytes)
    )
  }
  finally {
    $md5.Dispose()
  }

  $clientRequestId = [guid]::NewGuid().ToString()
  $renewedAfter403 = $false

  for ($attempt = 1; $attempt -le 6; $attempt++) {
    Update-AFNativeUploadSas -Context $Context

    $uri = "$($Context.File.azureStorageUri)&$Query"

    try {
      Invoke-WebRequest `
        -Uri $uri `
        -Method PUT `
        -Body $Bytes `
        -ContentType $ContentType `
        -TimeoutSec 120 `
        -Headers @{
        "x-ms-version"           = "2021-12-02"
        "x-ms-date"              = [DateTime]::UtcNow.ToString("R")
        "Content-MD5"            = $contentMd5
        "x-ms-client-request-id" = $clientRequestId
      } `
        -ErrorAction Stop | Out-Null

      return
    }
    catch {
      $failure = Get-AFNativeHttpFailure -Record $_

      if (
        $failure.Status -eq 403 -and
        -not $renewedAfter403 -and
        $attempt -lt 6
      ) {
        $renewedAfter403 = $true
        Update-AFNativeUploadSas -Context $Context -Force
        continue
      }

      if (
        $failure.Status -in @(0, 408, 429, 500, 502, 503, 504) -and
        $attempt -lt 6
      ) {
        $delay = if ($failure.RetrySeconds -gt 0) {
          [Math]::Ceiling($failure.RetrySeconds)
        }
        else {
          [Math]::Min(60, [Math]::Pow(2, $attempt)) +
          (Get-Random -Minimum 0 -Maximum 4)
        }

        if ($delay -le 300) {
          Start-Sleep -Seconds $delay
          continue
        }
      }

      throw (
        "Azure content PUT failed. " +
        "Operation=$Query; HTTP=$($failure.Status); " +
        "RequestId=$($failure.RequestId); " +
        "ClientRequestId=$clientRequestId; " +
        "Response=$($failure.Detail)"
      )
    }
  }
}