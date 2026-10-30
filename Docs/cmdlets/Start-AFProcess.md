# Start-AFProcess

Discover installer versions, build packages, and publish package assets to Azure storage.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Import the built module with its Templates/SupportFiles; configure package JSON, vault/API/storage credentials and source-provider dependencies. This function initializes package settings itself.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Start-AFProcess -configFile <string> -workspace <string> [-application_id <string>] [-EnableLogging] [-LogLevel <string>] [-Force] [-TestMode] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configFile` | `string` | Yes | Not specified | Path to the JSON configuration file. Start/Set-AFSettings use package-service JSON; Start/Set-AFClientSettings use client-publisher JSON. |
| `-workspace` | `string` | Yes | Not specified | Base working directory. Helpers create/use WorkingFolder and Logs beneath it. Supply an explicit operator-owned path. |
| `-application_id` | `string` | No | Not specified | AppFactory catalog application UUID or application lookup, not an Intune app/configuration ID. |
| `-EnableLogging` | `switch` | No | False | Enable module log messages and configure its PSFramework file provider. |
| `-LogLevel` | `string` | No | `"Verbose"` | Default PSFramework level for routine messages. Use Output for normal operator-facing messages, or Verbose together with -Verbose. Does not itself enable logging. |
| `-Force` | `switch` | No | False | Bypass the usual already-processed version decision. In the client process this can create a duplicate same-version app or replace content; it does not bypass unfinished journals. |
| `-TestMode` | `switch` | No | False | Skip storage publication in package processing. Builds/reads/local writes can still occur; this is not a universal dry run. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Build/publish one application

```powershell
Start-AFProcess -configFile $packageConfig -workspace $workspace `
  -application_id '<application-uuid>' -EnableLogging -LogLevel Output
```

## Example 2: Process all active unpaused applications

```powershell
Start-AFProcess -configFile $packageConfig -workspace $workspace `
  -EnableLogging -LogLevel Output
```

## Example 3: Build one application without storage publication

```powershell
Start-AFProcess -configFile $packageConfig -workspace $workspace `
  -application_id '<application-uuid>' -TestMode -EnableLogging -LogLevel Output
```

## Example 4: Force a package rebuild of the current source version

```powershell
Start-AFProcess -configFile $packageConfig -workspace $workspace `
  -application_id '<application-uuid>' -Force -EnableLogging -LogLevel Output
```

## Behavior and limits

application_id is an application UUID or existing lookup, not a configuration ID. TestMode still downloads/builds and reads storage/API; it skips publication metadata and retains work. Normal runs clean WorkingFolder/Installers and Publish. Errors are caught per app and processing continues, so inspect logs/storage/API rather than relying on a clean return. This command publishes to storage, not Intune.

## Output

Logs and storage/catalog side effects. It does not return the structured per-app result contract used by Start-AFClientProcess.

## Source

[cmdlets/Public/general/Start-AFProcess.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Start-AFProcess.ps1)

