# Get-AFApplications

Read shared application definitions visible to the API user.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFApplications [-id <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | No | Not specified | AppFactory catalog application UUID or supported name/slug lookup. Aliases: "name". |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: List definitions

```powershell
Get-AFApplications | Select-Object id, slug, information
```

## Example 2: Read by UUID

```powershell
Get-AFApplications -id '<application-uuid>'
```

## Example 3: Read by slug using the name alias

```powershell
Get-AFApplications -name 'example-app'
```

## Behavior and limits

Non-admin API output omits sourcefiles. Package creation needs an admin-group account that can read source metadata. The name alias selects an existing record; it does not rename it.

## Output

An array for list requests or an application object for a detail request.

## Source

[cmdlets/Public/api/applications/Get-AFApplications.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Get-AFApplications.ps1)

