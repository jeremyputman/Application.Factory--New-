function Publish-AFApplicationClientApp {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][PSCustomObject]$configuration,
    # Retained for compatibility with existing native-upload scripts.
    [switch]$UseNativeUpload = $true,
    [ValidateSet("Auto", "Native", "AzCopy")][string]$UploadTransport = "Auto",
    [string]$AzCopyPath
  )

  if (-not $UseNativeUpload) {
    throw (
      "The legacy IntuneWin32App publishing route has been retired. " +
      "Omit UseNativeUpload or specify -UseNativeUpload."
    )
  }

  Publish-AFApplicationClientAppNative `
    -Configuration $configuration `
    -UploadTransport $UploadTransport `
    -AzCopyPath $AzCopyPath |
  Out-Null
}