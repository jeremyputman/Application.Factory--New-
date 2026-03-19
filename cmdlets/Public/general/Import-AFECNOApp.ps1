<#
.SYNOPSIS
    Imports an ECNO application and creates a new application object from its configuration.
.DESCRIPTION
    Sets API settings, retrieves ECNO app details, downloads files, parses configuration, and creates a new application object with metadata and icon.
.PARAMETER applicationName
    The display name of the application to import. (Mandatory)
.PARAMETER publishTo
    Array of client containers to publish to.
.PARAMETER configFile
    The path to the ECNO configuration file. (Mandatory)
.PARAMETER workspace
    The workspace path for the import. (Mandatory)
.PARAMETER EnableLogging
    Enables logging if specified.
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    The new application object created from ECNO configuration.
.EXAMPLE
    Import-AFECNOApp -applicationName 'App1' -configFile 'config.txt' -workspace 'C:\Workspace'
#>
function Import-AFECNOApp {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationName,
    [Parameter()][String[]]$publishTo = @(),
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][switch]$EnableLogging
  )
  # Set Application Factory API settings
  $params = @{
    configFile    = $configFile
    EnableLogging = $EnableLogging.IsPresent
    Workspace     = $workspace
  }
  Set-AFSettings @params
  # Prepare application object for ECNO retrieval
  $application = [PSCustomObject]@{
    "Information" = [PSCustomObject]@{
      "DisplayName" = $applicationName
    }
    "SourceFiles" = [PSCustomObject]@{
      "StorageAccountContainerName" = $applicationName
    }
  }
  # Retrieve ECNO app details and download files
  $details = Get-AppFactoryECNOAppItem -application $application
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $applicationName
  # Create path if it doesn't exist
  if (-not(Test-Path -Path $AppSetupFolderPath -PathType "Container")) {
    try {
      New-Item -Path $AppSetupFolderPath -ItemType "Container" -ErrorAction "Stop" | Out-Null
    }
    catch [System.Exception] {
      throw "[$($application.Information.DisplayName)] Failed to create '$($Path)' with error message: $($_.Exception.Message)"
    }
  }
  Get-AppFactoryECNOFile -Application $Application -version $details -destination $AppSetupFolderPath
  # Read the config file to get details
  $configFile = Join-Path -Path $AppSetupFolderPath -ChildPath "_win32app.txt"
  $scriptFile = Join-Path -Path $AppSetupFolderPath -ChildPath "_detect.ps1"
  $iconFolder = Join-Path -Path $AppSetupFolderPath -ChildPath "osi"
  $icon = Get-ChildItem -Path $iconFolder -Filter "*.png" -Recurse
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
  # Prepare new application object metadata
  $new = @{
    name = $applicationName
    publisher = $publisherName
    description = $Description
    notes = $Notes
    owner = "ECNO"
    appsource = "ecno"
    storageaccountcontainername = $applicationName
    information_url = $informationURL
    privacy_url = $privacyURL
    publishto = $publishTo
    minimummemoryinmb = $MinimumMemoryInMB
    minimumfreediskspaceinmb = $MinimumFreeDiskSpaceInMB
    minimumsupportedwindowsrelease = $MinimumSupportedWindowsRelease
    install_type = "ecno"
    uninstall_type = "ecno"
    detection_type = "script"
    detection_scriptfile = (Get-Content -Path $scriptFile -Raw)
    architecture = $architecture
  }
  # Create new application and set icon
  $response = New-AFApplication @new
  Set-AFApplicationIcon -id $response.id -iconpath $icon.FullName | Out-Null
  return $response
}