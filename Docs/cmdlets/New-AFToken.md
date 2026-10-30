# New-AFToken

Create a new API token for the authenticated user.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFToken -name <string> -expires_at <datetime> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-name` | `string` | Yes | Not specified | The name of the token. (Mandatory) |
| `-expires_at` | `datetime` | Yes | Not specified | Expiry date/time for a new API token; serialized with timezone/date formatting by the wrapper. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Create a 30-day token

```powershell
$newToken = New-AFToken -name 'Pilot publishing' -expires_at (Get-Date).AddDays(30)
# Store $newToken.token in your approved secret vault without logging it.
```

## Example 2: Review metadata without displaying the raw token

```powershell
$newToken | Select-Object name, prefix, expires_at
```

## Behavior and limits

Requires an existing API-authenticated session/settings to create another token. Use Settings in the web interface to bootstrap the first credential. Store the raw token securely at creation.

## Output

Creation response containing token once, plus prefix and metadata.

## Source

[cmdlets/Public/api/tokens/New-AFToken.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/New-AFToken.ps1)

