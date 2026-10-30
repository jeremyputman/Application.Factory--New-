# Remove-AFIntuneAppAssignments

Remove assignments from one verified managed Intune application.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFClientSettings](Set-AFClientSettings.md) for the intended tenant and vault credentials. Graph helpers authenticate on demand. Verify target IDs before mutations.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Remove-AFIntuneAppAssignments -Id <guid> -ApplicationId <string> -Version <string> [-ApplicationRole <string>] [-ProtectedAppId <string>] [-TimeoutSeconds <int>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-Id` | `guid` | Yes | Not specified | Destination Intune app GUID (not an AppFactory catalog ID). |
| `-ApplicationId` | `string` | Yes | Not specified | Applicationid. See the source declaration and API requirements for the selected mode. |
| `-Version` | `string` | Yes | Not specified | Version. See the source declaration and API requirements for the selected mode. |
| `-ApplicationRole` | `string` | No | `"normal"` | Managed Notes role to verify: normal or updater. Accepted: "normal", "updater". |
| `-ProtectedAppId` | `string` | No | `[string]$script:published_application.id` | Current Intune app ID that must be protected from cleanup. Defaults from module state; explicitly supply a known current target for manual cleanup. |
| `-TimeoutSeconds` | `int` | No | `120` | Maximum cleanup confirmation wait in seconds after a tenant operation. Range: 0, 600. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Preview removal with identity checks

```powershell
Set-AFClientSettings -configFile $clientConfig -Workspace $workspace
Remove-AFIntuneAppAssignments -Id '<old-intune-app-uuid>' `
  -ApplicationId '<appfactory-application-uuid>' -Version '1.2.3' `
  -ProtectedAppId '<current-intune-app-uuid>' -WhatIf
```

## Example 2: Remove assignments from the verified old normal app

```powershell
Remove-AFIntuneAppAssignments -Id '<old-intune-app-uuid>' `
  -ApplicationId '<appfactory-application-uuid>' -Version '1.2.3' `
  -ProtectedAppId '<current-intune-app-uuid>' -Confirm
```

## Behavior and limits

Id is the Intune application GUID; ApplicationId is the AppFactory catalog UUID. Version/role/ownership/protected target/dependency checks must pass. WhatIf still reads Graph and performs checks. This does not delete the app. Prefer orchestrated retention for routine cleanup.

## Output

No designed result object; returns after assignments are confirmed absent or the app no longer exists.

This command implements SupportsShouldProcess: -WhatIf previews the mutation after read/identity checks; -Confirm requests confirmation before the mutation. These common options do not eliminate prerequisite reads.

## Source

[cmdlets/Public/intune/Remove-AFIntuneAppAssignments.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/Remove-AFIntuneAppAssignments.ps1)

