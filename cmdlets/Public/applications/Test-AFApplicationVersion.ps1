<#
.SYNOPSIS
    Tests and retrieves the current version of an application from its source.
.DESCRIPTION
    Determines the current version of the application by querying the appropriate source type and checks published versions for the application.
.PARAMETER Application
    The application object to check. (Mandatory)
.PARAMETER force
    Forces the version check, ignoring cached or empty values.
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    The current version object or $false if not found.
.EXAMPLE
    Test-AFApplicationVersion -Application $app
#>
function Test-AFApplicationVersion {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][switch]$force
  )
  # Retrieve published versions and determine current version from source
  Get-AFApplicationPublishedVersions
  $params = @{
    "Application" = $Application
  }
  switch ($Application.SourceFiles.AppSource) {
    'azure_storage' {
      $current_version = Get-AppFactoryAzureStorageAppItem @params
    }
    'winget' {
      $current_version = Get-AppFactoryWinGetAppItem @params
    }
    'evergreen' {
      $current_version = Get-AppFactoryEvergreenAppItem @params
    }
    'sharepoint' {
      $current_version = Get-AppFactorySharepointAppItem @params
    }
    'psadt' {
      $current_version = Get-AppFactoryPSADTAppItem @params
    }
    'ecno' {
      $current_version = Get-AppFactoryECNOAppItem @params
    }
    'local_storage' {
      $current_version = Get-AppFactoryLocalStorageAppItem @params
    }
  }
  Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Latest Version Packaged <c='green'>$($current_version.version)</c>" -Tag "Process", $application.information.Name
  # Determine lookup value for published versions
  if ($script:application_key -eq "guid") {
    $lookup_value = $Application.id
  }
  else{
    $lookup_value = $Application.slug
  }
  # Check published versions for public or client-specific containers
  if($application.SourceFiles.publishTo.count -eq 0){
    $app_versions = $script:application_packages.public | Where-Object { $_.app -eq $lookup_value }
    Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Currently published versions <c='green'>$($app_versions.version -join ', ')</c> for <c='green'>public</c>" -Tag "Process", $application.information.Name
    if(-not $app_versions){
      return $current_version
    }
    elseif($current_version.version -notin $app_versions.version){
      return $current_version
    }
  }
  else{
    $client_list = Get-AFClient
    foreach($publish in $application.SourceFiles.publishTo){
      if ($script:client_key -eq "guid") {
        $org = $publish.id
      }
      else{
        $org = ($client_list | Where-Object { $_.id -eq $publish.Id } | Select-Object -Property slug).slug
      }
      $app_versions = $script:application_packages.$($org) | Where-Object { $_.app -eq $lookup_value }
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Currently published versions <c='green'>$($app_versions.version -join ', ')</c> for <c='green'>$($org)</c>" -Tag "Process", $application.information.Name
      if(-not $app_versions -and $current_version.version -notin $app_versions.version){
        return $current_version
      }
      elseif($current_version.version -notin $app_versions.version){
        return $current_version
      }      
    }
  }
  if($force.IsPresent){
    return $current_version
  }
  return $false
}