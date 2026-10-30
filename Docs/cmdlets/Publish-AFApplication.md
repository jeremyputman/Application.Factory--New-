# Publish-AFApplication

Publish prepared package assets to Azure storage and register the version in AppFactory.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Publish-AFApplication -Application <PSCustomObject> -CurrentVersion <PSCustomObject> [-TestMode] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |
| `-CurrentVersion` | `PSCustomObject` | Yes | Not specified | Source discovery object containing Version and URI, usually returned by Test-AFApplicationVersion; not a Release API relation object. |
| `-TestMode` | `switch` | No | False | Skip storage publication in package processing. Builds/reads/local writes can still occur; this is not a universal dry run. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Preferred full build/storage publication

```powershell
Start-AFProcess -configFile $packageConfig -workspace $workspace `
  -application_id '<application-uuid>' -EnableLogging -LogLevel Output
```

## Example 2: Publish already prepared assets in an initialized package context

```powershell
Publish-AFApplication -Application $app -CurrentVersion $version
```

## Example 3: Prepare App.json without storage upload in that context

```powershell
Publish-AFApplication -Application $app -CurrentVersion $version -TestMode
```

## Behavior and limits

Requires a prepared PSADT/.intunewin tree, application/icon/detection data, Set-AFSettings, vault storage credentials, and API write permissions. TestMode returns after preparing App.json, before storage/API publication; MSI metadata reads may still occur. Normal publication uploads assets, registers the version, updates lastupdate, and removes its local installer/publish folders. It publishes to storage, not Intune.

## Output

Storage assets and updated API publication metadata; no designed result object.

## Source

[cmdlets/Public/applications/Publish-AFApplication.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplication.ps1)

