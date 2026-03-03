function Test-AFApplicationVersion{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateNotNullOrEmpty()][switch]$force,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  Get-AFApplicationPublishedVersions -LogLevel $LogLevel
  switch ($Application.SourceFiles.AppSource) {
    'azure_storage' {
      throw "Not Implemented - Azure Storage"
      # TODO: Version - Azure Storage
    }
    'winget' {
      throw "Not Implemented - Winget"
      # TODO: Version - Winget
    } 
    'evergreen' {
      $current_version = Get-AppFactoryEvergreenAppItem -application $Application -LogLevel $LogLevel
    }
    'sharepoint' {
      throw "Not Implemented - SharePoint"
      # TODO: Version - Sharepoint
    }
    'psadt' {
      throw "Not Implemented - PSADT"
      # TODO: Version - PSADT
    }
    'ecno' {
      throw "Not Implemented - ECNO"
      # TODO: Version - ECNO
    }
    'local_storage' {
      throw "Not Implemented - Local Storage"
      # TODO: Version - Local Storage
    }  
  }
  if($application.SourceFiles.publishTo.count -eq 0){
    if ($configuration.application_key -eq "guid") {
      $lookup_value = $Application.id
    }
    else{
      $lookup_value = $Application.slug
    }
    $app_versions = $script:application_packages.public | Where-Object { $_.app -eq $lookup_value } | Format-List
    if(-not $app_versions){
      return $current_version
    }
  }
  return $false
}