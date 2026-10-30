function Publish-AFApplicationClientApp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]$configuration,
    [switch]$UseNativeUpload = $true,
    [ValidateSet("Auto", "Native", "AzCopy")]
    [string]$UploadTransport = "Auto",
    [string]$AzCopyPath,
    [string]$ExistingAppId,
    [string]$ExpectedDisplayVersion,
    [string]$ExpectedContentVersion
  )

  if (-not $UseNativeUpload) {
    throw "The legacy IntuneWin32App publishing route has been retired."
  }

  Publish-AFApplicationClientAppNative `
    -Configuration $configuration `
    -UploadTransport $UploadTransport `
    -AzCopyPath $AzCopyPath `
    -ExistingAppId $ExistingAppId `
    -ExpectedDisplayVersion $ExpectedDisplayVersion `
    -ExpectedContentVersion $ExpectedContentVersion |
  Out-Null
}
