function New-AFClientRoleConfigurations {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Configurations,
    [switch]$DownloadOnly,
    [ValidateSet("normal", "updater")][string]$ResumeRole
  )
  foreach ($configuration in $Configurations) {
    $enabled = $false
    $property = $configuration.PSObject.Properties["create_updater_app"]
    if ($null -ne $property) {
      if ($property.Value -isnot [bool]) { throw "create_updater_app must be a JSON boolean." }
      $enabled = $property.Value
    }
    if ($ResumeRole -eq "updater" -and -not $enabled) {
      throw "Enable updater mode before resuming an updater publication."
    }
    $roles = @("normal")
    if ($enabled -and -not $DownloadOnly) { $roles += "updater" }
    foreach ($role in $roles) {
      if ($ResumeRole -and $role -ne $ResumeRole) { continue }
      $copy = ConvertTo-Json -InputObject $configuration -Depth 30 |
        ConvertFrom-Json -DateKind String
      $copy | Add-Member -NotePropertyName PublicationRole -NotePropertyValue $role -Force
      if ($role -eq "updater") {
        $copy | Add-Member -NotePropertyName dependencies -NotePropertyValue @() -Force
        $copy | Add-Member -NotePropertyName reconcile_reverse_dependencies -NotePropertyValue $false -Force
        foreach ($field in @(
            "assignment_available", "assignment_available_exceptions",
            "assignment_required_exceptions", "assignment_uninstall",
            "assignment_uninstall_exceptions"
          )) {
          $copy | Add-Member -NotePropertyName $field -NotePropertyValue @() -Force
        }
        $copy | Add-Member -NotePropertyName assignment_required -NotePropertyValue @([pscustomobject]@{ name = "All Devices" }) -Force
        foreach ($field in @("copy_previous_assignments", "interactive_install", "interactive_uninstall")) {
          $copy | Add-Member -NotePropertyName $field -NotePropertyValue $false -Force
        }
        $copy | Add-Member -NotePropertyName unassign_previous_assignments -NotePropertyValue $true -Force
        foreach ($field in @("esp_assignments", "filters")) {
          $copy | Add-Member -NotePropertyName $field -NotePropertyValue "" -Force
        }
        $copy | Add-Member -NotePropertyName assignment_filters -NotePropertyValue @() -Force
      }
      $copy
    }
  }
}
