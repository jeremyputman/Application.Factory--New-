# New-AFApplicationPackage

Create and customize a PSADT deployment folder using application metadata and installer assets.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFApplicationPackage -Application <PSCustomObject> -CurrentVersion <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |
| `-CurrentVersion` | `PSCustomObject` | Yes | Not specified | Source discovery object containing Version and URI, usually returned by Test-AFApplicationVersion; not a Release API relation object. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Prepare a package folder after source download

```powershell
$app = Get-AFApplications -id '<application-uuid>'
$version = Test-AFApplicationVersion -Application $app -force
if (-not $version) { throw 'No source version available.' }
Test-AFApplicationFiles -Application $app
Get-AFApplicationInstaller -Application $app -CurrentVersion $version
New-AFApplicationPackage -Application $app -CurrentVersion $version
Set-AFApplicationInstall -Application $app
Set-AFApplicationUninstall -Application $app
```

## Behavior and limits

Recreates the application's publish folder. The built module must include Templates/PSADT. This prepares the deployment tree; call New-AFIntuneFile for .intunewin, or use Start-AFProcess to orchestrate everything.

## Output

Prepared PSADT files under WorkingFolder/Publish/<slug>/.

## Source

[cmdlets/Public/applications/New-AFApplicationPackage.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/New-AFApplicationPackage.ps1)

