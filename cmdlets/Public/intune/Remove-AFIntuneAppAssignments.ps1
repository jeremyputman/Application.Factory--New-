function Remove-AFIntuneAppAssignments {
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory)][guid]$Id,
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version,
    [string]$ProtectedAppId = [string]$script:published_application.id,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )

  $app = Get-AFNativeManagedApp `
    -Id $Id `
    -ApplicationId $ApplicationId `
    -Version $Version `
    -ProtectedAppId $ProtectedAppId

  if ($null -eq $app) {
    return
  }

  if (-not $PSCmdlet.ShouldProcess(
      "$($app.displayName) [$Id]",
      "Remove application assignments"
    )) {
    return
  }

  $uri = "deviceAppManagement/mobileApps/$Id/assignments"
  $assignments = @(Get-AFClientGraphCollection -Uri $uri)

  foreach ($assignment in $assignments) {
    $assignmentId = [string]$assignment.id

    if ([string]::IsNullOrWhiteSpace($assignmentId)) {
      throw "An assignment has no assignment ID."
    }

    # Revalidate ownership immediately before each deletion.
    $verifiedApp = Get-AFNativeManagedApp `
      -Id $Id `
      -ApplicationId $ApplicationId `
      -Version $Version `
      -ProtectedAppId $ProtectedAppId

    if ($null -eq $verifiedApp) {
      return
    }

    # Assignment IDs are opaque strings, not necessarily GUIDs.
    $encodedId = [uri]::EscapeDataString($assignmentId)
    $assignmentUri = "$uri/$encodedId"

    try {
      Invoke-AFNativeGraphRequest `
        -Method DELETE `
        -Uri $assignmentUri |
      Out-Null
    }
    catch {
      $status = [int]$_.Exception.Data["HttpStatus"]

      if ($status -eq 404) {
        continue
      }

      if ($status -notin @(0, 408, 500, 502, 503, 504)) {
        throw
      }

      # Reconcile an ambiguous response without repeating deletion.
      try {
        Invoke-AFNativeGraphRequest `
          -Method GET `
          -Uri $assignmentUri |
        Out-Null
      }
      catch {
        if ([int]$_.Exception.Data["HttpStatus"] -eq 404) {
          continue
        }

        throw
      }

      throw "Could not confirm deletion of assignment $assignmentId."
    }
  }

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

  do {
    try {
      $remaining = @(Get-AFClientGraphCollection -Uri $uri)
    }
    catch {
      if ([int]$_.Exception.Data["HttpStatus"] -eq 404) {
        return
      }

      throw
    }

    if ($remaining.Count -eq 0) {
      return
    }

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw (
    "Application $Id still has assignments after removal. " +
    "A concurrent change or incomplete deletion may have occurred."
  )
}