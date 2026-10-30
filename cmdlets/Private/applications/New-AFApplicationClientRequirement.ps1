function New-AFApplicationClientRequirement {
  [CmdletBinding()]
  param(
    [Parameter()][AllowNull()]$Rules
  )

  # Older App.json files omit additional rules.
  if ($null -eq $Rules) { return }

  $items = ConvertTo-Json -InputObject $Rules -Depth 20 |
    ConvertFrom-Json -AsHashtable -NoEnumerate -DateKind String

  if ($items -isnot [System.Collections.IList]) {
    throw "Additional requirement rules must be an array."
  }

  $types = @{
    file     = @(
      "exists", "doesNotExist", "modifiedDate",
      "createdDate", "version", "sizeInMB"
    )
    registry = @(
      "exists", "doesNotExist", "string", "integer", "version"
    )
    script   = @(
      "string", "dateTime", "integer", "float", "version", "boolean"
    )
  }

  $fields = @{
    file     = @("path", "fileorfoldername", "check32biton64system")
    registry = @("keypath", "valuename", "check32biton64system")
    script   = @(
      "displayname", "script", "runas32bit",
      "runasaccount", "enforcesignaturecheck"
    )
  }

  $operators = @(
    "equal", "notEqual", "greaterThan",
    "greaterThanOrEqual", "lessThan", "lessThanOrEqual"
  )

  $booleanFields = @(
    "check32biton64system", "runas32bit", "enforcesignaturecheck"
  )

  $names = @{}
  $index = 0

  foreach ($r in $items) {
    $index++

    if ($r -isnot [System.Collections.IDictionary]) {
      throw "Requirement rule ${index}: expected an object."
    }

    function Read-RequirementText {
      param([string]$Name, [switch]$Required)

      if (-not $r.ContainsKey($Name)) {
        if ($Required) {
          throw "Requirement rule ${index}: $Name is required."
        }
        return ""
      }

      if ($r[$Name] -isnot [string]) {
        throw "Requirement rule ${index}: $Name must be text."
      }

      $text = [string]$r[$Name]
      if ($Required -and [string]::IsNullOrWhiteSpace($text)) {
        throw "Requirement rule ${index}: $Name is required."
      }
      return $text
    }

    function Read-RequirementFlag {
      param([string]$Name)

      if (-not $r.ContainsKey($Name)) { return $false }
      if ($r[$Name] -isnot [bool]) {
        throw "Requirement rule ${index}: $Name must be a boolean."
      }
      return [bool]$r[$Name]
    }

    $kind = Read-RequirementText -Name type -Required
    if ($kind -cnotin @("file", "registry", "script")) {
      throw "Requirement rule ${index}: unsupported type '$kind'."
    }

    $allowed = @("type", "detectiontype", "operator", "value") +
    $fields[$kind]

    foreach ($name in $r.Keys) {
      if ($name -cnotin $allowed) {
        throw "Requirement rule ${index}: unsupported field '$name'."
      }

      if ($name -cin $booleanFields) {
        if ($r[$name] -isnot [bool]) {
          throw "Requirement rule ${index}: $name must be a boolean."
        }
      }
      elseif ($r[$name] -isnot [string]) {
        throw "Requirement rule ${index}: $name must be text."
      }
    }

    $detectionType = Read-RequirementText -Name detectiontype -Required
    if ($detectionType -cnotin $types[$kind]) {
      throw "Requirement rule ${index}: unsupported property/output type."
    }

    $exists = $detectionType -cin @("exists", "doesNotExist")
    $operator = Read-RequirementText -Name operator
    $value = Read-RequirementText -Name value

    if ($exists) {
      if ($operator -and $operator -cne "notConfigured") {
        throw "Requirement rule ${index}: existence checks have no operator."
      }
      if ($value) {
        throw "Requirement rule ${index}: existence checks have no value."
      }
      $operator = "notConfigured"
      $value = $null
    }
    else {
      $operator = Read-RequirementText -Name operator -Required
      $value = Read-RequirementText -Name value -Required

      if ($operator -cnotin $operators) {
        throw "Requirement rule ${index}: unsupported operator."
      }

      if (
        $detectionType -cin @("string", "boolean") -and
        $operator -cnotin @("equal", "notEqual")
      ) {
        throw "Requirement rule ${index}: use equal or notEqual."
      }

      switch -CaseSensitive ($detectionType) {
        "integer" {
          $number = [long]0
          if (
            $value -notmatch '^[+-]?\d+$' -or
            -not [long]::TryParse($value, [ref]$number)
          ) {
            throw "Requirement rule ${index}: invalid integer."
          }
        }
        { $_ -cin @("float", "sizeInMB") } {
          $number = [double]0
          $numericPattern =
          '^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?$'

          if (
            $value -notmatch $numericPattern -or
            -not [double]::TryParse(
              $value,
              [Globalization.NumberStyles]::Float,
              [Globalization.CultureInfo]::InvariantCulture,
              [ref]$number
            ) -or
            [double]::IsNaN($number) -or
            [double]::IsInfinity($number) -or
            ($detectionType -ceq "sizeInMB" -and $number -lt 0)
          ) {
            throw "Requirement rule ${index}: invalid numeric value."
          }
        }
        "version" {
          $version = $null
          if (
            $value -notmatch '^\d+\.\d+(?:\.\d+){0,2}$' -or
            -not [version]::TryParse($value, [ref]$version)
          ) {
            throw "Requirement rule ${index}: invalid version."
          }
        }
        "boolean" {
          if ($value -cnotin @("true", "false")) {
            throw "Requirement rule ${index}: use true or false."
          }
        }
        { $_ -cin @("dateTime", "modifiedDate", "createdDate") } {
          $date = [DateTimeOffset]::MinValue
          $datePattern =
          '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}' +
          '(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$'

          if (
            $value -notmatch $datePattern -or
            -not [DateTimeOffset]::TryParse(
              $value,
              [Globalization.CultureInfo]::InvariantCulture,
              [Globalization.DateTimeStyles]::None,
              [ref]$date
            )
          ) {
            throw "Requirement rule ${index}: invalid ISO date/time."
          }
        }
      }
    }

    $graphRule = @{
      operator       = $operator
      detectionValue = $value
      detectionType  = $detectionType
    }

    switch -CaseSensitive ($kind) {
      "file" {
        $filename = Read-RequirementText -Name fileorfoldername -Required
        if ($filename -in @(".", "..") -or $filename -match '[/\\]') {
          throw "Requirement rule ${index}: use a file/folder name."
        }

        $graphRule["@odata.type"] =
        "#microsoft.graph.win32LobAppFileSystemRequirement"
        $graphRule.path = Read-RequirementText -Name path -Required
        $graphRule.fileOrFolderName = $filename
        $graphRule.check32BitOn64System =
        Read-RequirementFlag -Name check32biton64system
      }

      "registry" {
        $keyPath = Read-RequirementText -Name keypath -Required

        # Accept the same familiar hive notation used by detection settings.
        $keyPath = $keyPath -replace '^HKLM:?\\', 'HKEY_LOCAL_MACHINE\'
        $keyPath = $keyPath -replace '^HKCU:?\\', 'HKEY_CURRENT_USER\'
        $keyPath = $keyPath -replace
        '^(HKEY_LOCAL_MACHINE|HKEY_CURRENT_USER):\\', '$1\'

        $graphRule["@odata.type"] =
        "#microsoft.graph.win32LobAppRegistryRequirement"
        $graphRule.keyPath = $keyPath
        $graphRule.valueName = Read-RequirementText -Name valuename
        $graphRule.check32BitOn64System =
        Read-RequirementFlag -Name check32biton64system
      }

      "script" {
        $displayName = Read-RequirementText -Name displayname -Required
        $nameKey = $displayName.Trim().ToLowerInvariant()

        if ($names.ContainsKey($nameKey)) {
          throw "Requirement rule ${index}: duplicate script rule name."
        }
        $names[$nameKey] = $true

        $account = Read-RequirementText -Name runasaccount
        if (-not $account) { $account = "system" }
        if ($account -cnotin @("system", "user")) {
          throw "Requirement rule ${index}: invalid script account."
        }

        $scriptText = Read-RequirementText -Name script -Required

        $graphRule["@odata.type"] =
        "#microsoft.graph.win32LobAppPowerShellScriptRequirement"
        $graphRule.displayName = $displayName
        $graphRule.runAsAccount = $account
        $graphRule.runAs32Bit = Read-RequirementFlag -Name runas32bit
        $graphRule.enforceSignatureCheck =
        Read-RequirementFlag -Name enforcesignaturecheck
        $graphRule.scriptContent = [Convert]::ToBase64String(
          [Text.Encoding]::UTF8.GetBytes($scriptText)
        )
      }
    }

    $graphRule
  }
}