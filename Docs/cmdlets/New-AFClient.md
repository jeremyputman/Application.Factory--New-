# New-AFClient

Create an AppFactory client and its package-storage container.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFClient -name <string> [-id <string>] [-assigned_groups <string[]>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-name` | `string` | Yes | Not specified | The name of the client. (Mandatory) |
| `-id` | `string` | No | Not specified | AppFactory client UUID or supported name/slug lookup. |
| `-assigned_groups` | `string[]` | No | Not specified | Existing Django/AppFactory access group names or IDs. Replaces client access selection on update; not Intune assignment targets. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Create a client with existing access groups

```powershell
New-AFClient -name 'Pilot Client' -assigned_groups @('AppFactory Pilot Operators')
```

## Example 2: Inspect the new record

```powershell
Get-AFClient -id 'pilot-client'
```

## Behavior and limits

Requires admin-group access and the webapp's managed-identity storage permissions. Assigned group names must already exist in Django and are not Intune app assignment groups. Container creation is an external side effect; inspect database and storage after partial failure.

## Output

New client object.

## Source

[cmdlets/Public/api/clients/New-AFClient.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/New-AFClient.ps1)

