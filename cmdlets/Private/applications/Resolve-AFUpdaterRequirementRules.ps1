function Resolve-AFUpdaterRequirementRules {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][AllowNull()]$Rules,
    [Parameter(Mandatory)][string]$PublishedVersion
  )
  if ($null -eq $Rules) { throw "Updater requirement rules are missing; regenerate App.json." }
  $items = ConvertTo-Json -InputObject $Rules -Depth 20 |
    ConvertFrom-Json -AsHashtable -NoEnumerate -DateKind String
  if ($items -isnot [System.Collections.IList] -or $items.Count -eq 0) {
    throw "An updater requires at least one updater-specific requirement rule."
  }
  foreach ($item in $items) {
    if ($item -isnot [System.Collections.IDictionary]) { throw "Updater rule must be an object." }
    $source = "literal"
    if ($item.ContainsKey("value_source")) {
      $source = $item["value_source"]
      if ($source -isnot [string]) { throw "Updater comparison value source must be text." }
      $item.Remove("value_source") | Out-Null
    }
    if ($source -cnotin @("literal", "published_version")) { throw "Unsupported updater comparison value source." }
    if ($source -ceq "published_version") {
      if ($item.detectiontype -cne "version" -or $item.operator -cne "lessThan") {
        throw "Use published version only with a Version / Less than updater requirement."
      }
      if ($item.ContainsKey("value") -and -not [string]::IsNullOrEmpty([string]$item.value)) {
        throw "Published version cannot be combined with a literal comparison value."
      }
      $version = $null
      if ($PublishedVersion -notmatch '^\d+\.\d+(?:\.\d+){0,2}$' -or
          -not [version]::TryParse($PublishedVersion, [ref]$version)) {
        throw "The published version is not a supported numeric version; configure a literal or script-based gate."
      }
      $item["value"] = $PublishedVersion
    }
    $item
  }
}
