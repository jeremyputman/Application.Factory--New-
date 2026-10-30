function Assert-AFClientAssignments {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$AppId,
    [Parameter(Mandatory)]$Plan,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)
  $details = ""

  do {
    $actual = @(
      Get-AFClientGraphCollection `
        -Uri "deviceAppManagement/mobileApps/$AppId/assignments"
    )

    $actualKeys = @(
      $actual | ForEach-Object {
        Get-AFClientAssignmentKey -Assignment $_
      }
    )

    $missing = @(
      $Plan.ExpectedKeys | Where-Object { $_ -notin $actualKeys }
    )

    $unexpected = @(
      $actualKeys | Where-Object { $_ -notin $Plan.ExpectedKeys }
    )

    $duplicates = @(
      $actualKeys |
      Group-Object |
      Where-Object { $_.Count -gt 1 }
    )

    $settingsMismatch = @(
      foreach ($expected in @($Plan.Assignments)) {
        $key = Get-AFClientAssignmentKey -Assignment $expected

        $match = @(
          $actual | Where-Object {
            (Get-AFClientAssignmentKey -Assignment $_) -eq $key
          }
        )

        if (
          $match.Count -eq 1 -and
          -not (Test-AFNativeAssignmentMatches `
              -Expected $expected `
              -Actual $match[0])
        ) {
          $key
        }
      }
    )

    if (
      $missing.Count -eq 0 -and
      $unexpected.Count -eq 0 -and
      $duplicates.Count -eq 0 -and
      $settingsMismatch.Count -eq 0
    ) {
      return
    }

    $details = (
      "Missing=$($missing -join ', '); " +
      "Unexpected=$($unexpected -join ', '); " +
      "Duplicate=$($duplicates.Name -join ', '); " +
      "SettingsMismatch=$($settingsMismatch -join ', ')."
    )

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw (
    "Assignment verification failed for app $AppId. " +
    "$details Previous-version cleanup was not authorized to proceed."
  )
}