# Set-AFAppConfig

Patch selected fields on an existing client application configuration.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Set-AFAppConfig -id <string> [-application <string>] [-client <string>] [-assignment_required <string[]>] [-assignment_required_exceptions <string[]>] [-assignment_available <string[]>] [-assignment_available_exceptions <string[]>] [-assignment_uninstall <string[]>] [-assignment_uninstall_exceptions <string[]>] [-enabled <bool>] [-create_updater_app <bool>] [-dependencies <object[]>] [-reconcile_reverse_dependencies <bool>] [-download_foreground <bool>] [-keep_previous_versions <int>] [-copy_previous_assignments <bool>] [-unassign_previous_assignments <bool>] [-esp_assignments <string[]>] [-filters <string>] [-interactive_install <bool>] [-interactive_uninstall <bool>] [-versions <string>] [-replace_in_place <bool>] [-include_version_in_display_name <bool>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | Yes | Not specified | AppFactory configuration UUID. |
| `-application` | `string` | No | Not specified | Existing AppFactory application UUID/lookup for a configuration. For capitalized Application object parameters, supply the nested catalog object from Get-AFApplications. |
| `-client` | `string` | No | Not specified | Existing visible AppFactory client UUID; include when writing assignment group names so they are scoped correctly. |
| `-assignment_required` | `string[]` | No | Not specified | Included destination group names for Required assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentRequired". |
| `-assignment_required_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Required assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentRequiredExceptions". |
| `-assignment_available` | `string[]` | No | Not specified | Included destination group names for Available assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentAvailable". |
| `-assignment_available_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Available assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentAvailableExceptions". |
| `-assignment_uninstall` | `string[]` | No | Not specified | Included destination group names for Uninstall assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentUninstall". |
| `-assignment_uninstall_exceptions` | `string[]` | No | Not specified | Excluded destination group names for Uninstall assignments. Use a string array; include client UUID on group-name writes. Aliases: "assignmentUninstallExceptions". |
| `-enabled` | `bool` | No | `$false` | Include the configuration in enabled client publisher exports. Always bind explicitly on creation; API default true differs from wrapper's local false declaration. |
| `-create_updater_app` | `bool` | No | Not specified | Enable a separate updater role assigned Required to All Devices. Configure updater requirement rules and republish package metadata first. |
| `-dependencies` | `object[]` | No | Not specified | Array of client dependency objects: application_id, dependency_type (detect/autoInstall), version_policy (follow_config/pinned), version. @() clears. Explicit empty collection allowed. |
| `-reconcile_reverse_dependencies` | `bool` | No | Not specified | Reconcile managed following references to a verified replacement version. Pinned references retain their versions. |
| `-download_foreground` | `bool` | No | `$false` | Set foreground delivery priority for assignment settings when a plan is applied. Aliases: "downloadForeground". |
| `-keep_previous_versions` | `int` | No | `0` | Number of prior managed Intune apps to retain in create-new mode; client publisher requires a nonnegative value. Aliases: "keepPreviousVersions". |
| `-copy_previous_assignments` | `bool` | No | `$false` | Seed a new app's assignments from the most recent prior managed app. Aliases: "copyPreviousAssignments". |
| `-unassign_previous_assignments` | `bool` | No | `$true` | Remove assignments from eligible old apps during cleanup, including retained apps when safe. Aliases: "unassignPreviousAssignments". |
| `-esp_assignments` | `string[]` | No | Not specified | Windows ESP profile names as a string array. Omit to preserve; @() clears desired selection but does not remove existing tenant ESP membership. Aliases: "espAssignments". Explicit empty collection allowed. |
| `-filters` | `string` | No | Not specified | Legacy text parameter retained in wrappers. Current server field is read-only; use web/direct API assignment_filters instead. |
| `-interactive_install` | `bool` | No | `$false` | Use Auto instead of Silent deployment mode for normal client installation. Aliases: "interactiveInstall". |
| `-interactive_uninstall` | `bool` | No | `$false` | Use Auto instead of Silent deployment mode for normal client uninstall. Aliases: "interactiveUninstall". |
| `-versions` | `string` | No | Not specified | Release UUID selecting a specific catalog version, despite legacy help calling it a version string. Omit to retain/default; use direct API null to clear a pin. |
| `-replace_in_place` | `bool` | No | Not specified | Replace content on a verified managed Intune target; ordinary assignments are preserved. False uses create-new behavior. Aliases: "replaceInPlace". |
| `-include_version_in_display_name` | `bool` | No | `$true` | Include version in the Intune display name. Does not change app identity or displayVersion tracking. Aliases: "includeVersionInDisplayName". |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Enable a configuration and preserve other settings

```powershell
Set-AFAppConfig -id '<configuration-uuid>' -enabled $true
```

## Example 2: Update assignments with explicit client scope

```powershell
Set-AFAppConfig -id '<configuration-uuid>' -client '<client-uuid>' `
  -assignment_required @('Pilot Devices') -assignment_available @()
```

## Example 3: Select replacement and display naming behavior

```powershell
Set-AFAppConfig -id '<configuration-uuid>' -replace_in_place $true `
  -include_version_in_display_name $false
```

## Example 4: Set and clear ESP names

```powershell
Set-AFAppConfig -id '<configuration-uuid>' -esp_assignments @('Pilot ESP')
# To clear desired selections later:
# Set-AFAppConfig -id '<configuration-uuid>' -esp_assignments @()
```

## Example 5: Follow a prerequisite configuration

```powershell
$dependency = @{
  application_id = '<prerequisite-application-uuid>'
  dependency_type = 'autoInstall'
  version_policy = 'follow_config'
  version = ''
}
Set-AFAppConfig -id '<configuration-uuid>' -dependencies @($dependency)
```

## Behavior and limits

Omitted fields are preserved. Include client UUID when writing assignment names. versions expects a Release UUID; use direct API null to clear a version pin. Empty dependencies/ESP arrays clear desired lists. Structured filters need web/API. Normal replacement and same-version reconciliation preserve existing Intune assignments, so an assignment-setting patch is not an immediate tenant reassignment.

## Output

The updated configuration object.

## Source

[cmdlets/Public/api/appconfig/Set-AFAppConfig.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Set-AFAppConfig.ps1)

