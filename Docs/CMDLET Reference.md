# PowerShell command reference


## Command index

- [PowerShell command reference](#powershell-command-reference)
  - [Command index](#command-index)
  - [Get-AFAppConfig](#get-afappconfig)
  - [New-AFAppConfig](#new-afappconfig)
  - [Remove-AFAppConfig](#remove-afappconfig)
  - [Set-AFAppConfig](#set-afappconfig)
  - [Get-AFApplicationConfigurations](#get-afapplicationconfigurations)
  - [Add-AFApplicationVersion](#add-afapplicationversion)
  - [Get-AFApplications](#get-afapplications)
  - [New-AFApplication](#new-afapplication)
  - [Remove-AFApplication](#remove-afapplication)
  - [Set-AFApplication](#set-afapplication)
  - [Set-AFApplicationConflictingProcess](#set-afapplicationconflictingprocess)
  - [Set-AFApplicationExitCode](#set-afapplicationexitcode)
  - [Set-AFApplicationIcon](#set-afapplicationicon)
  - [Get-AFClient](#get-afclient)
  - [New-AFClient](#new-afclient)
  - [Remove-AFClient](#remove-afclient)
  - [Set-AFClient](#set-afclient)
  - [Get-AFTokenList](#get-aftokenlist)
  - [New-AFToken](#new-aftoken)
  - [Remove-AFToken](#remove-aftoken)
  - [Revoke-AFToken](#revoke-aftoken)
  - [Copy-AFApplicationClientGroups](#copy-afapplicationclientgroups)
  - [Get-AFApplicationClientFiles](#get-afapplicationclientfiles)
  - [Get-AFApplicationInstaller](#get-afapplicationinstaller)
  - [New-AFApplicationPackage](#new-afapplicationpackage)
  - [Publish-AFApplication](#publish-afapplication)
  - [Publish-AFApplicationClientApp](#publish-afapplicationclientapp)
  - [Publish-AFApplicationClientAppNative](#publish-afapplicationclientappnative)
  - [Set-AFApplicationClientESPAssignments](#set-afapplicationclientespassignments)
  - [Set-AFApplicationClientGroups](#set-afapplicationclientgroups)
  - [Set-AFApplicationInstall](#set-afapplicationinstall)
  - [Set-AFApplicationUninstall](#set-afapplicationuninstall)
  - [Test-AFApplicationFiles](#test-afapplicationfiles)
  - [Test-AFApplicationVersion](#test-afapplicationversion)
  - [Get-AFApplicationPublishedVersions](#get-afapplicationpublishedversions)
  - [Import-AFECNOApp](#import-afecnoapp)
  - [Set-AFClientSettings](#set-afclientsettings)
  - [Set-AFSettings](#set-afsettings)
  - [Start-AFClientProcess](#start-afclientprocess)
  - [Start-AFProcess](#start-afprocess)
  - [Get-AFIntuneWin32App](#get-afintunewin32app)
  - [New-AFIntuneFile](#new-afintunefile)
  - [Remove-AFIntuneAppAssignments](#remove-afintuneappassignments)
  - [Remove-AFIntuneWin32App](#remove-afintunewin32app)

## Get-AFAppConfig

Retrieves application configuration from the Application Factory API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Get-AFAppConfig.ps1#L13)

```powershell
Get-AFAppConfig
param(
    [Parameter(Mandatory=$false)][string]$id,
    [Parameter()][bool]$enabled
  )
```

## New-AFAppConfig

Creates a new application configuration via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/New-AFAppConfig.ps1#L59)

```powershell
New-AFAppConfig
param(
    [Parameter(Mandatory = $true)][string]$application,
    [Parameter(Mandatory = $true)][string]$client,
    [Alias("assignmentRequired", "RequiredAssignments")][Parameter()][string[]]$assignment_required,
    [Alias("assignmentRequiredExceptions", "RequiredExceptions")][Parameter()][string[]]$assignment_required_exceptions,
    [Alias("assignmentAvailable", "AvailableAssignments")][Parameter()][string[]]$assignment_available,
    [Alias("assignmentAvailableExceptions", "AvailableExceptions")][Parameter()][string[]]$assignment_available_exceptions,
    [Alias("assignmentUninstall", "UninstallAssignments")][Parameter()][string[]]$assignment_uninstall,
    [Alias("assignmentUninstallExceptions", "UninstallExceptions")][Parameter()][string[]]$assignment_uninstall_exceptions,
    [Alias("AddToIntune")][Parameter()][bool]$enabled = $false,
    [Parameter()][bool]$create_updater_app,
    [Parameter()][AllowEmptyCollection()][object[]]$dependencies,
    [Parameter()][bool]$reconcile_reverse_dependencies,
    [Alias("downloadForeground", "foreground")][Parameter()][bool]$download_foreground = $false,
    [Alias("keepPreviousVersions", "KeepPrevious")][Parameter()][int]$keep_previous_versions = 0,
    [Alias("copyPreviousAssignments", "CopyPrevious")][Parameter()][bool]$copy_previous_assignments = $false,
    [Alias("unassignPreviousAssignments", "UnassignPrevious")][Parameter()][bool]$unassign_previous_assignments = $true,
    [Alias("espAssignments", "espprofiles")][Parameter()][AllowEmptyCollection()][string[]]$esp_assignments,
    [Parameter()][string]$filters,
    [Alias("interactiveInstall")][Parameter()][bool]$interactive_install = $false,
    [Alias("interactiveUninstall")][Parameter()][bool]$interactive_uninstall = $false,
    [Parameter()][string]$versions,
    [Alias("replaceInPlace")][Parameter()][bool]$replace_in_place,
    [Alias("includeVersionInDisplayName")][Parameter()][bool]$include_version_in_display_name = $true
  )
```

## Remove-AFAppConfig

Removes an application configuration via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Remove-AFAppConfig.ps1#L13)

```powershell
Remove-AFAppConfig
param(
    [Parameter(Mandatory=$true)][string]$id
  )
```

## Set-AFAppConfig

Updates an application configuration via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appconfig/Set-AFAppConfig.ps1#L62)

```powershell
Set-AFAppConfig
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter()][string]$application,
    [Parameter()][string]$client,
    [Alias("assignmentRequired")][Parameter()][string[]]$assignment_required,
    [Alias("assignmentRequiredExceptions")][Parameter()][string[]]$assignment_required_exceptions,
    [Alias("assignmentAvailable")][Parameter()][string[]]$assignment_available,
    [Alias("assignmentAvailableExceptions")][Parameter()][string[]]$assignment_available_exceptions,
    [Alias("assignmentUninstall")][Parameter()][string[]]$assignment_uninstall,
    [Alias("assignmentUninstallExceptions")][Parameter()][string[]]$assignment_uninstall_exceptions,
    [Parameter()][bool]$enabled = $false,
    [Parameter()][bool]$create_updater_app,
    [Parameter()][AllowEmptyCollection()][object[]]$dependencies,
    [Parameter()][bool]$reconcile_reverse_dependencies,
    [Alias("downloadForeground")][Parameter()][bool]$download_foreground = $false,
    [Alias("keepPreviousVersions")][Parameter()][int]$keep_previous_versions = 0,
    [Alias("copyPreviousAssignments")][Parameter()][bool]$copy_previous_assignments = $false,
    [Alias("unassignPreviousAssignments")][Parameter()][bool]$unassign_previous_assignments = $true,
    [Alias("espAssignments")][Parameter()][AllowEmptyCollection()][string[]]$esp_assignments,
    [Parameter()][string]$filters,
    [Alias("interactiveInstall")][Parameter()][bool]$interactive_install = $false,
    [Alias("interactiveUninstall")][Parameter()][bool]$interactive_uninstall = $false,
    [Parameter()][string]$versions,
    [Alias("replaceInPlace")][Parameter()][bool]$replace_in_place,
    [Alias("includeVersionInDisplayName")][Parameter()][bool]$include_version_in_display_name = $true
  )
```

## Get-AFApplicationConfigurations

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/appfactory/Get-AFApplicationConfigurations.ps1#L1)

```powershell
Get-AFApplicationConfigurations
param(
    [Parameter(Mandatory=$true)][string]$id,
    [Parameter()][string]$application_id
  )
```

## Add-AFApplicationVersion

Adds a version to an application in the Application Factory API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Add-AFApplicationVersion.ps1#L15)

```powershell
Add-AFApplicationVersion
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter()][string]$versions
  )
```

## Get-AFApplications

Retrieves application details from the Application Factory API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Get-AFApplications.ps1#L13)

```powershell
Get-AFApplications
param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
```

## New-AFApplication

Creates a new application via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/New-AFApplication.ps1#L160)

```powershell
New-AFApplication
param(
    [Parameter()][string]$id,
    [Alias("DisplayName")][Parameter(Mandatory = $false)][string]$name,
    [Parameter(Mandatory = $false)][string]$description,
    [Parameter(Mandatory = $false)][string]$publisher,
    [Parameter()][string]$notes,
    [Parameter()][string]$owner,
    [Alias("informationurl")][Parameter()][string]$information_url,
    [Alias("privacyurl")][Parameter()][string]$privacy_url,
    [Parameter(Mandatory = $false)][ValidateSet('azure_storage', 'winget', 'evergreen', 'sharepoint', 'psadt', 'ecno', 'local_storage')][string]$appsource,
    [Parameter()][string]$appid,
    [Parameter()][string]$appsetupfilename,
    [Parameter()][string]$storageaccountcontainername,
    [Parameter()][string]$filter_architecture,
    [Parameter()][string]$filter_platform,
    [Parameter()][string]$filter_channel,
    [Parameter()][string]$filter_type,
    [Alias("filter_installertype")][Parameter()][string]$filter_installer_type,
    [Parameter()][string]$filter_release,
    [Parameter()][string]$filter_language,
    [Parameter()][string]$filter_imagetype,
    [Parameter()][string]$dependson,
    [Parameter()][bool]$active,
    [Parameter()][datetime]$lastupdate,
    [Parameter()][bool]$pauseupdate,
    [Parameter()][string[]]$publishto,
    [Alias("AppVersion")][Parameter()][string[]]$versions,
    [Parameter(Mandatory = $false)][ValidateSet('none', 'script', 'ecno', 'exe', 'msi')][string]$install_type,
    [Parameter()][string]$install_argumentList,
    [Parameter()][string]$install_additionalArgumentList,
    [Parameter()][bool]$install_secureArgumentList,
    [Parameter()][string]$install_installer,
    [Parameter()][string]$install_transforms,
    [Parameter()][bool]$install_SkipMSIAlreadyInstalledCheck,
    [Parameter()][string]$install_script,
    [Parameter()][bool]$install_wim,
    [Parameter()][string]$install_successExitCodes,
    [Parameter()][string[]]$install_rebootExitCodes,
    [Parameter()][string[]]$install_ignoreExitCodes,
    [Parameter()][string[]]$install_conflictingProcessStart,
    [Parameter()][string[]]$install_conflictingProcessEnd,
    [Parameter(Mandatory = $false)][ValidateSet('none', 'msi', 'exe', 'name', 'guid', 'ecno', 'script')][string]$uninstall_type,
    [Alias("uninstall_name")][Parameter()][string]$uninstall_namematch,
    [Parameter()][string]$uninstall_productcode,
    [Parameter()][string]$uninstall_filterscript,
    [Parameter()][string]$uninstall_argumentlist,
    [Parameter()][string]$uninstall_additionalargumentlist,
    [Parameter()][bool]$uninstall_secureargumentlist,
    [Parameter()][string]$uninstall_script,
    [Parameter()][string]$uninstall_installer,
    [Parameter()][bool]$uninstall_wim,
    [Parameter()][bool]$uninstall_dirfiles,
    [Parameter()][string[]]$uninstall_ignoreexitcodes,
    [Parameter()][string[]]$uninstall_conflictingprocessstart,
    [Parameter()][string[]]$uninstall_conflictingprocessend,
    [Parameter()][ValidateSet('user', 'system')][string]$installexperience,
    [Parameter()][ValidateSet('suppress', 'force', 'basedOnReturnCode', 'allow')][string]$devicerestartbehavior,
    [Parameter()][bool]$allowavailableuninstall,
    [Parameter()][ValidateSet('W10_1607', 'W10_1703', 'W10_1709', 'W10_1809', 'W10_1909', 'W10_2004', 'W10_20H2', 'W10_21H1', 'W10_21H2', 'W10_22H2', 'W11_21H2', 'W11_22H2')][string]$minimumsupportedwindowsrelease,
    [Parameter()][ValidateSet('x86', 'x64', 'all', 'arm64')][string]$architecture,
    [Parameter()][int]$minimumfreediskspaceinmb,
    [Parameter()][int]$minimummemoryinmb,
    [Parameter()][AllowEmptyCollection()][object[]]$additionalrules,
    [Parameter()][AllowEmptyCollection()][object[]]$updaterrules,
    [Parameter(Mandatory = $false)][ValidateSet('msi', 'registry_version', 'registry_existence', 'script')][string]$detection_type,
    [Parameter()][string]$detection_scriptfile,
    [Parameter()][bool]$detection_enforcesignaturecheck,
    [Parameter()][bool]$detection_runas32bit,
    [Parameter()][ValidateSet('existence', 'versionComparison')][string]$detection_detectionmethod,
    [Parameter()][string]$detection_keypath,
    [Parameter()][string]$detection_valuename,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_operator,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_productversionoperator,
    [Parameter()][string]$detection_value,
    [Parameter()][bool]$detection_check32biton64system
  )
```

## Remove-AFApplication

Removes an application from the Application Factory API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Remove-AFApplication.ps1#L13)

```powershell
Remove-AFApplication
param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id
  )
```

## Set-AFApplication

Updates an application via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplication.ps1#L162)

```powershell
Set-AFApplication
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter()][string]$name,
    [Parameter()][string]$description,
    [Parameter()][string]$publisher,
    [Parameter()][string]$notes,
    [Parameter()][string]$owner,
    [Parameter()][string]$information_url,
    [Parameter()][string]$privacy_url,
    [Parameter()][ValidateSet('azure_storage', 'winget', 'evergreen', 'sharepoint', 'psadt', 'ecno', 'local_storage')][string]$appsource,
    [Parameter()][string]$appid,
    [Parameter()][string]$appsetupfilename,
    [Parameter()][string]$storageaccountcontainername,
    [Parameter()][string]$filter_architecture,
    [Parameter()][string]$filter_platform,
    [Parameter()][string]$filter_channel,
    [Parameter()][string]$filter_type,
    [Parameter()][string]$filter_installer_type,
    [Parameter()][string]$filter_release,
    [Parameter()][string]$filter_language,
    [Parameter()][string]$filter_imagetype,
    [Parameter()][string]$dependson,
    [Parameter()][bool]$active,
    [Parameter()][datetime]$lastupdate,
    [Parameter()][bool]$pauseupdate,
    [Parameter()][string[]]$publishto,
    [Parameter()][string]$versions,
    [Parameter()][ValidateSet('none', 'script', 'powershell', 'ecno', 'exe', 'msi')][string]$install_type,
    [Parameter()][string]$install_argumentList,
    [Parameter()][string]$install_additionalArgumentList,
    [Parameter()][bool]$install_secureArgumentList,
    [Parameter()][string]$install_installer,
    [Parameter()][string]$install_transforms,
    [Parameter()][bool]$install_SkipMSIAlreadyInstalledCheck,
    [Parameter()][string]$install_script,
    [Parameter()][bool]$install_wim,
    [Parameter()][string]$install_successExitCodes,
    [Parameter()][string[]]$install_rebootExitCodes,
    [Parameter()][string[]]$install_ignoreExitCodes,
    [Parameter()][string[]]$install_conflictingProcessStart,
    [Parameter()][string[]]$install_conflictingProcessEnd,
    [Parameter()][ValidateSet('none', 'msi', 'exe', 'name', 'guid', 'ecno', 'script', 'powershell')][string]$uninstall_type,
    [Parameter()][string]$uninstall_name,
    [Parameter()][string]$uninstall_namematch,
    [Parameter()][string]$uninstall_productcode,
    [Parameter()][string]$uninstall_filterscript,
    [Parameter()][string]$uninstall_argumentlist,
    [Parameter()][string]$uninstall_additionalargumentlist,
    [Parameter()][bool]$uninstall_secureargumentlist,
    [Parameter()][string]$uninstall_script,
    [Parameter()][string]$uninstall_installer,
    [Parameter()][bool]$uninstall_wim,
    [Parameter()][bool]$uninstall_dirfiles,
    [Parameter()][string[]]$uninstall_ignoreexitcodes,
    [Parameter()][string[]]$uninstall_conflictingprocessstart,
    [Parameter()][string[]]$uninstall_conflictingprocessend,
    [Parameter()][ValidateSet('user', 'system')][string]$installeexperience,
    [Parameter()][ValidateSet('suppress', 'force', 'basedOnReturnCode', 'allow')][string]$devicerestartbehavior,
    [Parameter()][bool]$allowavailableuninstall,
    [Parameter()][ValidateSet('W10_1607', 'W10_1703', 'W10_1709', 'W10_1809', 'W10_1909', 'W10_2004', 'W10_20H2', 'W10_21H1', 'W10_21H2', 'W10_22H2', 'W11_21H2', 'W11_22H2')][string]$minimumsupportedwindowsrelease,
    [Parameter()][ValidateSet('x86', 'x64', 'all', 'arm64')][string]$architecture,
    [Parameter()][int]$minimumfreediskspaceinmb,
    [Parameter()][int]$minimummemoryinmb,
    [Parameter()][AllowEmptyCollection()][object[]]$additionalrules,
    [Parameter()][AllowEmptyCollection()][object[]]$updaterrules,
    [Parameter()][ValidateSet('msi', 'registry_version', 'registry_existence', 'script')][string]$detection_type,
    [Parameter()][string]$detection_scriptfile,
    [Parameter()][bool]$detection_enforcesignaturecheck,
    [Parameter()][bool]$detection_runas32bit,
    [Parameter()][ValidateSet('existence', 'versionComparison')][string]$detection_detectionmethod,
    [Parameter()][string]$detection_keypath,
    [Parameter()][string]$detection_valuename,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_operator,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_productversionoperator,
    [Parameter()][string]$detection_value,
    [Parameter()][bool]$detection_check32biton64system
  )
```

## Set-AFApplicationConflictingProcess

Updates conflicting processes for an application via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplicationConflictingProcess.ps1#L21)

```powershell
Set-AFApplicationConflictingProcess
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('start', 'end')][string]$type,
    [Parameter(Mandatory = $true)][string]$process
  )
```

## Set-AFApplicationExitCode

Updates exit codes for an application via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplicationExitCode.ps1#L21)

```powershell
Set-AFApplicationExitCode
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][ValidateSet('add', 'remove')][string]$action,
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$section,
    [Parameter(Mandatory = $true)][ValidateSet('ignore', 'reboot', 'success')][string]$type,
    [Parameter(Mandatory = $true)][int]$exitcode
  )
```

## Set-AFApplicationIcon

Uploads an icon for an application via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/applications/Set-AFApplicationIcon.ps1#L15)

```powershell
Set-AFApplicationIcon
param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][string]$iconpath
  )
```

## Get-AFClient

Retrieves client information via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/Get-AFClient.ps1#L13)

```powershell
Get-AFClient
param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
```

## New-AFClient

Creates a new client via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/New-AFClient.ps1#L17)

```powershell
New-AFClient
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$name,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
  )
```

## Remove-AFClient

Removes a client via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/Remove-AFClient.ps1#L13)

```powershell
Remove-AFClient
param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id
  )
```

## Set-AFClient

Updates a client via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/clients/Set-AFClient.ps1#L15)

```powershell
Set-AFClient
param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
  )
```

## Get-AFTokenList

Retrieves the list of tokens via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/Get-AFTokenList.ps1#L11)

```powershell
Get-AFTokenList
param()
```

## New-AFToken

Creates a new token via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/New-AFToken.ps1#L15)

```powershell
New-AFToken
param(
    [parameter(Mandatory = $true)][string]$name,
    [parameter(Mandatory = $true)][datetime]$expires_at
  )
```

## Remove-AFToken

Removes a token via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/Remove-AFToken.ps1#L13)

```powershell
Remove-AFToken
param(
    [parameter(Mandatory = $true)][string]$prefix
  )
```

## Revoke-AFToken

Revokes a token via API.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/api/tokens/Revoke-AFToken.ps1#L13)

```powershell
Revoke-AFToken
param(
    [parameter(Mandatory = $true)][string]$prefix
  )
```

## Copy-AFApplicationClientGroups

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Copy-AFApplicationClientGroups.ps1#L1)

```powershell
Copy-AFApplicationClientGroups
param(
    [Parameter(Mandatory)]$intune_apps,
    [Parameter(Mandatory)][PSCustomObject]$configuration
  )
```

## Get-AFApplicationClientFiles

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Get-AFApplicationClientFiles.ps1#L1)

```powershell
Get-AFApplicationClientFiles
param(  
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$configuration
  )
```

## Get-AFApplicationInstaller

Retrieves and downloads the installer for a given application version.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Get-AFApplicationInstaller.ps1#L17)

```powershell
Get-AFApplicationInstaller
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion   
  )
```

## New-AFApplicationPackage

Creates a new application package using PSADT templates and application metadata.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/New-AFApplicationPackage.ps1#L17)

```powershell
New-AFApplicationPackage
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion      
  )
```

## Publish-AFApplication

Publishes an application package and uploads related files to storage containers.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplication.ps1#L17)

```powershell
Publish-AFApplication
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][switch]$TestMode     
  )
```

## Publish-AFApplicationClientApp

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplicationClientApp.ps1#L1)

```powershell
Publish-AFApplicationClientApp
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [PSCustomObject]$configuration,
    [switch]$UseNativeUpload = $true,
    [ValidateSet("Auto", "Native", "AzCopy")]
    [string]$UploadTransport = "Auto",
    [string]$AzCopyPath,
    [string]$ExistingAppId,
    [string]$ExpectedDisplayVersion,
    [string]$ExpectedContentVersion
  )
```

## Publish-AFApplicationClientAppNative

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Publish-AFApplicationClientAppNative.ps1#L1)

```powershell
Publish-AFApplicationClientAppNative
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][PSCustomObject]$Configuration,
    [ValidateSet("Auto", "Native", "AzCopy")][string]$UploadTransport = "Auto",
    [string]$AzCopyPath,
    [ValidateRange(300, 86400)][int]$UploadTimeoutSeconds = 21600,
    [ValidateRange(30, 3600)][int]$ProcessingTimeoutSeconds = 900,
    [string]$ExistingAppId,
    [string]$ExpectedDisplayVersion,
    [string]$ExpectedContentVersion
  )
```

## Set-AFApplicationClientESPAssignments

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationClientESPAssignments.ps1#L1)

```powershell
Set-AFApplicationClientESPAssignments
param(
    [Parameter(Mandatory)][PSCustomObject]$configuration
  )
```

## Set-AFApplicationClientGroups

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationClientGroups.ps1#L1)

```powershell
Set-AFApplicationClientGroups
param(
    [Parameter(Mandatory)][PSCustomObject]$configuration,
    [Parameter()]$Plan
  )
```

## Set-AFApplicationInstall

Sets the installation script for an application package.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationInstall.ps1#L15)

```powershell
Set-AFApplicationInstall
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application      
  )
```

## Set-AFApplicationUninstall

Sets the uninstallation script for an application package.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Set-AFApplicationUninstall.ps1#L15)

```powershell
Set-AFApplicationUninstall
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application    
  )
```

## Test-AFApplicationFiles

Tests the application object for required file properties.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Test-AFApplicationFiles.ps1#L15)

```powershell
Test-AFApplicationFiles
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application
  )
```

## Test-AFApplicationVersion

Tests and retrieves the current version of an application from its source.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/applications/Test-AFApplicationVersion.ps1#L17)

```powershell
Test-AFApplicationVersion
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][switch]$force
  )
```

## Get-AFApplicationPublishedVersions

Retrieves published application versions from storage containers.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Get-AFApplicationPublishedVersions.ps1#L13)

```powershell
Get-AFApplicationPublishedVersions
param(
  )
```

## Import-AFECNOApp

Imports an ECNO application and creates a new application object from its configuration.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Import-AFECNOApp.ps1#L23)

```powershell
Import-AFECNOApp
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$applicationName,
    [Parameter()][String[]]$publishTo = @(),
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel = "Verbose"
  )
```

## Set-AFClientSettings

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFClientSettings.ps1#L1)

```powershell
Set-AFClientSettings
param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $false)][string]$Workspace = $PSScriptRoot,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel
  )
```

## Set-AFSettings

Sets Application Factory configuration and environment variables.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFSettings.ps1#L17)

```powershell
Set-AFSettings
param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $false)][string]$Workspace = $PSScriptRoot,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel
  )
```

## Start-AFClientProcess

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Start-AFClientProcess.ps1#L1)

```powershell
Start-AFClientProcess
param(
    [Parameter(Mandatory)][string]$configFile,
    [Parameter(Mandatory)][string]$workspace,
    [string]$application_name,
    [switch]$EnableLogging,
    [string]$LogLevel = "Verbose",
    [switch]$Force,
    [switch]$DownloadOnly,

    [switch]$UseNativeUpload = $true,
    [ValidateSet("Auto", "Native", "AzCopy")][string]$UploadTransport = "Auto",
    [string]$AzCopyPath,

    [switch]$SkipPreviousVersionCleanup,
    [string]$ResumePublishedAppId
  )
```

## Start-AFProcess

Starts the application factory process for all configured applications.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Start-AFProcess.ps1#L23)

```powershell
Start-AFProcess
param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][string]$application_id,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel = "Verbose",
    [Parameter()][switch]$Force,
    [Parameter()][switch]$TestMode
  )
```

## Get-AFIntuneWin32App

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/Get-AFIntuneWin32App.ps1#L1)

```powershell
Get-AFIntuneWin32App
param(
    [Parameter(Mandatory = $true, ParameterSetName = "Id")]
    [ValidateNotNullOrEmpty()][string]$Id,
    [Parameter(Mandatory = $true, ParameterSetName = "DisplayName")][ValidateNotNullOrEmpty()][string]$DisplayName,
    [Parameter()][switch]$Failed
  )
```

## New-AFIntuneFile

Creates an Intune Win32 application package file for the application.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/New-AFIntuneFile.ps1#L15)

```powershell
New-AFIntuneFile
param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application  
  )
```

## Remove-AFIntuneAppAssignments

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/Remove-AFIntuneAppAssignments.ps1#L1)

```powershell
Remove-AFIntuneAppAssignments
param(
    [Parameter(Mandatory)][guid]$Id,
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version,
    [ValidateSet("normal", "updater")][string]$ApplicationRole = "normal",
    [string]$ProtectedAppId = [string]$script:published_application.id,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )
```

## Remove-AFIntuneWin32App

See source and workflow guides for behavior.

[Source declaration](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/intune/Remove-AFIntuneWin32App.ps1#L1)

```powershell
Remove-AFIntuneWin32App
param(
    [Parameter(Mandatory)][guid]$Id,
    [Parameter(Mandatory)][string]$ApplicationId,
    [Parameter(Mandatory)][string]$Version,
    [ValidateSet("normal", "updater")][string]$ApplicationRole = "normal",
    [string]$ProtectedAppId = [string]$script:published_application.id,
    [ValidateRange(0, 600)][int]$TimeoutSeconds = 120
  )
```