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

  $length = (Get-Item -LiteralPath $PayloadPath -ErrorAction Stop).Length

  if (-not $AzCopyPath -and $Transport -ne "Native") {
    $command = Get-Command azcopy.exe `
      -CommandType Application `
      -ErrorAction SilentlyContinue |
    Select-Object -First 1

    if ($command) {
      $AzCopyPath = $command.Source
    }
  }

  $azCopyAvailable = (
    -not [string]::IsNullOrWhiteSpace($AzCopyPath) -and
    (Test-Path -LiteralPath $AzCopyPath -PathType Leaf)
  )

  if ($Transport -eq "AzCopy" -and -not $azCopyAvailable) {
    throw "AzCopy was requested but its executable was not found."
  }

  $tryAzCopy = (
    $Transport -eq "AzCopy" -or
    (
      $Transport -eq "Auto" -and
      $length -ge $AzCopyThresholdBytes -and
      $azCopyAvailable
    )
  )

  if (
    $Transport -eq "Auto" -and
    $length -ge $AzCopyThresholdBytes -and
    -not $azCopyAvailable
  ) {
    Write-Verbose "AzCopy is unavailable; Auto selected native upload."
    Write-AFLogEntry `
      -Message "AzCopy is unavailable; Auto selected native upload." `
      -Tag "Upload" `
      -ErrorAction Continue -WarningAction Continue

  }

  if ($tryAzCopy) {
    Write-AFLogEntry `
      -Message "Uploading $length encrypted bytes using AzCopy." `
      -Tag "Upload" `
      -ErrorAction Continue -WarningAction Continue
    $complete = Invoke-AFNativeAzCopy `
      -Context $Context `
      -PayloadPath $PayloadPath `
      -AzCopyPath $AzCopyPath `
      -DiagnosticsDirectory $DiagnosticsDirectory

    if ($complete) {
      return
    }

    # AzCopy has stopped. Clear its partial upload before
    # starting a fresh native block sequence.
    Invoke-AFNativeStoragePut `
      -Context $Context `
      -Bytes ([byte[]]::new(0)) `
      -InitializeBlob

    Write-Verbose "Partial Azure upload cleared; starting native fallback."
    Write-AFLogEntry `
      -Message "Partial Azure upload cleared; starting native fallback." `
      -Tag "Upload" `
      -ErrorAction Continue -WarningAction Continue

  }

  Write-AFLogEntry `
    -Message "Uploading $length encrypted bytes using native block transfer." `
    -Tag "Upload" `
    -ErrorAction Continue -WarningAction Continue

  Send-AFNativeAzureBlocks `
    -Context $Context `
    -PayloadPath $PayloadPath
}
