function New-AFApplicationClientDetection {
  [CmdletBinding()]
  [OutputType([System.Collections.Generic.List[PSCustomObject]])]
  param(  
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ApplicationFolder,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  $rules = [System.Collections.Generic.List[PSCustomObject]]@() 
  $DetectionRules = $script:application_data.DetectionRule
  foreach ($DetectionRuleItem in $DetectionRules) {
    switch ($DetectionRuleItem.Type) {
      "msi" {
        $DetectionRule = [ordered]@{
          "@odata.type"            = "#microsoft.graph.win32LobAppProductCodeDetection"
          "productCode"            = $DetectionRuleItem.valuename
          "productVersionOperator" = $DetectionRuleItem.productversionoperator
          "productVersion"         = $DetectionRuleItem.value
        } 
      }
      "script" {
        $ScriptContent = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Content -Path (Join-Path -Path $ApplicationFolder -ChildPath "detection.ps1") -Raw -Encoding UTF8)))
        $DetectionRule = [ordered]@{
          "@odata.type"           = "#microsoft.graph.win32LobAppPowerShellScriptDetection"
          "enforceSignatureCheck" = [System.Convert]::ToBoolean($DetectionRuleItem.enforcesignaturecheck)
          "runAs32Bit"            = [System.Convert]::ToBoolean($DetectionRuleItem.runas32bit)
          "scriptContent"         = $ScriptContent
        }        
      }
      "registry_version" {
        $DetectionRule = [ordered]@{
          "@odata.type"          = "#microsoft.graph.win32LobAppRegistryDetection"
          "operator"             = $DetectionRuleItem.operator
          "detectionValue"       = $DetectionRuleItem.Value
          "check32BitOn64System" = [System.Convert]::ToBoolean($DetectionRuleItem.Check32BitOn64System)
          "keyPath"              = $DetectionRuleItem.KeyPath
          "valueName"            = $DetectionRuleItem.ValueName
          "detectionType"        = "version"
        }
      }
      "registry_existence" { 
            $DetectionRule = [ordered]@{
              "@odata.type"          = "#microsoft.graph.win32LobAppRegistryDetection"
              "operator"             = "notConfigured"
              "detectionValue"       = $null
              "check32BitOn64System" = [System.Convert]::ToBoolean($DetectionRuleItem.Check32BitOn64System)
              "keyPath"              = $DetectionRuleItem.KeyPath
              "valueName"            = $DetectionRuleItem.ValueName
              "detectionType"        = "exists"
            }
      }
    }
    # Add detection rule to list
    $rules.Add($DetectionRule) | Out-Null       
  }
  return $rules
}
