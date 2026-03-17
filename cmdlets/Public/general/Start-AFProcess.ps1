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
    [Parameter()][switch]$Force,
    [Parameter()][switch]$TestMode
  )
  # Set Application Factory API settings
  $params = @{
    configFile    = $configFile
    EnableLogging = $EnableLogging.IsPresent
    Workspace     = $workspace
  }
  Set-AFSettings @params
  # Get current list of applications
  $params = @{}
  if ($application_id) {
    $params.id = $application_id
  }
  $application_list = Get-AFApplications @params
  # Check for new versions and create packages if needed
  $current_progress_preference = $ProgressPreference
  $ProgressPreference = "SilentlyContinue"
  try {
    Write-PSFMessage -Message "There are <c='green'>$($application_list.count)</c> applications configured in AppFactory"  -Level  "Output" -Tag "Process" -Target "Application Factory Service"
    foreach ($application in ($application_list | Where-Object { -not $_.sourcefiles.pauseupdate })) {
      Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Starting Process"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
      try {
        $need_package = Test-AFApplicationVersion -Application $application -Force:$force.IsPresent -LogLevel "Output"
        if (-not $need_package) {
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Nothing to do"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
          continue
        }
        if ($Force.IsPresent) {
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Force flag is set - Forcing package creation"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        }
        else{
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: New Version Detected - Creating Package"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        }
        Test-AFApplicationFiles -Application $application -LogLevel "Output"
        Get-AFApplicationInstaller -Application $application -CurrentVersion $need_package -LogLevel "Output"
        Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Downloaded Installer"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        New-AFApplicationPackage -Application $application -CurrentVersion $need_package -LogLevel "Output"
        Set-AFApplicationInstall -Application $application -LogLevel "Output"
        Set-AFApplicationUninstall -Application $application -LogLevel "Output"
        Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Created Installer Script"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        New-AFIntuneFile -Application $application -LogLevel "Output"
        Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Created Intune File"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        Publish-AFApplication -Application $application -CurrentVersion $need_package -TestMode:$TestMode.IsPresent -LogLevel "Output"
        if (-not $TestMode.IsPresent) {        
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Published Package"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        }
        else {
          Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Test Mode is enabled - Skipping Publish"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        }
      }
      catch {
        Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: $($_.Exception.Message)" -Level "Error" -Tag "Process", $application.information.Name -Target "Application Factory Service"
        continue
      }
      Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process", $application.information.Name -Target "Application Factory Service"
    }
  }
  catch {
    Write-PSFMessage -Message $_.Exception.Message -Level "Error" -Tag "Process" -Target "Application Factory Service"
    $_
  }
  finally {
    $ProgressPreference = $current_progress_preference
  }
}