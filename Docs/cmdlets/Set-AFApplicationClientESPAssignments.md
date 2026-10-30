# Set-AFApplicationClientESPAssignments

Add the current published application to selected Windows enrollment status pages and verify membership.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFApplicationClientESPAssignments -configuration <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Configure desired profile names through the API

```powershell
Set-AFAppConfig -id '<configuration-uuid>' -esp_assignments @('Pilot ESP')
```

## Example 2: Internal invocation after publication readiness is verified

```powershell
Set-AFApplicationClientESPAssignments -configuration $configuration
```

## Behavior and limits

Requires current module published_application.id and initialized Graph credentials. Profile names must resolve uniquely to Windows ESP configurations. It adds the app to selectedMobileAppIds; clearing desired names is not a removal operation. Normal in-place publishing skips ESP writes.

## Output

No designed result object; tenant ESP configuration is updated.

## Source

[cmdlets/Public/applications/Set-AFApplicationClientESPAssignments.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationClientESPAssignments.ps1)

