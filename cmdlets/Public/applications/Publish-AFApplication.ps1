function Publish-AFApplication {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )  
  # TODO: Client Speicific Publishing
  $containerUploads = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($application.sourcefiles.publishto.count -eq 0) {
    $containerUploads.Add($configuration.storage.public) | Out-Null
  }
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $application.slug
  if ($Application.DetectionRule.KeyPath -match "###PRODUCTCODE###") {
    throw "Not Implemented - Product Code Detection Rule Publishing"
    # TODO: Publish - Product Code Detection Rule
  }
  $ScriptDataFile = Join-Path -Path $AppPublishFolderPath -ChildPath "detection.ps1"
  $AppIconFile = Join-Path -Path $AppPublishFolderPath -ChildPath "icon.png"
  $IntunePackage = Join-Path -Path $AppPublishFolderPath -ChildPath "$($application.Information.Name).intunewin"
  if ($configuration.application_key -eq "guid") {
    $application_path = $Application.id
  }
  else {
    $application_path = $Application.slug
  }  
  $appUploads = [PSCustomObject]@(
    @{
      "File" = $IntunePackage
      "Blob" = "$($application_path)/$($CurrentVersion.version)/$($application.Information.Name).intunewin"
    },
    @{
      "File" = $AppIconFile
      "Blob" = "$($application_path)/$($CurrentVersion.version)/Icon.png"
    }    
  )  
  if (Test-Path -Path $ScriptDataFile) {
    $appUploads += @{
      "File" = $ScriptDataFile
      "Blob" = "$($application_path)/$($CurrentVersion.version)/Detection.ps1"
    }
  }
  $storage_credential = Get-Secret -Vault $configuration.keyvault_name -Name $configuration.storage.packages -AsPlainText
  $storageAccountContext = New-AzStorageContext -StorageAccountName $configuration.storage.packages -StorageAccountKey $storage_credential  
  foreach ($container in $containerUploads) {
    if ($script:enable_logging) {
      Write-PSFMessage -Message "[<c='green'>$($application.Information.Name)</c>] Uploading files to storage" -Level $LogLevel -Tag "Application", "$($application.Information.Name)" -Target "Application Factory Service"
    }
    foreach ($upload in $appUploads) {
      try {
        Set-AzStorageBlobContent @upload -Container $container -Context $storageAccountContext -Force -ErrorAction Stop | Out-Null
        if ($script:enable_logging) {
          Write-PSFMessage -Message "[<c='green'>$($application.Information.Name)</c>] Uploaded <c='green'>$($upload.File)</c> to <c='green'>$($container)</c> container" -Level $LogLevel -Tag "Application", "$($application.Information.Name)" -Target "Application Factory Service"
        }
      }
      catch {
        throw "[$($application.Information.Name)] Unable able to upload file: $($_.Exception.Message)"
      }       
    } 
    Add-AFApplicationVersion -id $application.id -versions $CurrentVersion.version | Out-Null
    Remove-Item -Path $AppPublishFolderPath -Recurse -Force | Out-Null
    Remove-Item -Path $AppSetupFolderPath -Recurse -Force | Out-Null
  }
}