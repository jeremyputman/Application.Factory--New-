<#
.SYNOPSIS
    Retrieves published application versions from storage containers.
.DESCRIPTION
    Queries public and client-specific storage containers for Intune application packages, parses their names, and stores published version information in a script-scoped variable.
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Populates $script:application_packages with published version data.
.EXAMPLE
    Get-AFApplicationPublishedVersions
#>
function Get-AFApplicationPublishedVersions {
  [cmdletbinding()]
  param(
  )
  # Return if published versions are already loaded
  if ($script:application_packages) {
    return
  }
  # Initialize published versions dictionary
  $script:application_packages = @{}
  # Get storage credentials and context
  $storage_credential = Get-Secret -Vault $script:keyvault_name -Name $script:storage_packages -AsPlainText
  $storageAccountContext = New-AzStorageContext -StorageAccountName $script:storage_packages -StorageAccountKey $storage_credential
  # Get public container blobs for Intune packages
  $intune_win_files = (Get-AzStorageBlob -Container public -Context $storageAccountContext | Select-Object -Property Name | Where-Object { $_ -match "intunewin" }).Name
  # Determine regex for app/version extraction
  if ($script:application_key -eq "guid") {
    $regex_match = '^(?<app>[0-9a-fA-F-]{36})/(?<Version>[^/]+)/'
  }
  else{
    $regex_match = '^(?![0-9a-fA-F-]{36}/)(?<app>[^/]+)/(?<Version>[^/]+)/'
  }
  # Parse public container files for app/version
  $script:application_packages.public = $intune_win_files | ForEach-Object {
    if ($_ -match $regex_match) {
      [PSCustomObject]@{
        app    = $matches.app
        Version = $matches.Version
      }
    }
  }
  # Get client list and parse client-specific containers
  $client_list = Get-AFClient
  foreach($client in $client_list) {
    if ($script:client_key -eq "guid") {
      $client_id = $client.id
    }
    else{
      $client_id = $client.slug
    }
    $intune_win_files = (Get-AzStorageBlob -Container $client_id -Context $storageAccountContext | Select-Object -Property Name | Where-Object { $_ -match "intunewin" }).Name
    $script:application_packages.$($client_id) = $intune_win_files | ForEach-Object {
      if ($_ -match $regex_match) {
        [PSCustomObject]@{
          app    = $matches.app
          Version = $matches.Version
        }
      }
    }
  }
}