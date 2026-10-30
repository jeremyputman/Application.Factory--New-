function New-AFUpdaterDetectionRules {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$UpdaterRequirements,
    [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$NormalDetectionRules,
    [Parameter(Mandatory)][string]$PublishedVersion
  )
  foreach ($rule in $UpdaterRequirements) {
    if ($rule.detectionType -ne "version" -or $rule.operator -ne "lessThan") { continue }
    $kind = ([string]$rule.'@odata.type').TrimStart('#')
    if ($kind -notin @("microsoft.graph.win32LobAppFileSystemRequirement", "microsoft.graph.win32LobAppRegistryRequirement")) { continue }
    $version = $null
    if ($PublishedVersion -notmatch '^\d+\.\d+(?:\.\d+){0,2}$' -or -not [version]::TryParse($PublishedVersion, [ref]$version)) {
      throw "File/registry updater detection requires a numeric target version. Use a target-aware detection script for other version formats."
    }
    if ($kind -eq "microsoft.graph.win32LobAppFileSystemRequirement") {
      return @{
        "@odata.type"="#microsoft.graph.win32LobAppFileSystemDetection"
        path=$rule.path; fileOrFolderName=$rule.fileOrFolderName
        check32BitOn64System=$rule.check32BitOn64System
        detectionType="version"; operator="greaterThanOrEqual"
        detectionValue=$PublishedVersion
      }
    }
    return @{
      "@odata.type"="#microsoft.graph.win32LobAppRegistryDetection"
      keyPath=$rule.keyPath; valueName=$rule.valueName
      check32BitOn64System=$rule.check32BitOn64System
      detectionType="version"; operator="greaterThanOrEqual"
      detectionValue=$PublishedVersion
    }
  }
  foreach ($rule in $NormalDetectionRules) {
    $copy = ConvertTo-Json -InputObject $rule -Depth 20 | ConvertFrom-Json -AsHashtable -DateKind String
    $kind = ([string]$copy.'@odata.type').TrimStart('#')
    switch ($kind) {
      "microsoft.graph.win32LobAppProductCodeDetection" {
        if ([string]::IsNullOrWhiteSpace([string]$copy.productVersion)) { throw "Updater MSI detection requires the target product version." }
        $copy.productVersionOperator = "greaterThanOrEqual"
      }
      "microsoft.graph.win32LobAppRegistryDetection" {
        if ($copy.detectionType -ne "version" -or [string]::IsNullOrWhiteSpace([string]$copy.detectionValue)) {
          throw "Presence-only detection cannot detect updater completion. Configure a file/registry version gate using the published version, or a target-aware detection script."
        }
        $copy.operator = "greaterThanOrEqual"
      }
      "microsoft.graph.win32LobAppPowerShellScriptDetection" {
        # The author-supplied script must check the target version.
      }
      default { throw "Unsupported updater detection type." }
    }
    $copy
  }
}
