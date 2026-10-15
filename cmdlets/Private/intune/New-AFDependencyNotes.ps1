function New-AFDependencyNotes {
  param([string]$Notes,[Parameter(Mandatory)]$Manifest)
  $base = ($Notes -split '\r?\n' | Where-Object {
    $_ -notmatch '^\s*AppFactory(?:Config|Client|Dependencies):'
  }) -join [Environment]::NewLine
  $json = ConvertTo-Json -InputObject $Manifest -Depth 30 -Compress
  $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json))
  return ($base.TrimEnd() + [Environment]::NewLine +
    "AppFactoryConfig:$($Manifest.configuration_id)" + [Environment]::NewLine +
    "AppFactoryClient:$($Manifest.client_id)" + [Environment]::NewLine +
    "AppFactoryDependencies:$encoded")
}

