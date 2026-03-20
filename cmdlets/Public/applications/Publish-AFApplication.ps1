<#
.SYNOPSIS
    Publishes an application package and uploads related files to storage containers.
.DESCRIPTION
    Handles uploading application files (Intune package, icon, detection script) to one or more storage containers, updates application version, and manages ECNO-specific metadata. Cleans up local folders after publishing.
.PARAMETER Application
    The application object containing metadata and source information. (Mandatory)
.PARAMETER CurrentVersion
    The version object containing URI and file details. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Publishes files to storage and updates application version.
.EXAMPLE
    Publish-AFApplication -Application $app -CurrentVersion $ver
#>
function Publish-AFApplication {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][switch]$TestMode     
  )  
  # Determine storage containers for upload
  $containerUploads = [System.Collections.Generic.List[PSCustomObject]]@()
  if ($application.sourcefiles.publishto.count -eq 0) {
    $containerUploads.Add($script:storage_container_public) | Out-Null
  }
  else{
    $client_list = Get-AFClient
    foreach($client in $application.sourcefiles.publishto) {
      if ($script:client_key -eq "guid") {
        $org = $client.id
      }
      else{
        $org = ($client_list | Where-Object { $_.id -eq $client.Id } | Select-Object -Property slug).slug
      }
      $containerUploads.Add($org) | Out-Null
    }
  }
  # Define paths for publish and setup folders
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $application.slug
  if($application.detectionrule.type -eq "msi"){
    $MSIPath = Join-Path -Path $AppPublishFolderPath -ChildPath "Files" -AdditionalChildPath $application.sourcefiles.AppSetupFileName
    $product_code = (Get-MSIMetaData -path $MSIPath -Property "ProductCode")[3].trim()
    $product_version = (Get-MSIMetaData -path $MSIPath -Property "ProductVersion")[3].trim()
    $application.detectionrule.valuename = $($product_code)
    $application.detectionrule.value = $product_version
  }
  elseif($application.detectionrule.type -eq "registry_version"){
    $application.detectionrule.value = $CurrentVersion.version
    $application.detectionrule.valuename = "DisplayVersion"
    if(-not $application.detectionrule.keypath){
      $MSIPath = Join-Path -Path $AppPublishFolderPath -ChildPath "Files" -AdditionalChildPath $application.sourcefiles.AppSetupFileName
      $product_code = (Get-MSIMetaData -path $MSIPath -Property "ProductCode")[3].trim()
      $application.detectionrule.keypath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($product_code)"
    }
  }
  elseif($application.detectionrule.type -eq "registry_existence"){
    if(-not $application.detectionrule.keypath){
      $MSIPath = Join-Path -Path $AppPublishFolderPath -ChildPath "Files" -AdditionalChildPath $application.sourcefiles.AppSetupFileName
      $product_code = (Get-MSIMetaData -path $MSIPath -Property "ProductCode")[3].trim()
      $application.detectionrule.keypath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($product_code)"
    }    
  }
  # Prepare file paths for upload
  $ScriptDataFile = Join-Path -Path $AppPublishFolderPath -ChildPath "detection.ps1"
  $AppJSONPath = Join-Path -Path $AppPublishFolderPath -ChildPath "App.json"
  $AppIconFile = Join-Path -Path $AppPublishFolderPath -ChildPath "icon.png"
  $IntunePackage = Join-Path -Path $AppPublishFolderPath -ChildPath "$($application.Information.Name).intunewin"
  # Determine application path for blob storage
  if ($script:application_key -eq "guid") {
    $application_path = $Application.id
  }
  else {
    $application_path = $Application.slug
  }
  # Prepare upload objects for each file
  $appUploads = [PSCustomObject]@(
    @{
      "File" = $IntunePackage
      "Blob" = "$($application_path)/$($CurrentVersion.version)/$($application.Information.Name).intunewin"
    },
    @{
      "File" = $AppJSONPath
      "Blob" = "$($application_path)/$($CurrentVersion.version)/App.json"
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
  $app_data = $application.PSObject.Copy()
  $app_data.detectionrule.psobject.properties.remove("scriptfile")
  $app_data.psobject.properties.remove("id")
  $app_data.psobject.properties.remove("slug")
  $app_data.psobject.properties.remove("iconUrl")
  $app_data.psobject.properties.remove("sourcefiles")
  $app_data.psobject.properties.remove("install")    
  $app_data.psobject.properties.remove("uninstall")
  $app_data | ConvertTo-Json -Depth 10 | Out-File -FilePath $AppJSONPath -Encoding UTF8
  if($TestMode.IsPresent){
    return
  }
  # Get storage credentials and context
  $storage_credential = Get-Secret -Vault $script:keyvault_name -Name $script:storage_packages -AsPlainText
  $storageAccountContext = New-AzStorageContext -StorageAccountName $script:storage_packages -StorageAccountKey $storage_credential
  # Upload files to each container
  foreach ($container in $containerUploads) {
    if ($script:enable_logging) {
      Write-AFLogEntry -Message "[<c='green'>$($application.Information.Name)</c>] Uploading files to storage" -Tag "Application", "$($application.Information.Name)"
    }
    foreach ($upload in $appUploads) {
      try {
        Set-AzStorageBlobContent @upload -Container $container -Context $storageAccountContext -Force -ErrorAction Stop | Out-Null
        if ($script:enable_logging) {
          Write-AFLogEntry -Message "[<c='green'>$($application.Information.Name)</c>] Uploaded <c='green'>$($upload.File)</c> to $($container) container" -Tag "Application", "$($application.Information.Name)"
        }
      }
      catch {
        throw "[$($application.Information.Name)] Unable able to upload file: $($_.Exception.Message)"
      }
    }
    # Update application version after upload
    Add-AFApplicationVersion -id $application.id -versions $CurrentVersion.version | Out-Null
  }
  # Handle ECNO-specific metadata and update
  $params = @{}
  if($Application.SourceFiles.AppSource -eq "ecno"){
    $configFile = Join-Path -Path $AppSetupFolderPath -ChildPath "_win32app.txt"
    $scriptFile = Join-Path -Path $AppSetupFolderPath -ChildPath "_detect.ps1"
    $file = Get-Content -Path $configFile
    $publisherName = $file[45].trim()
    $informationURL = $file[53].trim()
    $privacyURL = $file[55].trim()
    $Description = $file[43].trim()
    $Notes = $file[61].trim()
    $MinimumMemoryInMB = ($file[89].trim() -ne ".") ? $file[89].trim() : 0
    $MinimumFreeDiskSpaceInMB = ($file[87].trim() -ne ".") ? $file[87].trim() : 0
    $MinimumSupportedWindowsRelease = $file[85].trim()
    $architecture = $file[83].trim().trim()
    $params = @{
      publisher = $publisherName
      description = $Description
      notes = $Notes
      information_url = $informationURL
      privacy_url = $privacyURL
      minimummemoryinmb = $MinimumMemoryInMB
      minimumfreediskspaceinmb = $MinimumFreeDiskSpaceInMB
      minimumsupportedwindowsrelease = $MinimumSupportedWindowsRelease
      detection_scriptfile = (Get-Content -Path $scriptFile -Raw)
      architecture = $architecture
    }
  }
  Set-AFApplication -id $application.id -lastupdate (Get-Date) @params | Out-Null
  # Clean up local publish and setup folders
  Remove-Item -Path $AppPublishFolderPath -Recurse -Force | Out-Null
  Remove-Item -Path $AppSetupFolderPath -Recurse -Force | Out-Null
}
