# Set-AFClientSettings

Load client publishing configuration, storage read SAS tokens, and Graph application credentials into module state.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Import the built module and prepare the matching JSON file and registered secret vault. See [configuration and prerequisites](configuration.md).

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFClientSettings -configFile <string> [-Workspace <string>] [-EnableLogging] [-LogLevel <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configFile` | `string` | Yes | Not specified | Path to the JSON configuration file. Start/Set-AFSettings use package-service JSON; Start/Set-AFClientSettings use client-publisher JSON. |
| `-Workspace` | `string` | No | `$PSScriptRoot` | Base working directory. Helpers create/use WorkingFolder and Logs beneath it. Supply an explicit operator-owned path. |
| `-EnableLogging` | `switch` | No | False | Enable module log messages and configure its PSFramework file provider. |
| `-LogLevel` | `string` | No | Not specified | Default PSFramework level for routine messages. Use Output for normal operator-facing messages, or Verbose together with -Verbose. Does not itself enable logging. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Initialize client API/Graph helpers

```powershell
Set-AFClientSettings -configFile $clientConfig -Workspace $workspace
```

## Example 2: Initialize client logging and inspect enabled policy

```powershell
Set-AFClientSettings -configFile $clientConfig -Workspace $workspace `
  -EnableLogging -LogLevel Output
Get-AFApplicationConfigurations -id '<client-uuid>'
```

## Behavior and limits

Uses the separate client JSON format. Fetches SAS tokens for api.client (AppFactory client UUID) and reads appregistration.secret from the configured vault. It does not itself authenticate to Graph until a Graph helper requests a token. Supply LogLevel when logging is enabled directly.

## Output

No designed output; initializes selected client, SAS tokens, and Graph settings.

## Source

[cmdlets/Public/general/Set-AFClientSettings.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFClientSettings.ps1)

