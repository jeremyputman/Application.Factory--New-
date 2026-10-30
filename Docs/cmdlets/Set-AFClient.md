# Set-AFClient

Update a client's assigned AppFactory access groups.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFClient -id <string> [-assigned_groups <string[]>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory client UUID or supported name/slug lookup. Aliases: "name". |
| `-assigned_groups` | `string[]` | No | Not specified | Existing Django/AppFactory access group names or IDs. Replaces client access selection on update; not Intune assignment targets. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Replace the client access-group selection

```powershell
Set-AFClient -id '<client-uuid>' `
  -assigned_groups @('AppFactory Pilot Operators', 'AppFactory Packaging Operators')
```

## Example 2: Review access group selection

```powershell
Get-AFClient -id '<client-uuid>' | Select-Object id, assigned_groups
```

## Behavior and limits

The name alias applies to the lookup id; this command has no rename parameter. assigned_groups replaces the selected relation. It uses ValidateNotNullOrEmpty, so do not assume @() is accepted to clear the list; use the web/API contract for clearing.

## Output

Updated client object.

## Source

[cmdlets/Public/api/clients/Set-AFClient.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/Set-AFClient.ps1)

