# Get-AFApplicationClientFiles

Download a client application's versioned package assets from package storage.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Advanced client helper. Use [Start-AFClientProcess](Start-AFClientProcess.md) for operator runs. Direct examples below require the module's own initialized publishing context: client credentials, selected published_version, current published_application, and downloaded package/App.json where applicable. Creating ordinary caller variables named $script:published_version does not initialize the module's private scope.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFApplicationClientFiles -configuration <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configuration` | `PSCustomObject` | Yes | Not specified | Publisher-export configuration object from Get-AFApplicationConfigurations, not the CRUD configuration returned by Get-AFAppConfig. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Preferred operator download workflow

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name '<application-uuid>' -DownloadOnly
```

## Example 2: Invocation inside the publisher after its version is selected

```powershell
Get-AFApplicationClientFiles -configuration $configuration
```

## Behavior and limits

Set-AFClientSettings initializes SAS tokens, but this helper additionally needs the selected module-scoped published_version; it has no version parameter. Existing download folders for the slug are removed before downloading. Detection.ps1 is optional unless script detection requires it; the higher-level publisher validates required artifacts.

## Output

Files under WorkingFolder/Download/<slug>/ and module-scoped application_data loaded from App.json.

## Source

[cmdlets/Public/applications/Get-AFApplicationClientFiles.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Get-AFApplicationClientFiles.ps1)

