function Remove-AFClientCompletedWork {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
  param(
    [Parameter(Mandatory)][PSCustomObject]$Configuration,
    [Parameter(Mandatory)][System.Collections.IDictionary]$Journal
  )

  $ErrorActionPreference = "Stop"

  if (
    $Journal.State -ne "Complete" -or
    $Journal.Stage -ne "Complete" -or
    [string]::IsNullOrWhiteSpace([string]$Journal.AppId)
  ) {
    throw "Working files can only be removed after client processing completes."
  }

  if (
    [string]$Journal.ApplicationId -ne
    [string]$Configuration.application.id -or
    [string]$Journal.TenantId -ne
    [string]$script:appregistration_tenant -or
    [string]$Journal.ClientId -ne
    [string]$script:client_id
  ) {
    throw "Cleanup identity does not match the current client/application."
  }

  if ([string]::IsNullOrWhiteSpace([string]$script:working_folder)) {
    throw "The working folder is not configured."
  }

  $root = [IO.Path]::GetFullPath(
    [string]$script:working_folder
  ).TrimEnd([IO.Path]::DirectorySeparatorChar)

  $slug = [string]$Configuration.application.slug

  if ($slug -notmatch '^[a-zA-Z0-9][a-zA-Z0-9._-]*$') {
    throw "The application slug is not safe for working-folder cleanup."
  }

  $downloadRoot = Join-Path $root "Download"
  $downloadPath = [IO.Path]::GetFullPath(
    (Join-Path $downloadRoot $slug)
  )

  if ([IO.Path]::GetDirectoryName($downloadPath) -ne $downloadRoot) {
    throw "The download directory is outside the expected parent."
  }

  $targets = @($downloadPath)

  if (-not [string]::IsNullOrWhiteSpace(
      [string]$Journal.WorkDirectory
    )) {
    $nativeRoot = Join-Path $root "NativeUploads"
    $nativePath = [IO.Path]::GetFullPath(
      [string]$Journal.WorkDirectory
    ).TrimEnd([IO.Path]::DirectorySeparatorChar)

    if (
      [IO.Path]::GetDirectoryName($nativePath) -ne $nativeRoot -or
      [IO.Path]::GetFileName($nativePath) -notmatch
      '^[a-fA-F0-9]{32}$'
    ) {
      throw "The native upload directory is outside the expected location."
    }

    $targets += $nativePath
  }

  # Validate every target and its parents before deleting anything.
  foreach ($target in $targets) {
    $current = $target

    while ($true) {
      if (Test-Path -LiteralPath $current) {
        $item = Get-Item `
          -LiteralPath $current `
          -Force `
          -ErrorAction Stop

        if (
          -not $item.PSIsContainer -or
          ($item.Attributes -band
          [IO.FileAttributes]::ReparsePoint)
        ) {
          throw "Cleanup refuses a file, junction, or symbolic link: $current"
        }
      }

      if ($current -eq $root) {
        break
      }

      $current = [IO.Path]::GetDirectoryName($current)

      if ([string]::IsNullOrWhiteSpace($current)) {
        throw "Cleanup could not validate the working-folder boundary."
      }
    }
  }

  foreach ($target in $targets) {
    if (
      (Test-Path -LiteralPath $target -PathType Container) -and
      $PSCmdlet.ShouldProcess(
        $target,
        "Remove completed application working files"
      )
    ) {
      Remove-Item `
        -LiteralPath $target `
        -Recurse `
        -Force `
        -ErrorAction Stop

      Write-Verbose "Removed completed working directory: $target"
    }
  }
}