Clear-Host
Import-Module -Name C:\DevOps\Application.Factory\Module\Application.Factory -Force
#$config_file_path = "C:\DevOps\Application.Factory\Workspace\EID-AppFactoryClient.json"
$config_file_path = "C:\DevOps\Application.Factory\Workspace\AppFactoryClientConfig.json"
$workspace_path = "C:\DevOps\Application.Factory"

$application = "7-Zip"
Start-AFClientProcess -configFile $config_file_path -workspace $workspace_path -application_name $application -EnableLogging -LogLevel "Output" -Force
# Start-AFClientProcess -configFile $config_file_path -workspace $workspace_path -EnableLogging -LogLevel "Output" #-TestMode