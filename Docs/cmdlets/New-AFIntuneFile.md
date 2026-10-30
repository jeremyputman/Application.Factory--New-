# New-AFIntuneFile

Package a prepared PSADT deployment tree into an .intunewin file.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFIntuneFile -Application <PSCustomObject> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Application` | `PSCustomObject` | Yes | Not specified | Nested application metadata object from Get-AFApplications; includes information/sourcefiles/install/uninstall/program/requirements/detection. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Package after generating install/uninstall behavior

```powershell
New-AFApplicationPackage -Application $app -CurrentVersion $version
Set-AFApplicationInstall -Application $app
Set-AFApplicationUninstall -Application $app
New-AFIntuneFile -Application $app
```

## Behavior and limits

Requires Set-AFSettings, prepared installer/template files, and bundled SupportFiles/IntuneWinAppUtil.exe. This runs the packaging executable locally; it does not upload to Intune or storage.

## Output

WorkingFolder/Publish/<slug>/<application-name>.intunewin; throws on a nonzero packaging utility exit code.

## Source

[cmdlets/Public/intune/New-AFIntuneFile.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/New-AFIntuneFile.ps1)

