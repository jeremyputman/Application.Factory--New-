function Publish-AFApplicationClientApp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$configuration
  )
  # Construct table for supported operating systems
    $ArchitectureTable = @{
    "x64" = "x64"
    "x86" = "x86"
    "All" = "x64,x86"
  }
  $OperatingSystemTable = @{
    "W10_1607" = "1607"
    "W10_1703" = "1703"
    "W10_1709" = "1709"
    "W10_1803" = "1803"
    "W10_1809" = "1809"
    "W10_1903" = "1903"
    "W10_1909" = "1909"
    "W10_2004" = "2004"
    "W10_20H2" = "20H2"
    "W10_21H1" = "21H1"
    "W10_21H2" = "Windows10_21H2"
    "W10_22H2" = "Windows10_22H2"
    "W11_21H2" = "Windows11_21H2"
    "W11_22H2" = "Windows11_22H2"
    "W11_23H2" = "Windows11_23H2"
  }  

  $application = $configuration.application
  $download_folder = Join-Path -Path $script:working_folder -ChildPath "Download" -AdditionalChildPath $application.slug
  # Build Requirement Rule
  $requirement_rule = [ordered]@{
    "applicableArchitectures"        = $ArchitectureTable[$script:application_data.requirementrule.architecture]
    "minimumSupportedWindowsRelease" = $OperatingSystemTable[$script:application_data.requirementrule.minimumsupportedwindowsrelease]
    "MinimumMemoryInMB"              = $script:application_data.requirementrule.minimummemoryinmb
    "MinimumFreeDiskSpaceInMB"       = $script:application_data.requirementrule.minimumfreediskspaceinmb
  }
  # Build Detection Rules
  $detection_rule = New-AFApplicationClientDetection -application $application -ApplicationFolder $download_folder
  # Create the base 64 image file
  $Icon = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$(Join-Path -Path $download_folder -ChildPath "Icon.png")"))
  $IntuneAppPackage = Get-item -Path $(Join-Path -Path $download_folder -ChildPath "$($application.Name).intunewin")
  $Win32AppArgs = @{
    "FilePath"          = $IntuneAppPackage.FullName
    "DisplayName"       = "$($script:app_prefix)$($application.Name) $($script:published_version)"
    "AppVersion"        = $script:published_version
    "Publisher"         = $script:application_data.Information.Publisher.name
    "InstallExperience" = $script:application_data.program.installexperience
    "RestartBehavior"   = $script:application_data.program.devicerestartbehavior
    "DetectionRule"     = $detection_rule
    "RequirementRule"   = $requirement_rule
    "Notes"             = "$($script:application_data.Information.Notes)`n`AppFactoryID:$($application.id)"
    "AllowAvailableUninstall" = $script:application_data.Program.AllowAvailableUninstall
  }  
  # Dynamically add additional parameters for Win32 app
  if (-not([string]::IsNullOrEmpty($script:application_data.Information.Description))) {
    $Win32AppArgs.Add("Description", $script:application_data.Information.Description)
  }    
  else {
    $Win32AppArgs.Add("Description", $Win32AppArgs.DisplayName)
  }  
  if (Test-Path -Path (Join-Path -Path $download_folder -ChildPath "Icon.png")) {
    $Win32AppArgs.Add("Icon", $Icon)
  }  
  if (-not([string]::IsNullOrEmpty($script:application_data.Information.information_url))) {
    $Win32AppArgs.Add("InformationURL", $script:application_data.Information.information_url)
  }  
  if (-not([string]::IsNullOrEmpty($script:application_data.Information.privacy_url))) {
    $Win32AppArgs.Add("PrivacyURL", $script:application_data.Information.privacy_url)
  }   
  if (-not([string]::IsNullOrEmpty($script:application_data.Information.owner))) {
    $Win32AppArgs.Add("Owner", $script:application_data.Information.owner)
  }    
  if ($configuration.interactive_install) {
    $Win32AppArgs.Add("InstallCommandLine", "Invoke-AppDeployToolkit.exe Install -DeployMode Auto")
  }
  else {
    $Win32AppArgs.Add("InstallCommandLine", "Invoke-AppDeployToolkit.exe Install -DeployMode Silent")
  }
  if ($configuration.interactive_uninstall) {
    $Win32AppArgs.Add("UninstallCommandLine", "Invoke-AppDeployToolkit.exe Uninstall -DeployMode Auto")
  }
  else {
    $Win32AppArgs.Add("UninstallCommandLine", "Invoke-AppDeployToolkit.exe Uninstall -DeployMode Silent")
  }
  $script:published_application = Add-IntuneWin32App @Win32AppArgs -UseAzCopy -AzCopyWindowStyle Hidden -ErrorAction Stop -WarningAction Stop
  Start-Sleep -Seconds 30
  if ($script:published_application.UploadState -eq 0) {
    Remove-IntuneWin32App -id $script:published_application.id
    throw "Failed to upload files."
  }
}