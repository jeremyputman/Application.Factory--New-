<#
.SYNOPSIS
    Downloads files for a specific application version from Azure Storage.
.DESCRIPTION
    Retrieves all files matching the specified version from an Azure Storage container and saves them to the destination path.
.OUTPUTS
    None (performs file operations).
.EXAMPLE
    Get-AppFactoryAzureStorageFile -application $appObj -version $verObj -destination 'C:\Temp'
#>
function Get-AppFactoryAzureStorageFile{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$version,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$destination,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose" 
  )
  try{
    # Get credentials and create storage context
    $storage_credential = Get-Secret -Vault $script:keyvault_name -Name $script:storage_installers -AsPlainText
    $storageAccountContext = New-AzStorageContext -StorageAccountName $script:storage_installers -StorageAccountKey $storage_credential        
    # Iterate over matching blobs and download each file
    $StorageBlobContents = Get-AzStorageBlob -Container $application.SourceFiles.StorageAccountContainerName -Context $storageAccountContext -ErrorAction Stop | Where-Object {$_.Name -like "$($version.version)*"}
    foreach($blob in $StorageBlobContents){
      # Determine directory path for file
      $file = $blob.Name -split "/"
      if($file.length -gt 2){
        $directoryPath = Join-path -Path $destination -ChildPath (($file[1..($file.length -2)]) -join "/")
        New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
      }
      else{
        $directoryPath = $destination
      }
      # Prepare parameters and download blob content
      $params = @{
        Context = $storageAccountContext
        Container = $application.SourceFiles.StorageAccountContainerName
        Blob = $blob.Name
        Destination = (Join-Path -Path $directoryPath -ChildPath $file[-1])
        Force = $true
      }
      Get-AzStorageBlobContent @params | Out-Null  
    }
  }
  catch {
    # Throw error if download fails
    throw "[$($application.Information.DisplayName)] Failed to download file from Azure Storage with error message: $($_.Exception.Message)"
  }  
}