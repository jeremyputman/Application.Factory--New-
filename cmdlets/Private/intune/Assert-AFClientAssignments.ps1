function Assert-AFClientAssignments {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)]$Plan,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

  do {
    $actual = @(
      Get-AFClientGraphCollection `
        -Uri "deviceAppManagement/mobileApps/$AppId/assignments" |
      ForEach-Object {
        Get-AFClientAssignmentKey -Assignment $_
      } |
      Sort-Object -Unique
    )

    $missing = @(
      $Plan.ExpectedKeys | Where-Object { $_ -notin $actual }
    )

    $unexpected = @(
      $actual | Where-Object { $_ -notin $Plan.ExpectedKeys }
    )

    if ($missing.Count -eq 0 -and $unexpected.Count -eq 0) {
      return
    }

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw (
    "Assignment verification failed for app $AppId. " +
    "Missing: $($missing -join ', '); " +
    "Unexpected: $($unexpected -join ', '). " +
    "Previous assignments and versions have not been removed."
  )
}