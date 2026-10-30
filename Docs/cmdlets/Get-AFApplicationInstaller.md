# Get-AFApplicationInstaller

Retrieve installer files for a source version into the working installer directory.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFApplicationInstaller -Application <PSCustomObject> -CurrentVersion <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |
| `-CurrentVersion` | `PSCustomObject` | Yes | Not specified | Source discovery object containing Version and URI, usually returned by Test-AFApplicationVersion; not a Release API relation object. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Discover and download a source version

```powershell
$app = Get-AFApplications -id '<application-uuid>'
$version = Test-AFApplicationVersion -Application $app -force
if (-not $version) { throw 'No source version available.' }
Get-AFApplicationInstaller -Application $app -CurrentVersion $version
```

## Behavior and limits

Requires Set-AFSettings and the dependencies/credentials for the selected source adapter. CurrentVersion is a source discovery object with Version/URI, not a Release API record. Local sources copy a directory; other providers may download a file. It does not build or publish a package.

## Output

Local installer files under WorkingFolder/Installers/<slug>/.

## Source

[cmdlets/Public/applications/Get-AFApplicationInstaller.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Get-AFApplicationInstaller.ps1)

