<#
.SYNOPSIS
    Downloads and extracts a specific ECNO application file from SharePoint.
.DESCRIPTION
    Connects to SharePoint, downloads the specified application file, and extracts it to the destination folder using 7-Zip.
.OUTPUTS
    None (performs file operations).
.EXAMPLE
    Get-AppFactoryECNOFile -application $appObj -version $verObj -destination 'C:\Temp'
#>
function Get-AppFactoryECNOFile{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$version,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$destination
  )
  # # The PFX used to connect to the Sharepoint Configured
  $pfxPath = Join-Path -Path $script:Workspace -ChildPath $script:sharepoint_certificateFile
  $sharepointConfig = @{
    "url"                 = "$($script:sharepointurl)/sites/$($script:sharepointsite)"
    "CertificatePath"     = $pfxPath
    "CertificatePassword" = (Get-Secret -Vault $script:keyvault_name -Name $script:sharepoint_certificateSecret).Password
    "ClientId"            = $script:sharepoint_clientId
    "Tenant"              = $script:sharepoint_tenant
  }  

  # Attempt to connect and download the specified ECNO file
  try { Connect-PnPOnline @sharepointConfig }
  catch {
    throw $_
  }
  # Find and download the file from SharePoint
  $listItems = Get-PnPListItem -List $script:sharepoint_documentLibrary -PageSize 1000 | Where-Object {$_["FileDirRef"] -like "*$($application.SourceFiles.StorageAccountContainerName)"}
  if(-not $listitems){
    throw "[$($application.information.Name)] Failed to find file in SharePoint document library '$($script:sharepoint_documentLibrary)' with name '$($version.version)'"
  }
  $item = $listItems | Select-Object -Property @(@{name="FileLeafRef"; expr={$_["FileLeafRef"]}},@{name="FileRef"; expr={$_["FileRef"]}}) -First 1
  Get-PnPFile -Url $item.FileRef -Path $destination -FileName $item.FileLeafRef -AsFile -Force
  # Extract the downloaded file using 7-Zip
  $7ZipPath = Join-Path -Path $PSScriptRoot -ChildPath "SupportFiles"  -AdditionalChildPath "7zr.exe"
  $7ZipFile = Join-Path -Path $destination -ChildPath $item.FileLeafRef
  $vars = @{
    "FilePath" = $7zipPath
    "ArgumentList" = "x `"$($7ZipFile)`" -aoa -o`"$($destination)`""
    "Wait" = $true
  }
  Start-Process @vars  
  Remove-Item -Path $7ZipFile -Force
}