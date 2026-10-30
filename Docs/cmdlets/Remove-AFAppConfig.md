# Remove-AFAppConfig

Delete a saved application/client configuration from AppFactory.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Remove-AFAppConfig -id <string> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory configuration UUID. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Inspect the record before removal

```powershell
Get-AFAppConfig | Where-Object id -eq '<configuration-uuid>'
```

## Example 2: Delete that configuration

```powershell
Remove-AFAppConfig -id '<configuration-uuid>'
```

## Behavior and limits

Removes desired configuration records. It is not an Intune app deletion command and does not remove tenant applications. There is no SupportsShouldProcess/-WhatIf on this wrapper.

## Output

Usually no body after successful API deletion.

## Source

[cmdlets/Public/api/appconfig/Remove-AFAppConfig.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Remove-AFAppConfig.ps1)

