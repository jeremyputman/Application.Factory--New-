function Get-AFIntuneWin32App {
  [CmdletBinding(DefaultParameterSetName = "All")]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = "Id")]
    [ValidateNotNullOrEmpty()][string]$Id,
    [Parameter(Mandatory = $true, ParameterSetName = "DisplayName")][ValidateNotNullOrEmpty()][string]$DisplayName,
    [Parameter()][switch]$Failed
  )

  $filters = [System.Collections.Generic.List[string]]::new()
  $filters.Add("isof('microsoft.graph.win32LobApp')")
  $filters.Add("contains(notes,'AppFactoryID:')")

  if ($PSBoundParameters.ContainsKey("Id")) {
    $escapedId = $Id.Replace("'", "''")
    $filters.Add("id eq '$escapedId'")
  }

  if ($PSBoundParameters.ContainsKey("DisplayName")) {
    $escapedDisplayName = $DisplayName.Replace("'", "''")
    $filters.Add("contains(displayName,'$escapedDisplayName')")
  }

  if ($Failed.IsPresent) {
    # Keep failed-state filtering local because Intune's app-level
    # upload state representation has changed over time.
    # This also lets us recognize more than one failure state.
  }

  $filter = $filters -join " and "
  $encodedFilter = [System.Uri]::EscapeDataString($filter)
  $uri = "deviceAppManagement/mobileApps?`$filter=$encodedFilter"
  $applications = [System.Collections.Generic.List[PSCustomObject]]::new()

  try {
    do {
      $response = Invoke-AFGraphRequest `
        -Method GET `
        -Uri $uri `
        -ApiVersion beta

      foreach ($item in @($response.value)) {
        $applications.Add($item)
      }

      $uri = $response.'@odata.nextLink'
    }
    while ($uri)

    if ($Failed.IsPresent) {
      return @(
        $applications |
        Where-Object {
          $_.uploadState -in @(
            0,
            "error",
            "transientError",
            "commitFileFailed",
            "commitFileTimedOut"
          )
        }
      )
    }

    return @($applications)
  }
  catch {
    throw "Unable to retrieve Intune Win32 applications. $($_.Exception.Message)"
  }
}