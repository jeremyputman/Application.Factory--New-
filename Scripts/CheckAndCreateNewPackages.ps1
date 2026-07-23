Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force
# Load configuration data
#$config_file_path = "C:\DevOps\Application.Factory\Workspace\EID-Appfactory.json"
$config_file_path = "C:\DevOps\Application.Factory\Workspace\AppFactoryConfig.json"
$workspace_path = "C:\DevOps\Application.Factory"
#Update-Evergreen -Force *> $null

$application = "7-Zip"
Start-AFProcess -configFile $config_file_path -workspace $workspace_path -EnableLogging -LogLevel "Output" #-application $application -Force #-TestMode 
# Start-AFProcess -configFile $config_file_path -workspace $workspace_path -EnableLogging -LogLevel "Output" #-TestMode #-Force