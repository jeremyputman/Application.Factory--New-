function Invoke-AFNativeAzCopy {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$Context,
    [Parameter(Mandatory)][string]$PayloadPath,
    [Parameter(Mandatory)][string]$AzCopyPath,
    [Parameter(Mandatory)][string]$DiagnosticsDirectory
  )

  Update-AFNativeUploadSas -Context $Context
  [IO.Directory]::CreateDirectory($DiagnosticsDirectory) | Out-Null

  $expiration = Get-AFNativeSasExpiration -File $Context.File

  $startInfo = [Diagnostics.ProcessStartInfo]::new()
  $startInfo.FileName = $AzCopyPath
  $startInfo.UseShellExecute = $false
  $startInfo.CreateNoWindow = $true
  $startInfo.RedirectStandardOutput = $true
  $startInfo.RedirectStandardError = $true

  $startInfo.Environment["AZCOPY_LOG_LOCATION"] =
  $DiagnosticsDirectory

  $startInfo.Environment["AZCOPY_JOB_PLAN_LOCATION"] =
  $DiagnosticsDirectory

  foreach ($argument in @(
      "copy",
      $PayloadPath,
      [string]$Context.File.azureStorageUri,
      "--from-to=LocalBlob",
      "--blob-type=BlockBlob",
      "--overwrite=true",
      "--check-length=true",
      "--output-type=json",
      "--log-level=ERROR"
    )) {
    $startInfo.ArgumentList.Add($argument)
  }

  $process = [Diagnostics.Process]::new()
  $process.StartInfo = $startInfo

  try {
    if (-not $process.Start()) {
      throw "AzCopy process did not start."
    }

    # Drain both pipes asynchronously to prevent deadlocks.
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $interrupted = $false

    while (-not $process.WaitForExit(1000)) {
      if (
        [DateTimeOffset]::UtcNow -ge $Context.Deadline -or
        [DateTimeOffset]::UtcNow -ge $expiration.AddSeconds(-60)
      ) {
        $interrupted = $true
        $process.Kill($true)
        $process.WaitForExit()
        break
      }
    }

    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()

    $summary = $null

    # AzCopy emits newline-delimited JSON envelopes.
    foreach ($line in ($stdout -split '\r?\n')) {
      if ([string]::IsNullOrWhiteSpace($line)) {
        continue
      }

      try {
        $envelope = ConvertFrom-Json -InputObject $line

        if ($envelope.MessageType -eq "EndOfJob") {
          $summary = ConvertFrom-Json `
            -InputObject $envelope.MessageContent
        }
      }
      catch {
        # Ignore informational lines that are not JSON.
      }
    }

    if ($summary.JobID) {
      $Context.AzCopyJobId = [string]$summary.JobID
    }

    $safeOutput = Protect-AFNativeDiagnostic -Text (
      $stdout + [Environment]::NewLine + $stderr
    )

    [IO.File]::WriteAllText(
      (Join-Path $DiagnosticsDirectory "console.redacted.txt"),
      $safeOutput
    )

    if (
      -not $interrupted -and
      $process.ExitCode -eq 0 -and
      $summary -and
      $summary.JobStatus -eq "Completed" -and
      [int]$summary.TransfersCompleted -eq 1 -and
      [int]$summary.TransfersFailed -eq 0 -and
      [int]$summary.TransfersSkipped -eq 0
    ) {
      $Context.TransportUsed = "AzCopy"
      return $true
    }

    Write-Warning (
      "AzCopy did not confirm a complete upload. " +
      "ExitCode=$($process.ExitCode); " +
      "Interrupted=$interrupted; " +
      "Diagnostics=$DiagnosticsDirectory. " +
      "Switching to native block upload."
    )

    return $false
  }
  finally {
    # Ensure fallback cannot race a still-running AzCopy process.
    try {
      if ($process.Id -and -not $process.HasExited) {
        $process.Kill($true)
        $process.WaitForExit()
      }
    }
    catch {}

    $process.Dispose()
  }
}