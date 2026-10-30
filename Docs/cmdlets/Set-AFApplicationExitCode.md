# Set-AFApplicationExitCode

Add or remove one application exit code through the action API.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFApplicationExitCode -id <string> -action <string> -section <string> -type <string> -exitcode <int> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory catalog application UUID or supported name/slug lookup. |
| `-action` | `string` | Yes | Not specified | add or remove for the selected relation. Accepted: 'add', 'remove'. |
| `-section` | `string` | Yes | Not specified | install or uninstall. Exit codes allow all listed types only for install; uninstall supports ignore. Accepted: 'install', 'uninstall'. |
| `-type` | `string` | Yes | Not specified | install: success, reboot, ignore; uninstall: ignore only. Wrapper validation is broader than server uninstall acceptance. Accepted: 'ignore', 'reboot', 'success'. |
| `-exitcode` | `int` | Yes | Not specified | Integer exit code to add/remove. Server PATCH rejects 0 through a truthiness check in this baseline. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Add an installation reboot exit code

```powershell
Set-AFApplicationExitCode -id '<application-uuid>' -action add `
  -section install -type reboot -exitcode 3010
```

## Example 2: Remove an uninstall ignored code

```powershell
Set-AFApplicationExitCode -id '<application-uuid>' -action remove `
  -section uninstall -type ignore -exitcode 1605
```

## Behavior and limits

Server allows success/reboot/ignore for install, but only ignore for uninstall. The PATCH handler rejects integer zero through its truthiness check, despite source help showing exitcode 0. Use a corrected/verified API path for that case. Rebuild packages to propagate changes.

## Output

API action response.

## Source

[cmdlets/Public/api/applications/Set-AFApplicationExitCode.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplicationExitCode.ps1)

