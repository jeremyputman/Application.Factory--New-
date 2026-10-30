# Get-AFAppConfig

Read saved client application configurations.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFAppConfig [-id <string>] [-enabled <bool>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | No | Not specified | AppFactory configuration UUID. |
| `-enabled` | `bool` | No | Not specified | Include the configuration in enabled client publisher exports. Always bind explicitly on creation; API default true differs from wrapper's local false declaration. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: List all accessible configurations

```powershell
Get-AFAppConfig
```

## Example 2: List enabled configurations

```powershell
Get-AFAppConfig -enabled $true
```

## Example 3: Find one configuration without relying on the detail URL redirect

```powershell
Get-AFAppConfig | Where-Object id -eq '<configuration-uuid>'
```

## Behavior and limits

The detail wrapper omits the final slash required by the server route; collection filtering avoids relying on a redirect. The id is a configuration UUID, not an application ID.

## Output

Configuration objects from the CRUD API. These differ from the publisher export returned by Get-AFApplicationConfigurations.

## Source

[cmdlets/Public/api/appconfig/Get-AFAppConfig.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Get-AFAppConfig.ps1)

