Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force
# Load configuration data
#$config_file_path = "C:\DevOps\Application.Factory\Workspace\EID-Appfactory.json"
$config_file_path = "C:\DevOps\Application.Factory\Workspace\AppFactoryConfig.json"
$workspace_path = "C:\DevOps\Application.Factory"
#Update-Evergreen -Force *> $null

$application = "Acrobat"
Start-AFProcess -configFile $config_file_path -workspace $workspace_path -application $application -EnableLogging -TestMode
