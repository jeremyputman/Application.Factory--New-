<#
.SYNOPSIS
    Starts the application factory process for all configured applications.
.DESCRIPTION
    Loads configuration, retrieves applications, checks for new versions, creates packages, and publishes them. Handles logging and error reporting throughout the process.
.PARAMETER configFile
    The path to the configuration JSON file. (Mandatory)
.PARAMETER workspace
    The workspace path for environment setup. (Mandatory)
.PARAMETER EnableLogging
    Enables logging if specified.
.PARAMETER LogLevel
    Specifies the log level, default is "Verbose".
.PARAMETER Force
    Forces package creation even if no new version is detected.
.PARAMETER TestMode
    If set, skips the publishing step for testing purposes.
.OUTPUTS
    None. Processes all applications and publishes new versions as needed.
.EXAMPLE
    Start-AFProcess -configFile 'config.json' -workspace 'C:\Workspace' -EnableLogging
#>
function Start-AFProcess {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][string]$application_id,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel = "Verbose",
    [Parameter()][switch]$Force,
    [Parameter()][switch]$TestMode
  )
  # Clear the script based variable
  Remove-Variable -Scope Script -Name application_packages -ErrorAction SilentlyContinue
  # Set Application Factory API settings
  $params = @{
    configFile    = $configFile
    EnableLogging = $EnableLogging.IsPresent
    LogLevel      = $LogLevel
    Workspace     = $workspace
  }
  $script:log_target = "Application Factory Service"
  Set-AFSettings @params
  # Get current list of applications
  $params = @{}
  if ($application_id) {
    $params.id = $application_id
  }
  $application_list = Get-AFApplications @params | Where-Object { -not $_.sourcefiles.pauseupdate -and $_.sourcefiles.active }
  # Check for new versions and create packages if needed
  $current_progress_preference = $ProgressPreference
  $ProgressPreference = "SilentlyContinue"
  try {
    Write-AFLogEntry -Message "[<c='green'>Application Factory</c>] :: There are <c='green'>$($application_list.count)</c> applications configured in AppFactory" -Tag Process
    foreach ($application in $application_list) {
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Starting Process" -Tag Process, $application.information.Name
      try {
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Checking for new version" -Tag "Process", $application.information.Name
        $need_package = Test-AFApplicationVersion -Application $application -Force:$force.IsPresent
        if (-not $need_package) {
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Nothing to do" -Tag "Process", $application.information.Name
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process"  -Tag "Process", $application.information.Name
          continue
        }
        if ($Force.IsPresent) {
          Write-AFLogEntry  -Message "[<c='green'>$($application.information.Name)</c>] :: <c='yellow'>Force flag</c> is set - Forcing package creation" -Tag "Process", $application.information.Name
        }
        else{
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: New Version Detected - Creating Package" -Tag "Process", $application.information.Name
        }
        Test-AFApplicationFiles -Application $application
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Downloading Installer" -Tag "Process", $application.information.Name
        Get-AFApplicationInstaller -Application $application -CurrentVersion $need_package
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Downloaded Installer" -Tag "Process", $application.information.Name
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Creating Packaging" -Tag "Process", $application.information.Name
        New-AFApplicationPackage -Application $application -CurrentVersion $need_package
        Set-AFApplicationInstall -Application $application
        Set-AFApplicationUninstall -Application $application
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Created Packaging" -Tag "Process", $application.information.Name
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Creating Intune File" -Tag "Process", $application.information.Name
        New-AFIntuneFile -Application $application
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Created Intune File" -Tag "Process", $application.information.Name
        if (-not $TestMode.IsPresent) {        
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Publishing Package" -Tag "Process", $application.information.Name
          Publish-AFApplication -Application $application -CurrentVersion $need_package -TestMode:$TestMode.IsPresent
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Published Package" -Tag "Process", $application.information.Name
        }
        else {
          Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: <c='yellow'>Test Mode</c> is enabled - Skipping Publish" -Tag "Process", $application.information.Name
        }
      }
      catch {
        Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: $($_.Exception.Message)" -Level Error -Tag "Process", $application.information.Name
        continue
      }
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process" -Tag "Process", $application.information.Name
    }
  }
  catch {
    Write-AFLogEntry -Message "[Application Factory] :: Error Occured: $($_.Exception.Message)" -Level Error -Tag "Process", $application.information.Name
    $_
  }
  finally {
    $ProgressPreference = $current_progress_preference
    if (-not $TestMode.IsPresent) {     
      $OutFilePath = Join-Path -Path $script:working_folder -ChildPath "Installers"
      Remove-Item -Path $OutFilePath -Recurse -Force -ErrorAction "SilentlyContinue" | Out-Null
      $OutFilePath = Join-Path -Path $script:working_folder -ChildPath "Publish"
      Remove-Item -Path $OutFilePath -Recurse -Force -ErrorAction "SilentlyContinue" | Out-Null
    }
  }
}