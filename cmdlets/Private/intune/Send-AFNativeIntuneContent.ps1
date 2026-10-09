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
    if (-not $AzCopyPath -or -not (
        Test-Path -LiteralPath $AzCopyPath -PathType Leaf
      )) {
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

    # Start a fresh native block set against the same blob.
    # Its final block list excludes any partial AzCopy blocks.
    Update-AFNativeUploadSas -Context $Context -Force
  }

  Send-AFNativeAzureBlocks `
    -Context $Context `
    -PayloadPath $PayloadPath
}