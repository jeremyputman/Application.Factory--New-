# Remove-AFToken

Delete one of the current user's API token records.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Remove-AFToken -prefix <string> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-prefix` | `string` | Yes | Not specified | Prefix identifying one API token owned by the current authenticated user; not the whole secret token. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Find the intended token prefix

```powershell
Get-AFTokenList | Select-Object name, prefix, expires_at
```

## Example 2: Delete the selected token

```powershell
Remove-AFToken -prefix '<token-prefix>'
```

## Behavior and limits

Deleting the token currently used for authentication makes later requests fail. This is immediate deletion, without SupportsShouldProcess.

## Output

Usually no API body.

## Source

[cmdlets/Public/api/tokens/Remove-AFToken.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/Remove-AFToken.ps1)

