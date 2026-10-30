# Set-AFApplicationConflictingProcess

Add or remove a process name in an application's conflicting-process policy.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFApplicationConflictingProcess -id <string> -action <string> -section <string> -type <string> -process <string> [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory catalog application UUID or supported name/slug lookup. |
| `-action` | `string` | Yes | Not specified | add or remove for the selected relation. Accepted: 'add', 'remove'. |
| `-section` | `string` | Yes | Not specified | install or uninstall. Exit codes allow all listed types only for install; uninstall supports ignore. Accepted: 'install', 'uninstall'. |
| `-type` | `string` | Yes | Not specified | start or end. Baseline server end relation naming is inconsistent; examples use start. Accepted: 'start', 'end'. |
| `-process` | `string` | Yes | Not specified | Conflicting process name such as example.exe. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Add an install-start process

```powershell
Set-AFApplicationConflictingProcess -id '<application-uuid>' `
  -action add -section install -type start -process 'example.exe'
```

## Example 2: Remove an uninstall-start process

```powershell
Set-AFApplicationConflictingProcess -id '<application-uuid>' `
  -action remove -section uninstall -type start -process 'example.exe'
```

## Behavior and limits

The server's end route builds relation names that differ from the model; end operations need correction/verification before use. The examples use start. Rebuild packages after changing generated deployment behavior.

## Output

API action response with changed, detail, and data.

## Source

[cmdlets/Public/api/applications/Set-AFApplicationConflictingProcess.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplicationConflictingProcess.ps1)

