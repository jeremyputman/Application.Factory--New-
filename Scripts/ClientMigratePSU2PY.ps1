Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force

$API_KEY = "### API KEY ###"
$BASE_API = "### APP FACTORY URI ###"

# Admin
Set-AFSettings -api_key $API_KEY -uri $BASE_API

# Get the list of clients
$dataPath = "C:\Support\test\Application-Factory-Applications"
$client_path = Join-Path -Path $dataPath -ChildPath "clients"
$clients = Get-ChildItem -Path $client_path -Filter "*.json"

# Create clients
foreach($client in $clients){
  $data = Get-Content -Path $client.FullName | ConvertFrom-JSON
  $body = @{
    "id" = $data.GUID
    "name" = $data.Name
  }
  New-AFClient @body
}