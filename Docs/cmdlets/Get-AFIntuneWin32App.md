# Get-AFIntuneWin32App

Read AppFactory-marked Win32 apps from the initialized destination Intune tenant.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFClientSettings](Set-AFClientSettings.md) for the intended tenant and vault credentials. Graph helpers authenticate on demand. Verify target IDs before mutations.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Get-AFIntuneWin32App [-Failed] [<CommonParameters>]

Get-AFIntuneWin32App -Id <string> [-Failed] [<CommonParameters>]

Get-AFIntuneWin32App -DisplayName <string> [-Failed] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Id` | `string` | In Id set | Not specified | Destination Intune app GUID (not an AppFactory catalog ID). |
| `-DisplayName` | `string` | In DisplayName set | Not specified | Substring filter for Intune displayName. Mutually exclusive with Id in Get-AFIntuneWin32App. |
| `-Failed` | `switch` | No | False | Filter managed Intune apps by the uploadState values classified by this function as failed/unresolved; does not delete them. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: List all AppFactory-marked Win32 apps

```powershell
Set-AFClientSettings -configFile $clientConfig -Workspace $workspace
Get-AFIntuneWin32App | Select-Object id, displayName, displayVersion
```

## Example 2: Read by Intune app ID

```powershell
Get-AFIntuneWin32App -Id '<intune-app-uuid>'
```

## Example 3: Search names and inspect failed states

```powershell
Get-AFIntuneWin32App -DisplayName 'Example App' -Failed
```

## Behavior and limits

Id and DisplayName are separate parameter sets and cannot be combined. No selector uses the All set. DisplayName uses a contains filter; all requests also require AppFactoryID in Notes. Failed filters uploadState values locally and is not an automatic deletion/recovery action.

## Output

Intune application objects; follows Graph pagination.

## Source

[cmdlets/Public/intune/Get-AFIntuneWin32App.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/Get-AFIntuneWin32App.ps1)

