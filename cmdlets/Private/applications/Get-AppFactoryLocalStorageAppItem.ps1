<#
.SYNOPSIS
    Gets the latest application item from local storage.
.DESCRIPTION
    Retrieves the most recent application version and URI from a local storage path for the specified application object.
.OUTPUTS
    PSCustomObject with Version and URI properties.
.EXAMPLE
    Get-AppFactoryLocalStorageAppItem -application $appObj
#>
function Get-AppFactoryLocalStorageAppItem {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application
  )
  # Build the local application path and get the latest item
  $localAppPath = Join-Path -Path $script:LocalStorage -ChildPath $application.SourceFiles.StorageAccountContainerName
  $localAppList = Get-ChildItem -Path $localAppPath | Sort-Object LastWriteTime -Descending
  # Return the top item as a custom object
  $PSObject = [PSCustomObject]@{
    "Version" = $localAppList[0].Name
    "URI"     = $localAppList[0].FullName
  }
  return $PSObject    
}