# Test-AFApplicationVersion

Discover the source version and decide whether package storage needs that version.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Test-AFApplicationVersion -Application <PSCustomObject> [-force] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |
| `-force` | `switch` | No | False | Bypass the usual already-processed version decision. In the client process this can create a duplicate same-version app or replace content; it does not bypass unfinished journals. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Check whether a package is needed

```powershell
$app = Get-AFApplications -id '<application-uuid>'
$version = Test-AFApplicationVersion -Application $app
if ($version) { $version | Select-Object Version, URI }
```

## Example 2: Retrieve the source version even if already published

```powershell
$version = Test-AFApplicationVersion -Application $app -force
```

## Behavior and limits

Requires source-provider access and package-storage inventory access. force bypasses the already-packaged decision but does not guarantee a missing source will resolve. Local storage uses newest LastWriteTime child; PSADT source uses recorded versions. Source version objects differ from catalog Release records.

## Output

A CurrentVersion object (Version/URI) when packaging is needed, otherwise false.

## Source

[cmdlets/Public/applications/Test-AFApplicationVersion.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Test-AFApplicationVersion.ps1)

