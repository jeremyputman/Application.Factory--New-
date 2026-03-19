<#
.SYNOPSIS
    Gets the latest application item from Azure Storage.
.DESCRIPTION
    Retrieves the most recent application version and URI from an Azure Storage container for the specified application object.
.OUTPUTS
    PSCustomObject with Version and URI properties.
.EXAMPLE
    Get-AppFactoryAzureStorageAppItem -application $appObj
#>
function Get-AppFactoryAzureStorageAppItem {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application
  )
  try {
    # Get credentials and create storage context
    $storage_credential = Get-Secret -Vault $script:keyvault_name -Name $script:storage_installers -AsPlainText
    $storageAccountContext = New-AzStorageContext -StorageAccountName $script:storage_installers -StorageAccountKey $storage_credential    
    # Get and sort blob contents
    $StorageBlobContents = Get-AzStorageBlob -Container $application.SourceFiles.StorageAccountContainerName -Context $storageAccountContext -ErrorAction Stop | Where-Object {$_.Name -ne "latest.json"} | Sort-Object LastModified -Descending
    # Parse the top item and return as object
    $fileInfo = $StorageBlobContents[0].Name -split "/"
    # Only return the top item
    $PSObject = [PSCustomObject]@{
      "Version" = $fileInfo[0]
      "URI" = $fileInfo[0]
    }
    return $PSObject    
  }
  catch {
    # Log error and rethrow
    Write-AFLogEntry -Message "[<c='green'>$($application.Information.DisplayName)</c>] Error Occured: $($_)" -Level "Error" -Tag "Application", "$($application.Information.DisplayName)"
    throw $_
  }  
}