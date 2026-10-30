# Get-AFTokenList

List API tokens owned by the authenticated user.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFTokenList  [<CommonParameters>]
```

## Parameters

No command-specific parameters. PowerShell common parameters remain available.

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: List token metadata

```powershell
Get-AFTokenList
```

## Example 2: Show expiry information

```powershell
Get-AFTokenList | Select-Object name, prefix, expires_at, revoked_at
```

## Behavior and limits

Returns the current user's tokens only. Use the prefix to revoke or delete a token.

## Output

Token metadata, including prefix and expiry/revocation; existing raw token values are not recoverable.

## Source

[cmdlets/Public/api/tokens/Get-AFTokenList.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/Get-AFTokenList.ps1)

