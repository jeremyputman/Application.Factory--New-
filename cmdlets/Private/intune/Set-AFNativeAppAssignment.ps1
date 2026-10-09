function Set-AFNativeAppAssignment {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][guid]$AppId,
    [Parameter(Mandatory)]$Assignment,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )

  $body = ConvertTo-AFNativeAssignmentBody -Assignment $Assignment
  $baseKey = Get-AFNativeAssignmentBaseKey -Assignment $body
  $uri = "deviceAppManagement/mobileApps/$AppId/assignments"

  $current = @(Get-AFClientGraphCollection -Uri $uri)

  $matches = @(
    $current | Where-Object {
      (Get-AFNativeAssignmentBaseKey -Assignment $_) -eq $baseKey
    }
  )

  if ($matches.Count -gt 1) {
    throw "Multiple existing assignments have the same target/intent: $baseKey"
  }

  if (
    $matches.Count -eq 1 -and
    (Test-AFNativeAssignmentMatches `
      -Expected $body `
      -Actual $matches[0])
  ) {
    return
  }

  $updating = $matches.Count -eq 1
  $expected = @($body)
  $writeUri = $uri
  $writeBody = $body

  if ($updating) {
    # The assign action receives the complete desired collection.
    # Preserve every existing assignment except the requested change.
    $seen = @{}

    $expected = @(
      foreach ($existing in $current) {
        $source = [string]$existing.source

        if ($source -and $source -ne "direct") {
          throw (
            "Cannot rewrite an assignment collection containing " +
            "a non-direct assignment. Source=$source; " +
            "AssignmentId=$($existing.id)"
          )
        }

        $key = Get-AFNativeAssignmentBaseKey -Assignment $existing

        if ($seen.ContainsKey($key)) {
          throw "Duplicate target/intent in the current collection: $key"
        }

        $seen[$key] = $true

        if ($key -eq $baseKey) {
          $body
        }
        else {
          ConvertTo-AFNativeAssignmentBody -Assignment $existing
        }
      }
    )

    $writeUri = "deviceAppManagement/mobileApps/$AppId/assign"
    $writeBody = @{
      mobileAppAssignments = @($expected)
    }
  }

  $writeFailure = ""

  try {
    Invoke-AFNativeGraphRequest `
      -Method POST `
      -Uri $writeUri `
      -Body $writeBody |
    Out-Null
  }
  catch {
    $status = [int]$_.Exception.Data["HttpStatus"]

    if ($status -notin @(0, 408, 500, 502, 503, 504)) {
      throw
    }

    # An ambiguous response may conceal a successful write.
    # Reconcile through GETs instead of repeating the POST.
    $writeFailure = $_.Exception.Message
  }

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

  do {
    $actual = @(Get-AFClientGraphCollection -Uri $uri)
    $allMatched = $true

    if ($updating -and $actual.Count -ne $expected.Count) {
      $allMatched = $false
    }

    foreach ($desired in $expected) {
      $desiredKey = Get-AFNativeAssignmentBaseKey -Assignment $desired

      $confirmed = @(
        $actual | Where-Object {
          (Get-AFNativeAssignmentBaseKey -Assignment $_) -eq
          $desiredKey
        }
      )

      if ($confirmed.Count -gt 1) {
        throw "Duplicate assignments detected after writing: $desiredKey"
      }

      if ($confirmed.Count -ne 1) {
        $allMatched = $false
        continue
      }

      if (-not (Test-AFNativeAssignmentMatches `
            -Expected $desired `
            -Actual $confirmed[0])) {
        $allMatched = $false
      }
    }

    if ($allMatched) {
      return
    }

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw (
    "Assignment write could not be confirmed. " +
    "AppId=$AppId; Target=$baseKey. " +
    "$writeFailure"
  )
}