# Set-AFApplicationClientGroups

Apply and verify the assignment plan for the current published application.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFApplicationClientGroups -configuration <PSCustomObject> [-Plan <object>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |
| `-Plan` | `object` | No | Not specified | Optional precomputed assignment plan used inside client orchestration. If omitted, the helper builds one seeded from the current published app. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Internal invocation using a precomputed plan

```powershell
Set-AFApplicationClientGroups -configuration $configuration -Plan $plan
```

## Example 2: Internal invocation that builds a plan from the current published app

```powershell
Set-AFApplicationClientGroups -configuration $configuration
```

## Behavior and limits

Requires module-scoped published_application, published_version, Graph credentials, and a publisher configuration. If Plan is omitted, planning seeds from the current app. Groups/filters must resolve in the destination tenant. Start-AFClientProcess determines whether assignments should be applied or preserved; invoking this directly bypasses that mode decision.

## Output

No designed result object; writes/verifies tenant app assignments.

## Source

[cmdlets/Public/applications/Set-AFApplicationClientGroups.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationClientGroups.ps1)

