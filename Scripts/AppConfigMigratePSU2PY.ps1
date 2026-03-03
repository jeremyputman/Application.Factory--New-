Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force

$API_KEY = "### API KEY ###"
$BASE_API = "### APP FACTORY URI ###"

# Admin
Set-AFSettings -api_key $API_KEY -uri $BASE_API

# Get the list of clients
$dataPath = "C:\Support\test\Application-Factory-Applications"
$clients_path = Join-Path -Path $dataPath -ChildPath "ClientConfigurations"
$clients = Get-ChildItem -Path $clients_path
foreach($client in $clients){
  $client_id = $client.BaseName
  $applications = Get-ChildItem -Path $client.FullName -Filter "*.json"

  foreach($application in $applications){
    $application_id = $application.BaseName

    $application_data = Get-Content -Path $application.FullName -Raw |
      ConvertFrom-Json -AsHashtable

    # add/overwrite safely
    $application_data['espprofiles'] = $application_data['espprofiles'] -join ","
    $application_data['client']      = $client_id
    $application_data['application'] = $application_id

    
    New-AFAppConfig @application_data 
  }
}