# Get-AFClient

Read accessible AppFactory client records.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFClient [-id <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | No | Not specified | AppFactory client UUID or supported name/slug lookup. Aliases: "name". |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: List clients

```powershell
Get-AFClient | Select-Object id, name, slug
```

## Example 2: Read a client by slug

```powershell
Get-AFClient -id 'pilot-client'
```

## Example 3: Read by UUID

```powershell
Get-AFClient -id '<client-uuid>'
```

## Behavior and limits

Client IDs differ from destination tenant IDs and app-registration IDs. Assigned groups here control AppFactory record access.

## Output

Client object(s), including UUID, name, slug, and assigned AppFactory groups.

## Source

[cmdlets/Public/api/clients/Get-AFClient.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/Get-AFClient.ps1)

