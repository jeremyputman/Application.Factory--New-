# Get-AFApplicationPublishedVersions

Load the module's cached inventory of versioned .intunewin files from package storage.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same imported module session. Package helpers need an admin-group API user, source/storage access, and prepared local files for the shown stage. Prefer [Start-AFProcess](Start-AFProcess.md) for a complete build.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFApplicationPublishedVersions  [<CommonParameters>]
```

## Parameters

No command-specific parameters. PowerShell common parameters remain available.

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Warm package inventory after settings initialization

```powershell
Set-AFSettings -configFile $packageConfig -Workspace $workspace
Get-AFApplicationPublishedVersions
```

## Example 2: Use the inventory through a version check

```powershell
$app = Get-AFApplications -id '<application-uuid>'
Test-AFApplicationVersion -Application $app
```

## Behavior and limits

Returns early when the module cache already exists. Start-AFProcess clears this cache at the start of each run. Public inventory reads container public literally; review nonstandard public-container naming. This is storage inventory, not Intune app inventory.

## Output

No public pipeline result; populates script-scoped application_packages.

## Source

[cmdlets/Public/general/Get-AFApplicationPublishedVersions.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Get-AFApplicationPublishedVersions.ps1)

