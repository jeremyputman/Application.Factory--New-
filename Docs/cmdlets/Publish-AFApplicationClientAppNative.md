# Publish-AFApplicationClientAppNative

Upload and commit Win32 application content using native Graph/content APIs.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Publish-AFApplicationClientAppNative -Configuration <PSCustomObject> [-UploadTransport <string>] [-AzCopyPath <string>] [-UploadTimeoutSeconds <int>] [-ProcessingTimeoutSeconds <int>] [-ExistingAppId <string>] [-ExpectedDisplayVersion <string>] [-ExpectedContentVersion <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |
| `-UploadTransport` | `string` | No | `"Auto"` | Byte-transfer selection: Auto, Native, or AzCopy. Auto can choose AzCopy for encrypted payloads >=100MB when available. Accepted: "Auto", "Native", "AzCopy". |
| `-AzCopyPath` | `string` | No | Not specified | Path to azcopy.exe. When omitted, a non-Native transport can search PATH. Explicit AzCopy must find an executable. |
| `-UploadTimeoutSeconds` | `int` | No | `21600` | Overall native content upload deadline, in seconds; this low-level option is not exposed by Start-AFClientProcess. Range: 300, 86400. |
| `-ProcessingTimeoutSeconds` | `int` | No | `900` | Content processing/publishing wait timeout in seconds in the native publisher. Range: 30, 3600. |
| `-ExistingAppId` | `string` | No | Not specified | Existing managed Intune app ID for content replacement. Requires matching expected version/content identity. |
| `-ExpectedDisplayVersion` | `string` | No | Not specified | Original displayVersion expected on the replacement target; guards against concurrent changes. |
| `-ExpectedContentVersion` | `string` | No | Not specified | Original committedContentVersion expected on the replacement target; guards against concurrent changes. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Preferred high-level publication

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name '<application-uuid>' -UploadTransport Native
```

## Example 2: Adjust native upload timeouts in an initialized internal context

```powershell
Publish-AFApplicationClientAppNative -Configuration $configuration `
  -UploadTransport AzCopy -AzCopyPath 'C:\Tools\AzCopy\azcopy.exe' `
  -UploadTimeoutSeconds 43200 -ProcessingTimeoutSeconds 1800
```

## Behavior and limits

Windows/PowerShell >=7.5 required. Default upload timeout 21600 seconds and processing timeout 900 seconds. Requires module script state and downloaded artifacts; do not invent that state in an ordinary caller scope. The high-level Start command does not expose these timeout parameters. It handles content publication only; prefer Start-AFClientProcess for journal-aware end-to-end processing.

## Output

Module-scoped published_application and af_native_upload_status; status records app/content/file IDs, stage, transport, and work directory.

## Source

[cmdlets/Public/applications/Publish-AFApplicationClientAppNative.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplicationClientAppNative.ps1)

