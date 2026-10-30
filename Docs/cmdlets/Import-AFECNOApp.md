# Import-AFECNOApp

Read an ECNO package's metadata and create a catalog application with its icon.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Prepare package JSON, an admin-group API token, ECNO source access, and the expected ECNO metadata files. This command initializes package settings itself.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Import-AFECNOApp -applicationName <string> [-publishTo <String[]>] -configFile <string> -workspace <string> [-EnableLogging] [-LogLevel <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-applicationName` | `string` | Yes | Not specified | ECNO application/package name to locate and import. |
| `-publishTo` | `String[]` | No | `@()` | Existing AppFactory client identifiers for storage publication/visibility. An empty target list means public publication. |
| `-configFile` | `string` | Yes | Not specified | Path to the JSON configuration file. Start/Set-AFSettings use package-service JSON; Start/Set-AFClientSettings use client-publisher JSON. |
| `-workspace` | `string` | Yes | Not specified | Base working directory. Helpers create/use WorkingFolder and Logs beneath it. Supply an explicit operator-owned path. |
| `-EnableLogging` | `switch` | No | False | Enable module log messages and configure its PSFramework file provider. |
| `-LogLevel` | `string` | No | `"Verbose"` | Default PSFramework level for routine messages. Use Output for normal operator-facing messages, or Verbose together with -Verbose. Does not itself enable logging. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Import an ECNO application

```powershell
Import-AFECNOApp -applicationName 'Example ECNO App' `
  -configFile $packageConfig -workspace $workspace -EnableLogging -LogLevel Output
```

## Example 2: Restrict a new import to a client

```powershell
Import-AFECNOApp -applicationName 'Another ECNO App' `
  -publishTo @('<client-uuid>') -configFile $packageConfig `
  -workspace $workspace -EnableLogging -LogLevel Output
```

## Behavior and limits

Initializes package settings internally. Requires the ECNO storage adapter/credentials and expected metadata file layout; the importer reads fixed line positions in _win32app.txt and _detect.ps1. It creates catalog metadata/icon and removes temporary source work; use Start-AFProcess for subsequent package publication.

## Output

Catalog/API and local work side effects; no stable documented success object.

## Source

[cmdlets/Public/general/Import-AFECNOApp.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Import-AFECNOApp.ps1)

