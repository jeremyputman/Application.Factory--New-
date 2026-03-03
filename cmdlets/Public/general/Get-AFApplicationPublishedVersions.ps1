function Get-AFApplicationPublishedVersions {
  [cmdletbinding()]
  param(
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  if ($script:application_packages) {
    return
  }
  $script:application_packages = @{}
  $storage_credential = Get-Secret -Vault $configuration.keyvault_name -Name $configuration.storage.packages -AsPlainText
  $storageAccountContext = New-AzStorageContext -StorageAccountName $configuration.storage.packages -StorageAccountKey $storage_credential
  # Get Public Container Blobs
  $intune_win_files = (Get-AzStorageBlob -Container public -Context $storageAccountContext | Select-Object -Property Name | Where-Object { $_ -match "intunewin" }).Name
  if ($configuration.application_key -eq "guid") {
    $regex_match = '^(?<app>[0-9a-fA-F-]{36})/(?<Version>[^/]+)/'
  } 
  else{
    $regex_match = '^(?![0-9a-fA-F-]{36}/)(?<app>[^/]+)/(?<Version>[^/]+)/'
  }
  $script:application_packages.public = $intune_win_files | ForEach-Object {
    if ($_ -match $regex_match) {
      [PSCustomObject]@{
        app    = $matches.app
        Version = $matches.Version
      }
    }  
  }
  $client_list = Get-AFClient
  foreach($client in $client_list) {
    if ($configuration.client_key -eq "guid") {
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