function Send-AFNativeIntuneContent {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$Context,
    [Parameter(Mandatory)][string]$PayloadPath,
    [ValidateSet("Auto", "Native", "AzCopy")][string]$Transport = "Auto",
    [string]$AzCopyPath,
    [long]$AzCopyThresholdBytes = 100MB,
    [Parameter(Mandatory)][string]$DiagnosticsDirectory
  )

  $length = (Get-Item -LiteralPath $PayloadPath).Length

  if (-not $AzCopyPath) {
    $command = Get-Command azcopy.exe `
      -CommandType Application `
      -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if ($command) {
      $AzCopyPath = $command.Source
    }
  }

  $tryAzCopy = (
    $Transport -eq "AzCopy" -or
    (
      $Transport -eq "Auto" -and
      $length -ge $AzCopyThresholdBytes -and
      $AzCopyPath
    )
  )

  if ($tryAzCopy) {
    if (
      -not $AzCopyPath -or
      -not (Test-Path -LiteralPath $AzCopyPath -PathType Leaf)
    ) {
      throw "AzCopy was requested but its executable was not found."
    }

    $complete = Invoke-AFNativeAzCopy `
      -Context $Context `
      -PayloadPath $PayloadPath `
      -AzCopyPath $AzCopyPath `
      -DiagnosticsDirectory $DiagnosticsDirectory

    if ($complete) {
      return
    }

    # Invoke-AFNativeAzCopy ensures its process has stopped.
    # Reset this uncommitted blob before using native block IDs.
    # The storage helper renews only when needed.
    Invoke-AFNativeStoragePut `
      -Context $Context `
      -Bytes ([byte[]]::new(0)) `
      -InitializeBlob

    Write-Verbose "Partial Azure upload cleared; starting native fallback."
  }

  Send-AFNativeAzureBlocks `
    -Context $Context `
    -PayloadPath $PayloadPath
}