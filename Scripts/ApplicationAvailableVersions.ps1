Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force

$API_KEY = "### API KEY ###"
$BASE_API = "### APP FACTORY URI ###"

# Admin
Set-AFSettings -api_key $API_KEY -uri $BASE_API
# Credential for Azure Storage Calls
$storage_credential = Get-Secret -Vault DEVPSU02 -Name "applicationfactoryv2" -AsPlainText
$storage_container = "applicationfactoryv2"
$storageAccountContext = New-AzStorageContext -StorageAccountName $storage_container -StorageAccountKey $storage_credential
# Public Intune Win Files
$intune_win_files = (Get-AzStorageBlob -Container public -Context $storageAccountContext | Select-Object -Property Name | Where-Object {$_ -match "intunewin"}).Name
# Client Intune Win Files
$client_list = Get-AFClient
foreach($client in $client_list) {
    $intune_win_files += (Get-AzStorageBlob -Container $client.id -Context $storageAccountContext | Select-Object -Property Name | Where-Object {$_ -match "intunewin"}).Name
}
$apps = $intune_win_files | ForEach-Object {
    if ($_ -match '^(?<Guid>[0-9a-fA-F-]{36})/(?<Version>[^/]+)/') {
        [PSCustomObject]@{
            GUID    = $matches.Guid
            Version = $matches.Version
        }
    }
}
foreach($app in $apps){
  Add-AFApplicationVersion -id $app.GUID -versions $app.Version
}