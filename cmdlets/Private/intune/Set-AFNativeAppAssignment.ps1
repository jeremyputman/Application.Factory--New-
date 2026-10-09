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

  $current = @(
    Get-AFClientGraphCollection -Uri $uri
  )

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

  $writeFailure = ""

  try {
    if ($matches.Count -eq 1) {
      if (-not $matches[0].id) {
        throw "Existing assignment has no assignment ID."
      }

      Invoke-AFNativeGraphRequest `
        -Method PATCH `
        -Uri "$uri/$($matches[0].id)" `
        -Body $body | Out-Null
    }
    else {
      Invoke-AFNativeGraphRequest `
        -Method POST `
        -Uri $uri `
        -Body $body | Out-Null
    }
  }
  catch {
    $status = [int]$_.Exception.Data["HttpStatus"]

    if ($status -notin @(0, 408, 500, 502, 503, 504)) {
      throw
    }

    # A lost response may conceal a successful write.
    # Read back rather than blindly creating another assignment.
    $writeFailure = $_.Exception.Message
  }

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

  do {
    $confirmed = @(
      Get-AFClientGraphCollection -Uri $uri |
      Where-Object {
        (Get-AFNativeAssignmentBaseKey -Assignment $_) -eq
        $baseKey
      }
    )

    if ($confirmed.Count -gt 1) {
      throw "Duplicate assignments detected after writing: $baseKey"
    }

    if (
      $confirmed.Count -eq 1 -and
      (Test-AFNativeAssignmentMatches `
        -Expected $body `
        -Actual $confirmed[0])
    ) {
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