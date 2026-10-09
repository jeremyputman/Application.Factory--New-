function Remove-AFIntuneWin32App {
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
      "Delete Intune Win32 application"
    )) {
    return
  }

  $uri = "deviceAppManagement/mobileApps/$Id"
  $writeFailure = ""

  try {
    Invoke-AFNativeGraphRequest `
      -Method DELETE `
      -Uri $uri | Out-Null
  }
  catch {
    $status = [int]$_.Exception.Data["HttpStatus"]

    if ($status -eq 404) {
      return
    }

    if ($status -notin @(0, 408, 500, 502, 503, 504)) {
      throw
    }

    $writeFailure = $_.Exception.Message
  }

  $deadline = [DateTimeOffset]::UtcNow.AddSeconds($TimeoutSeconds)

  do {
    try {
      Invoke-AFNativeGraphRequest `
        -Method GET `
        -Uri $uri | Out-Null
    }
    catch {
      if ([int]$_.Exception.Data["HttpStatus"] -eq 404) {
        return
      }

      throw
    }

    if ([DateTimeOffset]::UtcNow -ge $deadline) {
      break
    }

    Start-Sleep -Seconds 5
  }
  while ($true)

  throw "Could not confirm deletion of application $Id. $writeFailure"
}