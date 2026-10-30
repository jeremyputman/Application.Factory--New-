# Get-AFApplicationConfigurations

Read enabled client configurations in the shape consumed by the Intune publishing process.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFApplicationConfigurations -id <string> [-application_id <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory client UUID. |
| `-application_id` | `string` | No | Not specified | AppFactory catalog application UUID or application lookup, not an Intune app/configuration ID. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Read all enabled configurations for a client

```powershell
Get-AFApplicationConfigurations -id '<client-uuid>'
```

## Example 2: Read one application by UUID

```powershell
Get-AFApplicationConfigurations -id '<client-uuid>' -application_id '<application-uuid>'
```

## Example 3: Read by application slug

```powershell
Get-AFApplicationConfigurations -id '<client-uuid>' -application_id 'example-app'
```

## Behavior and limits

id is the AppFactory client UUID. application_id accepts the application UUID or slugified name; it is not the configuration ID. Disabled configurations are excluded.

## Output

An array of publisher configurations, including nested application/latest version and client policy; a single selection still returns a list.

## Source

[cmdlets/Public/api/appfactory/Get-AFApplicationConfigurations.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appfactory/Get-AFApplicationConfigurations.ps1)

