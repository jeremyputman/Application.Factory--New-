# Add-AFApplicationVersion

Register a raw version against a shared catalog application.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Add-AFApplicationVersion -id <string> [-versions <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory catalog application UUID or supported name/slug lookup. |
| `-versions` | `string` | No | Not specified | One nonblank raw version string to register (required by API even if locally optional). |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Register an already uploaded package version

```powershell
Add-AFApplicationVersion -id '<application-uuid>' -versions '1.2.3'
```

## Example 2: Inspect the updated version relation

```powershell
Get-AFApplications -id '<application-uuid>' | Select-Object -ExpandProperty sourcefiles
```

## Behavior and limits

Supply a nonblank version even though the declaration does not mark it mandatory. This does not build or upload files. Publish-AFApplication registers versions automatically after upload; manual registration alone can leave catalog metadata pointing to missing assets.

## Output

API action response with changed, detail, and data.

## Source

[cmdlets/Public/api/applications/Add-AFApplicationVersion.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Add-AFApplicationVersion.ps1)

