function Set-AFApplicationClientESPAssignments {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][PSCustomObject]$configuration
  )

  $appId = [string]$script:published_application.id

  if ([string]::IsNullOrWhiteSpace($appId)) {
    throw "A published application ID is required for ESP assignments."
  }

  $names = @(
    [string]$configuration.esp_assignments -split "," |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    Select-Object -Unique
  )

  foreach ($name in $names) {
    $esp = Get-AFClientUniqueGraphObject `
      -Resource "deviceManagement/deviceEnrollmentConfigurations" `
      -DisplayName $name

    if (
      $esp.'@odata.type' -ne
      "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
    ) {
      throw "'$name' is not a Windows ESP configuration."
    }

    $current = @(
      $esp.selectedMobileAppIds | Where-Object { $_ }
    )

    if ($appId -notin $current) {
      $newIds = @(
        @($current) + @($appId) |
        Select-Object -Unique
      )

      Invoke-AFNativeGraphRequest `
        -Method PATCH `
        -Uri (
        "deviceManagement/deviceEnrollmentConfigurations/" +
        $esp.id
      ) `
        -Body @{
        "@odata.type"            =
        "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
        showInstallationProgress = $true
        selectedMobileAppIds     = $newIds
      } | Out-Null
    }

    $confirmed = Invoke-AFNativeGraphRequest `
      -Method GET `
      -Uri (
      "deviceManagement/deviceEnrollmentConfigurations/" +
      $esp.id
    )

    if ($appId -notin @($confirmed.selectedMobileAppIds)) {
      throw "ESP '$name' did not retain application $appId."
    }
  }
}