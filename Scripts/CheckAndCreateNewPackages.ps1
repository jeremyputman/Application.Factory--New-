Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force
# Load configuration data
$config_file_path = "C:\DevOps\Application.Factory\Workspace\config.json"
$configuration = Get-Content -Raw -Path $config_file_path | ConvertFrom-Json
# Set Application Factory API settings
Set-AFSettings -api_key (Get-Secret -Vault $configuration.keyvault_name -Name $configuration.api.key -AsPlainText)  -uri $configuration.api.url -EnableLogging -LoggingPath "C:\DevOps\Application.Factory\Logs" -WorkingPath "C:\DevOps\Application.Factory\WorkingFolder"
# Get current list of applications
$application_list = Get-AFApplications
# Check for new versions of the applications and create them if they don't exist
$current_progress_preference = $ProgressPreference
$ProgressPreference = "SilentlyContinue"
try{
Write-PSFMessage -Message "There are <c='green'>$($application_list.count)</c> applications configured in AppFactory"  -Level  "Output" -Tag "Process" -Target "Application Factory Service"
foreach($application in ($application_list | Where-Object { -not $_.sourcefiles.pauseupdate})){
  Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Starting Process"  -Level  "Output" -Tag "Process",$application.information.Name -Target "Application Factory Service"
  try{
    $need_package = Test-AFApplicationVersion -Application $application -LogLevel "Output"
    if(-not $need_package){
      Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Nothing to do"  -Level  "Output" -Tag "Process",$application.information.Name -Target "Application Factory Service"
      Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process",$application.information.Name -Target "Application Factory Service"
      continue
    }
    Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: New Version Detected - Creating Package"  -Level  "Output" -Tag "Process",$application.information.Name -Target "Application Factory Service"
    Test-AFApplicationFiles -Application $application -LogLevel "Output"
    Get-AFApplicationInstaller -Application $application -CurrentVersion $need_package -LogLevel "Output"
    New-AFApplicationPackage -Application $application -CurrentVersion $need_package -LogLevel "Output"
    Set-AFApplicationInstall -Application $application -LogLevel "Output"
    Set-AFApplicationUninstall -Application $application -LogLevel "Output"
    New-AFIntuneFile -Application $application -LogLevel "Output"
    Publish-AFApplication -Application $application -CurrentVersion $need_package -LogLevel "Output"


  }
  catch{
    Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: $($_.Exception.Message)" -Level "Error" -Tag "Process",$application.information.Name -Target "Application Factory Service"
    continue
  }
  Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process",$application.information.Name -Target "Application Factory Service"
}
}
catch{
  Write-PSFMessage -Message $_.Exception.Message -Level "Error" -Tag "Process" -Target "Application Factory Service"
  $_
}
finally{
  $ProgressPreference = $current_progress_preference
}

