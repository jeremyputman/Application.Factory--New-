function Invoke-AFNativeStoragePut {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$Context,
    [AllowEmptyString()][string]$Query = "",
    [Parameter(Mandatory)][AllowEmptyCollection()][byte[]]$Bytes,
    [string]$ContentType = "application/octet-stream",
    [switch]$InitializeBlob
  )

  if ($InitializeBlob) {
    if ($Query -or $Bytes.Length -ne 0) {
      throw "Blob initialization requires no operation query and an empty body."
    }

    # Never reset a file that Intune has already committed.
    $latest = Invoke-AFNativeGraphRequest `
      -Method GET `
      -Uri $Context.FileUri

    if (
      $latest.isCommitted -eq $true -or
      $latest.uploadState -in @(
        "commitFilePending",
        "commitFileSuccess"
      )
    ) {
      throw "Refusing to reset committed or committing content."
    }

    $oldResource = ([uri]$Context.File.azureStorageUri).GetLeftPart(
      [UriPartial]::Path
    )

    if ([string]::IsNullOrWhiteSpace(
        [string]$latest.azureStorageUri
      )) {
      throw "The content file has no Azure upload URI."
    }

    $newResource = ([uri]$latest.azureStorageUri).GetLeftPart(
      [UriPartial]::Path
    )

    if ($newResource -cne $oldResource) {
      throw "The destination blob changed; initialization stopped."
    }

    $Context.File = $latest
  }
  elseif ([string]::IsNullOrWhiteSpace($Query)) {
    throw "A block or block-list operation query is required."
  }

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

  $operation = if ($InitializeBlob) {
    "InitializeBlob"
  }
  else {
    $Query
  }

  for ($attempt = 1; $attempt -le 6; $attempt++) {
    Update-AFNativeUploadSas -Context $Context

    $uri = [string]$Context.File.azureStorageUri

    if ($Query) {
      $uri += "&$Query"
    }

    $headers = @{
      "x-ms-version"           = "2021-12-02"
      "x-ms-date"              = [DateTime]::UtcNow.ToString("R")
      "Content-MD5"            = $contentMd5
      "x-ms-client-request-id" = $clientRequestId
    }

    if ($InitializeBlob) {
      $headers["x-ms-blob-type"] = "BlockBlob"
    }

    try {
      Invoke-WebRequest `
        -Uri $uri `
        -Method PUT `
        -Body $Bytes `
        -ContentType $ContentType `
        -TimeoutSec 120 `
        -Headers $headers `
        -ErrorAction Stop |
      Out-Null

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

        Update-AFNativeUploadSas `
          -Context $Context `
          -Force

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

      $detail = Protect-AFNativeDiagnostic -Text $failure.Detail

      throw (
        "Azure content PUT failed. " +
        "Operation=$operation; HTTP=$($failure.Status); " +
        "RequestId=$($failure.RequestId); " +
        "ClientRequestId=$clientRequestId; " +
        "Response=$detail"
      )
    }
  }
}