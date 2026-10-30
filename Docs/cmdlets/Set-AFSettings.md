# Set-AFSettings

Load package-service configuration, API authentication, storage/source settings, and optional logging into module state.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Import the built module and prepare the matching JSON file and registered secret vault. See [configuration and prerequisites](configuration.md).

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFSettings -configFile <string> [-Workspace <string>] [-EnableLogging] [-LogLevel <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configFile` | `string` | Yes | Not specified | Path to the JSON configuration file. Start/Set-AFSettings use package-service JSON; Start/Set-AFClientSettings use client-publisher JSON. |
| `-Workspace` | `string` | No | `$PSScriptRoot` | Base working directory. Helpers create/use WorkingFolder and Logs beneath it. Supply an explicit operator-owned path. |
| `-EnableLogging` | `switch` | No | False | Enable module log messages and configure its PSFramework file provider. |
| `-LogLevel` | `string` | No | Not specified | Default PSFramework level for routine messages. Use Output for normal operator-facing messages, or Verbose together with -Verbose. Does not itself enable logging. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Initialize API and package helpers

```powershell
Set-AFSettings -configFile $packageConfig -Workspace $workspace
```

## Example 2: Initialize with operator-visible logging

```powershell
Set-AFSettings -configFile $packageConfig -Workspace $workspace `
  -EnableLogging -LogLevel Output
Get-AFApplications
```

## Behavior and limits

Reads the API token from Get-Secret using JSON api.key as the secret name. api.url must end with /. Workspace is the base path; the helper appends WorkingFolder, Workspace, LocalStorage, and Logs. Supply LogLevel when enabling logging directly. Settings are module state, so avoid mixing clients/package jobs in one session.

## Output

No designed output; initializes module script-scoped settings.

## Source

[cmdlets/Public/general/Set-AFSettings.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFSettings.ps1)

