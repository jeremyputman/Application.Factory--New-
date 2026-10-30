# Copy-AFApplicationClientGroups

Copy assignment bodies from a previous Intune application to the current published application.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Copy-AFApplicationClientGroups -intune_apps <object> -configuration <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-intune_apps` | `object` | Yes | Not specified | Vetted previous Intune app objects used as assignment-copy sources. |
| `-configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Invocation inside an initialized client publication context

```powershell
Copy-AFApplicationClientGroups -intune_apps $previousApps -configuration $configuration
```

## Behavior and limits

Requires intune_apps plus a publisher-export configuration and module-scoped published_application/published_version. Previous apps must be vetted for the intended client/application; it chooses the most recent source in the planner. Prefer Start-AFClientProcess with copy_previous_assignments enabled; this helper does not run the full publication/cleanup workflow.

## Output

No designed success object; assignments are written to the current module publishing target.

## Source

[cmdlets/Public/applications/Copy-AFApplicationClientGroups.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Copy-AFApplicationClientGroups.ps1)

