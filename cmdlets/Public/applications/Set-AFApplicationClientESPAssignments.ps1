function Set-AFApplicationClientESPAssignments {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$configuration,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )
  $graph_header = @{
    "content-type"  = "application/json"
    "Authorization" = "Bearer $($global:AccessToken.access_token)"
  }  
  $assignments = $configuration.esp_assignments -split ","
  foreach ($assignment in $assignments) {
    $uri = "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations?`$filter=displayName eq '$($assignment)'"
    $esp = (Invoke-RestMethod -Method Get -Uri $uri -Headers $graph_header -StatusCodeVariable statusCode).value
    if ($esp) {
      $current = @()
      if ($esp.selectedMobileAppIds) {
        $current = @($esp.selectedMobileAppIds)
        $new = @($current + $script:published_application.id | Select-Object -Unique)
        $body = @{
          "@odata.type"              = "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
          "showInstallationProgress" = $true
          "selectedMobileAppIds"     = $new
        } | ConvertTo-Json -Depth 5
        Invoke-RestMethod -Method Patch -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations/$($esp.id)" -Headers $graph_header -Body $body | Out-Null
      }      
    }

  }
  

}