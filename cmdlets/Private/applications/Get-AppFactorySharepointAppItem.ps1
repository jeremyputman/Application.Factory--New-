<#
.SYNOPSIS
    Gets the latest application item from SharePoint.
.DESCRIPTION
    Connects to SharePoint using a certificate and retrieves the most recent application version and URI for the specified application object.
.OUTPUTS
    PSCustomObject with Version and URI properties.
.EXAMPLE
    Get-AppFactorySharepointAppItem -application $appObj
#>
function Get-AppFactorySharepointAppItem{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose" 
  )
  # Prepare SharePoint connection configuration
  $pfxPath = Join-Path -Path $script:Workspace -ChildPath $script:sharepoint_certificateFile
  $sharepointConfig = @{
    "url"                 = "$($script:sharepointurl)/sites/$($script:sharepointsite)"
    "CertificatePath"     = $pfxPath
    "CertificatePassword" = (Get-Secret -Vault $script:keyvault_name -Name $script:sharepoint_certificateSecret).Password
    "ClientId"            = $script:sharepoint_clientId
    "Tenant"              = $script:sharepoint_tenant
  }  
  # Attempt to connect and retrieve the latest application item from SharePoint
  try { 
    Connect-PnPOnline @sharepointConfig 
    $listItems = Get-PnPListItem -List $script:sharepoint_documentLibrary -PageSize 1000 | Where-Object {$_["FileDirRef"] -like "*$($application.SourceFiles.StorageAccountContainerName)"}
    $listItems = $listItems | Select-Object -Property @(@{name="FileLeafRef"; expr={$_["FileLeafRef"]}},@{name="FileRef"; expr={$_["FileRef"]}},@{name="FileDirRef"; expr={$_["FileDirRef"]}},@{name="Modified"; expr={$_["Modified"]}}) | Sort-Object -Property Modified -Descending
  }
  catch {
    throw $_
  }
  # Build and return the result object
  $PSObject = [PSCustomObject]@{
    "Version" = $listItems[0].FileLeafRef
    "URI" = $listItems[0].FileRef
  }
  return $PSObject 
}