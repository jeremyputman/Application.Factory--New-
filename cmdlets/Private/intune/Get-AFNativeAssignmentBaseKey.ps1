function Get-AFNativeAssignmentBaseKey {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]$Assignment
  )

  $key = Get-AFClientAssignmentKey -Assignment $Assignment
  return ($key.Split("|")[0..2] -join "|")
}