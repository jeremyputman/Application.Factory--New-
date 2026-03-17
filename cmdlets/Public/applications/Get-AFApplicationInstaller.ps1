<#
.SYNOPSIS
    Retrieves and downloads the installer for a given application version.
.DESCRIPTION
    Determines the source of the installer and downloads it to the appropriate folder, handling different source types (Azure Storage, SharePoint, ECNO, local storage, or direct download).
.PARAMETER Application
    The application object containing metadata and source information. (Mandatory)
.PARAMETER CurrentVersion
    The version object containing URI and file details. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. The installer file is downloaded to the local folder.
.EXAMPLE
    Get-AFApplicationInstaller -Application $app -CurrentVersion $ver
#>
function Get-AFApplicationInstaller{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"    
  )
  # Ensure setup folder exists for the application
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $application.slug
  if (-not(Test-Path -Path $AppSetupFolderPath -PathType "Container")) {
    try {
      New-Item -Path $AppSetupFolderPath -ItemType "Container" -ErrorAction "Stop" | Out-Null
    }
    catch [System.Exception] {
      throw "[$($application.Information.Name)] Failed to create '$($Path)' with error message: $($_.Exception.Message)"
    }
  }
  # Determine output file path for installer
  $OutFilePath = Join-Path -Path $AppSetupFolderPath -ChildPath $application.SourceFiles.AppSetupFileName
  # Log download action if logging is enabled
  if($script:enable_logging){
    Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Downloading setupfile <c='green'>$($CurrentVersion.URI)</c>" -Level $LogLevel -Tag "Application","$($application.information.Name)","Evergreen" -Target "Application Factory Service"
  }
  # Prepare parameters for file retrieval
  $params = @{
    "Application" = $Application
    "version" = $CurrentVersion
    "LogLevel" = $LogLevel
    "destination" = $AppSetupFolderPath
  }
  # Download installer based on source type
  switch ($Application.SourceFiles.AppSource) {
    'azure_storage' {
      Get-AppFactoryAzureStorageFile @params
    }
    'sharepoint' {
      Get-AppFactorySharepointFile @params 
    }
    'psadt' {}
    'ecno' {
      Get-AppFactoryECNOFile @params
    }
    'local_storage' {
      Get-ChildItem -Path $CurrentVersion.uri | foreach-object {Copy-Item $_.FullName -Destination $AppSetupFolderPath -Force -ErrorAction "Stop" -Recurse} | Out-Null
    }
    default {
      try{
        Invoke-WebRequest -Uri $CurrentVersion.URI -OutFile $OutFilePath -UseBasicParsing -ErrorAction "Stop"
      }
      catch{
        throw "[$($application.Information.Name)] Failed to download setup file from '$($CurrentVersion.URI)' with error message: $($_.Exception.Message)"
      }
    }
  }  
}