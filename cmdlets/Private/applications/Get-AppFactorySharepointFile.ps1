<#
.SYNOPSIS
    Downloads files for a specific application version from SharePoint.
.DESCRIPTION
    Connects to SharePoint, locates the specified application version, and downloads all related files to the destination folder.
.OUTPUTS
    None (performs file operations).
.EXAMPLE
    Get-AppFactorySharepointFile -application $appObj -version $verObj -destination 'C:\Temp'
#>
function Get-AppFactorySharepointFile{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$version,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$destination,
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
  # Attempt to connect and download files for the specified version
  try { Connect-PnPOnline @sharepointConfig }
  catch {
    throw $_
  }
  # Find and download files from SharePoint
  $listitems = Get-PnPListItem -List $script:sharepoint_documentLibrary -PageSize 1000 | Where-Object {$_["FileDirRef"] -like "*$($application.SourceFiles.StorageAccountContainerName)" -and $_["FileLeafRef"] -eq $version.version}
  if(-not $listitems){
    throw "[$($application.information.Name)] Failed to find file in SharePoint document library '$($script:sharepoint_documentLibrary)' with name '$($version.version)'"
  }
  $item = $listItems | Select-Object -Property @(@{name="FileLeafRef"; expr={$_["FileLeafRef"]}},@{name="FileRef"; expr={$_["FileRef"]}}) -First 1
  $relative_path = $item.FileRef -replace "/sites/$($script:sharepointsite)"
  $filelist = Get-PnPFolderItem -Recursive -FolderSiteRelativeUrl $relative_path
  foreach($file in $filelist){
    Get-PnPFile -Url $file.ServerRelativeUrl -Path $destination -FileName $file.Name -AsFile -Force
  }
}