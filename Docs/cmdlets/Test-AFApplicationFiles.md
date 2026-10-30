# Test-AFApplicationFiles

Check that application metadata supplies an icon URL before packaging.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Test-AFApplicationFiles -Application <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Check one application

```powershell
$app = Get-AFApplications -id '<application-uuid>'
Test-AFApplicationFiles -Application $app
```

## Example 2: Upload an icon then recheck

```powershell
Set-AFApplicationIcon -id $app.id -iconpath 'C:\AppFactory\Assets\example.png'
$app = Get-AFApplications -id $app.id
Test-AFApplicationFiles -Application $app
```

## Behavior and limits

The implementation only checks iconUrl presence. It does not validate every source file or prove the icon URL is downloadable.

## Output

No output when the check passes; throws if iconUrl is missing.

## Source

[cmdlets/Public/applications/Test-AFApplicationFiles.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Test-AFApplicationFiles.ps1)

