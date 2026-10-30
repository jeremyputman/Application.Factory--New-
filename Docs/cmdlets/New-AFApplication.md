# New-AFApplication

Create a shared catalog definition through the nested application API.

Source baseline: module branch `0.2.0`, commit `232b6b3e2a61ec5ece934a6534c402843afa335d`; paired webapp commit `67bfe66cd68a825e24a5429d7b48b71391d527c8`. Examples were checked against source, not run against a live environment. [All cmdlets](README.md).

## Prerequisites

Initialize [Set-AFSettings](Set-AFSettings.md) in the same module session (or client settings for read-only API operations). Catalog/client writes require the configured admin group; configuration/token endpoints require the configured user/admin group and visibility.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
New-AFApplication [-id <string>] [-name <string>] [-description <string>] [-publisher <string>] [-notes <string>] [-owner <string>] [-information_url <string>] [-privacy_url <string>] [-appsource <string>] [-appid <string>] [-appsetupfilename <string>] [-storageaccountcontainername <string>] [-filter_architecture <string>] [-filter_platform <string>] [-filter_channel <string>] [-filter_type <string>] [-filter_installer_type <string>] [-filter_release <string>] [-filter_language <string>] [-filter_imagetype <string>] [-dependson <string>] [-active <bool>] [-lastupdate <datetime>] [-pauseupdate <bool>] [-publishto <string[]>] [-versions <string[]>] [-install_type <string>] [-install_argumentList <string>] [-install_additionalArgumentList <string>] [-install_secureArgumentList <bool>] [-install_installer <string>] [-install_transforms <string>] [-install_SkipMSIAlreadyInstalledCheck <bool>] [-install_script <string>] [-install_wim <bool>] [-install_successExitCodes <string>] [-install_rebootExitCodes <string[]>] [-install_ignoreExitCodes <string[]>] [-install_conflictingProcessStart <string[]>] [-install_conflictingProcessEnd <string[]>] [-uninstall_type <string>] [-uninstall_namematch <string>] [-uninstall_productcode <string>] [-uninstall_filterscript <string>] [-uninstall_argumentlist <string>] [-uninstall_additionalargumentlist <string>] [-uninstall_secureargumentlist <bool>] [-uninstall_script <string>] [-uninstall_installer <string>] [-uninstall_wim <bool>] [-uninstall_dirfiles <bool>] [-uninstall_ignoreexitcodes <string[]>] [-uninstall_conflictingprocessstart <string[]>] [-uninstall_conflictingprocessend <string[]>] [-installexperience <string>] [-devicerestartbehavior <string>] [-allowavailableuninstall <bool>] [-minimumsupportedwindowsrelease <string>] [-architecture <string>] [-minimumfreediskspaceinmb <int>] [-minimummemoryinmb <int>] [-additionalrules <object[]>] [-updaterrules <object[]>] [-detection_type <string>] [-detection_scriptfile <string>] [-detection_enforcesignaturecheck <bool>] [-detection_runas32bit <bool>] [-detection_detectionmethod <string>] [-detection_keypath <string>] [-detection_valuename <string>] [-detection_operator <string>] [-detection_productversionoperator <string>] [-detection_value <string>] [-detection_check32biton64system <bool>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-id` | `string` | No | Not specified | AppFactory catalog application UUID or supported name/slug lookup. |
| `-name` | `string` | No | Not specified | The display name of the application. Aliases: "DisplayName". |
| `-description` | `string` | No | Not specified | The description of the application. |
| `-publisher` | `string` | No | Not specified | The publisher of the application. |
| `-notes` | `string` | No | Not specified | Notes for the application. |
| `-owner` | `string` | No | Not specified | Owner of the application. |
| `-information_url` | `string` | No | Not specified | Information URL for the application. Aliases: "informationurl". |
| `-privacy_url` | `string` | No | Not specified | Privacy URL for the application. Aliases: "privacyurl". |
| `-appsource` | `string` | No | Not specified | Source type for the application (azure_storage, winget, evergreen, sharepoint, psadt, ecno, local_storage). Accepted: 'azure_storage', 'winget', 'evergreen', 'sharepoint', 'psadt', 'ecno', 'local_storage'. |
| `-appid` | `string` | No | Not specified | Application ID. |
| `-appsetupfilename` | `string` | No | Not specified | Setup file name for the application. |
| `-storageaccountcontainername` | `string` | No | Not specified | Storage account container name. |
| `-filter_architecture` | `string` | No | Not specified | Filter for architecture. |
| `-filter_platform` | `string` | No | Not specified | Filter for platform. |
| `-filter_channel` | `string` | No | Not specified | Filter for channel. |
| `-filter_type` | `string` | No | Not specified | Filter for type. |
| `-filter_installer_type` | `string` | No | Not specified | Filter for installer type. Aliases: "filter_installertype". |
| `-filter_release` | `string` | No | Not specified | Filter for release. |
| `-filter_language` | `string` | No | Not specified | Filter for language. |
| `-filter_imagetype` | `string` | No | Not specified | Filter for image type. |
| `-dependson` | `string` | No | Not specified | Legacy source-level dependency parameter. Wrapper declares a string but API expects an application-ID relation list; use direct API for this field and config dependencies for modern Intune policy. |
| `-active` | `bool` | No | Not specified | Whether the catalog application is active; package workflow selects active applications. |
| `-lastupdate` | `datetime` | No | Not specified | Catalog last-update timestamp. Normally written after successful storage publication; setting it manually does not create assets. |
| `-pauseupdate` | `bool` | No | Not specified | Pause application package processing when true. |
| `-publishto` | `string[]` | No | Not specified | Existing AppFactory client identifiers for storage publication/visibility. An empty target list means public publication. |
| `-versions` | `string[]` | No | Not specified | Array of raw version strings to attach to the new catalog definition; does not upload packages. Aliases: "AppVersion". |
| `-install_type` | `string` | No | Not specified | Type of installation (none, script, ecno, exe, msi). Accepted: 'none', 'script', 'ecno', 'exe', 'msi'. |
| `-install_argumentList` | `string` | No | Not specified | Arguments for installation. |
| `-install_additionalArgumentList` | `string` | No | Not specified | Additional arguments for installation. |
| `-install_secureArgumentList` | `bool` | No | Not specified | Boolean for secure installation arguments. |
| `-install_installer` | `string` | No | Not specified | Installer for installation. |
| `-install_transforms` | `string` | No | Not specified | Transforms for installation. |
| `-install_SkipMSIAlreadyInstalledCheck` | `bool` | No | Not specified | Boolean to skip MSI already installed check. |
| `-install_script` | `string` | No | Not specified | Script for installation. |
| `-install_wim` | `bool` | No | Not specified | Boolean for WIM installation. |
| `-install_successExitCodes` | `string` | No | Not specified | Success exit codes for installation. |
| `-install_rebootExitCodes` | `string[]` | No | Not specified | Reboot exit codes for installation. |
| `-install_ignoreExitCodes` | `string[]` | No | Not specified | Ignore exit codes for installation. |
| `-install_conflictingProcessStart` | `string[]` | No | Not specified | Processes that conflict at start of installation. |
| `-install_conflictingProcessEnd` | `string[]` | No | Not specified | Processes that conflict at end of installation. |
| `-uninstall_type` | `string` | No | Not specified | Type of uninstallation (none, msi, exe, name, guid, ecno, script). Accepted: 'none', 'msi', 'exe', 'name', 'guid', 'ecno', 'script'. |
| `-uninstall_namematch` | `string` | No | Not specified | Name match for uninstallation. Aliases: "uninstall_name". |
| `-uninstall_productcode` | `string` | No | Not specified | Product code for uninstallation. |
| `-uninstall_filterscript` | `string` | No | Not specified | Filter script for uninstallation. |
| `-uninstall_argumentlist` | `string` | No | Not specified | Arguments for uninstallation. |
| `-uninstall_additionalargumentlist` | `string` | No | Not specified | Additional arguments for uninstallation. |
| `-uninstall_secureargumentlist` | `bool` | No | Not specified | Boolean for secure uninstallation arguments. |
| `-uninstall_script` | `string` | No | Not specified | Script for uninstallation. |
| `-uninstall_installer` | `string` | No | Not specified | Installer for uninstallation. |
| `-uninstall_wim` | `bool` | No | Not specified | Boolean for WIM uninstallation. |
| `-uninstall_dirfiles` | `bool` | No | Not specified | Boolean for uninstalling directory files. |
| `-uninstall_ignoreexitcodes` | `string[]` | No | Not specified | Ignore exit codes for uninstallation. |
| `-uninstall_conflictingprocessstart` | `string[]` | No | Not specified | Processes that conflict at start of uninstallation. |
| `-uninstall_conflictingprocessend` | `string[]` | No | Not specified | Processes that conflict at end of uninstallation. |
| `-installexperience` | `string` | No | Not specified | Installation experience (user, system). Accepted: 'user', 'system'. |
| `-devicerestartbehavior` | `string` | No | Not specified | Device restart behavior (suppress, force, basedOnReturnCode, allow). Accepted: 'suppress', 'force', 'basedOnReturnCode', 'allow'. |
| `-allowavailableuninstall` | `bool` | No | Not specified | Boolean to allow available uninstall. |
| `-minimumsupportedwindowsrelease` | `string` | No | Not specified | Minimum supported Windows release. Accepted: 'W10_1607', 'W10_1703', 'W10_1709', 'W10_1809', 'W10_1909', 'W10_2004', 'W10_20H2', 'W10_21H1', 'W10_21H2', 'W10_22H2', 'W11_21H2', 'W11_22H2'. |
| `-architecture` | `string` | No | Not specified | Architecture for the application (x86, x64, all, arm64). Accepted: 'x86', 'x64', 'all', 'arm64'. |
| `-minimumfreediskspaceinmb` | `int` | No | Not specified | Minimum free disk space in MB. |
| `-minimummemoryinmb` | `int` | No | Not specified | Minimum memory in MB. |
| `-additionalrules` | `object[]` | No | Not specified | File/registry/script requirement objects. Omit to preserve on update; @() clears. API validates the rule schema. Explicit empty collection allowed. |
| `-updaterrules` | `object[]` | No | Not specified | Updater-specific requirement objects. value_source can be literal or published_version. Disable client updater modes before clearing all rules. Explicit empty collection allowed. |
| `-detection_type` | `string` | No | Not specified | Type of detection (msi, registry_version, registry_existence, script). Accepted: 'msi', 'registry_version', 'registry_existence', 'script'. |
| `-detection_scriptfile` | `string` | No | Not specified | Script file for detection. |
| `-detection_enforcesignaturecheck` | `bool` | No | Not specified | Boolean to enforce signature check for detection. |
| `-detection_runas32bit` | `bool` | No | Not specified | Boolean to run detection as 32-bit. |
| `-detection_detectionmethod` | `string` | No | Not specified | Detection method (existence, versionComparison). Accepted: 'existence', 'versionComparison'. |
| `-detection_keypath` | `string` | No | Not specified | Key path for detection. |
| `-detection_valuename` | `string` | No | Not specified | Value name for detection. |
| `-detection_operator` | `string` | No | Not specified | Operator for detection (notConfigured, equals, notEquals, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan). Accepted: 'notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan'. |
| `-detection_productversionoperator` | `string` | No | Not specified | Product version operator for detection (notConfigured, equals, notEquals, greaterThanOrEqual, greaterThan, lessThanOrEqual, lessThan). Accepted: 'notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan'. |
| `-detection_value` | `string` | No | Not specified | Value for detection. |
| `-detection_check32biton64system` | `bool` | No | Not specified | Boolean to check 32-bit on 64-bit system for detection. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Create a local MSI definition

```powershell
$parameters = @{
  name = 'Example App'
  description = 'Example MSI deployment'
  publisher = 'Example Publisher'
  appsource = 'local_storage'
  appsetupfilename = 'example.msi'
  storageaccountcontainername = 'example-app'
  install_type = 'msi'
  uninstall_type = 'msi'
  detection_type = 'msi'
  detection_productversionoperator = 'greaterThanOrEqual'
  installexperience = 'system'
  architecture = 'x64'
  minimumsupportedwindowsrelease = 'W10_22H2'
}
$app = New-AFApplication @parameters
```

## Example 2: Upload the icon after creation

```powershell
Set-AFApplicationIcon -id $app.id -iconpath 'C:\AppFactory\Assets\example.png'
```

## Example 3: Restrict a new definition to a client

```powershell
$parameters.name = 'Example App - Private'
$parameters.publishto = @('<client-uuid>')
New-AFApplication @parameters
```

## Behavior and limits

Although most parameters are locally optional, the API requires information/source/install/uninstall/detection sections and conditional fields. Source files must exist separately. For the local example use <workspace>/LocalStorage/example-app/<version>/example.msi. Empty publish targets mean public catalog/storage publication. Do not use dependson for modern client Intune dependency policy; use New/Set-AFAppConfig -dependencies.

## Output

The created application object; capture id for icon upload and subsequent operations.

## Source

[cmdlets/Public/api/applications/New-AFApplication.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/New-AFApplication.ps1)

