# Publish-AFApplicationClientApp

Invoke the native Intune publisher using an initialized client publication context.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Publish-AFApplicationClientApp -configuration <PSCustomObject> [-UseNativeUpload] [-UploadTransport <string>] [-AzCopyPath <string>] [-ExistingAppId <string>] [-ExpectedDisplayVersion <string>] [-ExpectedContentVersion <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |
| `-UseNativeUpload` | `switch` | No | `$true` | Retired-route compatibility switch. Keep true/default; false is rejected. AzCopy is selected separately with UploadTransport. |
| `-UploadTransport` | `string` | No | `"Auto"` | Byte-transfer selection: Auto, Native, or AzCopy. Auto can choose AzCopy for encrypted payloads >=100MB when available. Accepted: "Auto", "Native", "AzCopy". |
| `-AzCopyPath` | `string` | No | Not specified | Path to azcopy.exe. When omitted, a non-Native transport can search PATH. Explicit AzCopy must find an executable. |
| `-ExistingAppId` | `string` | No | Not specified | Existing managed Intune app ID for content replacement. Requires matching expected version/content identity. |
| `-ExpectedDisplayVersion` | `string` | No | Not specified | Original displayVersion expected on the replacement target; guards against concurrent changes. |
| `-ExpectedContentVersion` | `string` | No | Not specified | Original committedContentVersion expected on the replacement target; guards against concurrent changes. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Preferred supported publication entry point

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name '<application-uuid>' -UploadTransport Auto
```

## Example 2: Internal-context invocation with native transfer

```powershell
Publish-AFApplicationClientApp -configuration $configuration -UploadTransport Native
```

## Behavior and limits

Requires downloaded App.json/package, selected module published_version, client settings, and credentials. ExistingAppId is an Intune app ID for replacement, with expected display/content versions used as concurrency guards. UseNativeUpload false is rejected. This helper alone does not apply the orchestrator's dependency/assignment/ESP/retention workflow.

## Output

No public result object; updates module-scoped publication status.

## Source

[cmdlets/Public/applications/Publish-AFApplicationClientApp.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplicationClientApp.ps1)

