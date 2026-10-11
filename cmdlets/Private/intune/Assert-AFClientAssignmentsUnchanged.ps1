function Assert-AFClientAssignmentsUnchanged {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][guid]$AppId,
    [Parameter(Mandatory)]
    [AllowEmptyCollection()]
    [object[]]$ExpectedAssignments
  )

  $actual = @(
    Get-AFClientGraphCollection `
      -Uri "deviceAppManagement/mobileApps/$AppId/assignments"
  )
  if ($actual.Count -ne $ExpectedAssignments.Count) {
    throw "Assignments changed during replacement. AppId=$AppId; no assignment writes were attempted."
  }

  foreach ($expected in $ExpectedAssignments) {
    $id = [string]$expected.id
    if ([string]::IsNullOrWhiteSpace($id)) {
      throw "The saved assignment snapshot contains an empty ID."
    }
    $matches = @($actual | Where-Object { [string]$_.id -ceq $id })
    if ($matches.Count -ne 1) {
      throw "Assignment identity changed during replacement. AppId=$AppId; AssignmentId=$id"
    }

    $expectedBody = ConvertTo-Json -InputObject $expected -Depth 30 |
    ConvertFrom-Json -AsHashtable
    $actualBody = ConvertTo-Json -InputObject $matches[0] -Depth 30 |
    ConvertFrom-Json -AsHashtable

    if (
      -not (Test-AFNativeJsonSubset -Expected $expectedBody -Actual $actualBody) -or
      -not (Test-AFNativeJsonSubset -Expected $actualBody -Actual $expectedBody)
    ) {
      throw (
        "Assignment settings changed during replacement. " +
        "AppId=$AppId; AssignmentId=$id. No restoration was attempted."
      )
    }
  }

  Write-Verbose "Verified existing assignment IDs and settings were preserved."
}
