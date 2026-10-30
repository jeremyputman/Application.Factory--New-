# New-AFAppConfig

Create the desired publication settings for one application/client pair.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFAppConfig -application <string> -client <string> [-assignment_required <string[]>] [-assignment_required_exceptions <string[]>] [-assignment_available <string[]>] [-assignment_available_exceptions <string[]>] [-assignment_uninstall <string[]>] [-assignment_uninstall_exceptions <string[]>] [-enabled <bool>] [-create_updater_app <bool>] [-dependencies <object[]>] [-reconcile_reverse_dependencies <bool>] [-download_foreground <bool>] [-keep_previous_versions <int>] [-copy_previous_assignments <bool>] [-unassign_previous_assignments <bool>] [-esp_assignments <string[]>] [-filters <string>] [-interactive_install <bool>] [-interactive_uninstall <bool>] [-versions <string>] [-replace_in_place <bool>] [-include_version_in_display_name <bool>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-application` | `string` | Yes | Not specified | Existing AppFactory application UUID/lookup for a configuration. For capitalized Application object parameters, supply the nested catalog object from Get-AFApplications. |
| `-client` | `string` | Yes | Not specified | Existing visible AppFactory client UUID; include when writing assignment group names so they are scoped correctly. |
| `-assignment_required` | `string[]` | No | Not specified | Included destination group names for Required assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentRequired", "RequiredAssignments". |
| `-assignment_required_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Required assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentRequiredExceptions", "RequiredExceptions". |
| `-assignment_available` | `string[]` | No | Not specified | Included destination group names for Available assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentAvailable", "AvailableAssignments". |
| `-assignment_available_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Available assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentAvailableExceptions", "AvailableExceptions". |
| `-assignment_uninstall` | `string[]` | No | Not specified | Included destination group names for Uninstall assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentUninstall", "UninstallAssignments". |
| `-assignment_uninstall_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Uninstall assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentUninstallExceptions", "UninstallExceptions". |
| `-enabled` | `bool` | No | `$false` | Include the configuration in enabled client publisher exports. Always bind explicitly on creation; API default true differs from wrapper's local false declaration. Aliases: "AddToIntune". |
| `-create_updater_app` | `bool` | No | Not specified | Enable a separate updater role assigned Required to All Devices. Configure updater requirement rules and republish package metadata first. |
| `-dependencies` | `object[]` | No | Not specified | Array of client dependency objects: application_id, dependency_type (detect/autoInstall), version_policy (follow_config/pinned), version. @() clears. Explicit empty collection allowed. |
| `-reconcile_reverse_dependencies` | `bool` | No | Not specified | Reconcile managed following references to a verified replacement version. Pinned references retain their versions. |
| `-download_foreground` | `bool` | No | `$false` | Set foreground delivery priority for assignment settings when a plan is applied. Aliases: "downloadForeground", "foreground". |
| `-keep_previous_versions` | `int` | No | `0` | Number of prior managed Intune apps to retain in create-new mode; client publisher requires a nonnegative value. Aliases: "keepPreviousVersions", "KeepPrevious". |
| `-copy_previous_assignments` | `bool` | No | `$false` | Seed a new app's assignments from the most recent prior managed app. Aliases: "copyPreviousAssignments", "CopyPrevious". |
| `-unassign_previous_assignments` | `bool` | No | `$true` | Remove assignments from eligible old apps during cleanup, including retained apps when safe. Aliases: "unassignPreviousAssignments", "UnassignPrevious". |
| `-esp_assignments` | `string[]` | No | Not specified | Windows ESP profile names as a string array. Omit to preserve; @() clears desired selection but does not remove existing tenant ESP membership. Aliases: "espAssignments", "espprofiles". Explicit empty collection allowed. |
| `-filters` | `string` | No | Not specified | Legacy text parameter retained in wrappers. Current server field is read-only; use web/direct API assignment_filters instead. |
| `-interactive_install` | `bool` | No | `$false` | Use Auto instead of Silent deployment mode for normal client installation. Aliases: "interactiveInstall". |
| `-interactive_uninstall` | `bool` | No | `$false` | Use Auto instead of Silent deployment mode for normal client uninstall. Aliases: "interactiveUninstall". |
| `-versions` | `string` | No | Not specified | Release UUID selecting a specific catalog version, despite legacy help calling it a version string. Omit to retain/default; use direct API null to clear a pin. |
| `-replace_in_place` | `bool` | No | Not specified | Replace content on a verified managed Intune target; ordinary assignments are preserved. False uses create-new behavior. Aliases: "replaceInPlace". |
| `-include_version_in_display_name` | `bool` | No | `$true` | Include version in the Intune display name. Does not change app identity or displayVersion tracking. Aliases: "includeVersionInDisplayName". |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Create an explicitly disabled configuration

```powershell
New-AFAppConfig -application '<application-uuid>' -client '<client-uuid>' -enabled $false
```

## Example 2: Enable publication with an available assignment and retention

```powershell
New-AFAppConfig -application '<application-uuid>' -client '<client-uuid>' `
  -enabled $true -assignment_available @('Pilot Users') `
  -keep_previous_versions 1 -replace_in_place $false
```

## Example 3: Configure ESP selections

```powershell
New-AFAppConfig -application '<application-uuid>' -client '<client-uuid>' `
  -enabled $true -esp_assignments @('Pilot ESP', 'Standard ESP')
```

## Behavior and limits

Only one pair can exist. Pass enabled explicitly: omitted parameters are not sent, and the API default is true despite the wrapper declaration's false. versions is a Release UUID at the API. Structured assignment_filters and replace_legacy_filters are not exposed here; use the web editor/API. The old filters field is read-only. Saving a configuration does not publish an Intune app.

## Output

The newly created configuration object.

## Source

[cmdlets/Public/api/appconfig/New-AFAppConfig.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/New-AFAppConfig.ps1)

