# Application.Factory cmdlet help — 0.2.0

Individual Markdown help files for **all 44 Public cmdlets**, with 310 declared parameters documented and 109 worked invocation examples. This is file-based operator/developer help; it does not install PowerShell Get-Help/MAML or change module source.

Source baseline: [module 232b6b3](https://github.com/jeremyputman/Application.Factory--New-/tree/232b6b3e2a61ec5ece934a6534c402843afa335d) and [webapp 67bfe66](https://github.com/jeremyputman/application-factory-webapp/tree/67bfe66cd68a825e24a5429d7b48b71391d527c8), both inspected on the 0.2.0 branch. Examples are source-checked drafts, not live execution results.

Start with [configuration and prerequisites](configuration.md). For the requested run options, see [Start-AFClientProcess](Start-AFClientProcess.md): one app, all enabled apps, logging, download-only, Auto/AzCopy/Native transfers, cleanup control, intentional force, resume, and result capture.

## Two publishing stages

- [Start-AFProcess](Start-AFProcess.md) builds deployment packages and publishes assets to Azure storage.
- [Start-AFClientProcess](Start-AFClientProcess.md) consumes those assets and publishes/manages Intune applications.

The package command supports TestMode. The client command supports DownloadOnly and requires PowerShell >=7.5 on Windows. They are different modes with different side effects.

## Start here

- [Start-AFClientProcess](Start-AFClientProcess.md) — Publish versioned packages from Azure storage into a client's Intune tenant, then verify dependencies, assignments, ESP selections, and eligible cleanup.
- [Start-AFProcess](Start-AFProcess.md) — Discover installer versions, build packages, and publish package assets to Azure storage.
- [Set-AFClientSettings](Set-AFClientSettings.md) — Load client publishing configuration, storage read SAS tokens, and Graph application credentials into module state.
- [Set-AFSettings](Set-AFSettings.md) — Load package-service configuration, API authentication, storage/source settings, and optional logging into module state.

## Applications and versions

- [Add-AFApplicationVersion](Add-AFApplicationVersion.md) — Register a raw version against a shared catalog application.
- [Get-AFApplications](Get-AFApplications.md) — Read shared application definitions visible to the API user.
- [New-AFApplication](New-AFApplication.md) — Create a shared catalog definition through the nested application API.
- [Remove-AFApplication](Remove-AFApplication.md) — Delete a shared application definition from AppFactory.
- [Set-AFApplication](Set-AFApplication.md) — Patch catalog metadata or deployment settings on a shared application.
- [Set-AFApplicationConflictingProcess](Set-AFApplicationConflictingProcess.md) — Add or remove a process name in an application's conflicting-process policy.
- [Set-AFApplicationExitCode](Set-AFApplicationExitCode.md) — Add or remove one application exit code through the action API.
- [Set-AFApplicationIcon](Set-AFApplicationIcon.md) — Upload an application's icon as multipart form data.

## Client configuration

- [Get-AFAppConfig](Get-AFAppConfig.md) — Read saved client application configurations.
- [New-AFAppConfig](New-AFAppConfig.md) — Create the desired publication settings for one application/client pair.
- [Remove-AFAppConfig](Remove-AFAppConfig.md) — Delete a saved application/client configuration from AppFactory.
- [Set-AFAppConfig](Set-AFAppConfig.md) — Patch selected fields on an existing client application configuration.
- [Get-AFApplicationConfigurations](Get-AFApplicationConfigurations.md) — Read enabled client configurations in the shape consumed by the Intune publishing process.

## Clients

- [Get-AFClient](Get-AFClient.md) — Read accessible AppFactory client records.
- [New-AFClient](New-AFClient.md) — Create an AppFactory client and its package-storage container.
- [Remove-AFClient](Remove-AFClient.md) — Delete an AppFactory client and its Azure package container.
- [Set-AFClient](Set-AFClient.md) — Update a client's assigned AppFactory access groups.

## API tokens

- [Get-AFTokenList](Get-AFTokenList.md) — List API tokens owned by the authenticated user.
- [New-AFToken](New-AFToken.md) — Create a new API token for the authenticated user.
- [Remove-AFToken](Remove-AFToken.md) — Delete one of the current user's API token records.
- [Revoke-AFToken](Revoke-AFToken.md) — Disable an API token by setting revoked_at.

## Package and publication helpers

- [Copy-AFApplicationClientGroups](Copy-AFApplicationClientGroups.md) — Copy assignment bodies from a previous Intune application to the current published application.
- [Get-AFApplicationClientFiles](Get-AFApplicationClientFiles.md) — Download a client application's versioned package assets from package storage.
- [Get-AFApplicationInstaller](Get-AFApplicationInstaller.md) — Retrieve installer files for a source version into the working installer directory.
- [New-AFApplicationPackage](New-AFApplicationPackage.md) — Create and customize a PSADT deployment folder using application metadata and installer assets.
- [Publish-AFApplication](Publish-AFApplication.md) — Publish prepared package assets to Azure storage and register the version in AppFactory.
- [Publish-AFApplicationClientApp](Publish-AFApplicationClientApp.md) — Invoke the native Intune publisher using an initialized client publication context.
- [Publish-AFApplicationClientAppNative](Publish-AFApplicationClientAppNative.md) — Upload and commit Win32 application content using native Graph/content APIs.
- [Set-AFApplicationClientESPAssignments](Set-AFApplicationClientESPAssignments.md) — Add the current published application to selected Windows enrollment status pages and verify membership.
- [Set-AFApplicationClientGroups](Set-AFApplicationClientGroups.md) — Apply and verify the assignment plan for the current published application.
- [Set-AFApplicationInstall](Set-AFApplicationInstall.md) — Generate installer behavior and insert it into the prepared PSADT deployment script.
- [Set-AFApplicationUninstall](Set-AFApplicationUninstall.md) — Generate uninstall behavior and insert it into the prepared PSADT deployment script.
- [Test-AFApplicationFiles](Test-AFApplicationFiles.md) — Check that application metadata supplies an icon URL before packaging.
- [Test-AFApplicationVersion](Test-AFApplicationVersion.md) — Discover the source version and decide whether package storage needs that version.
- [Get-AFApplicationPublishedVersions](Get-AFApplicationPublishedVersions.md) — Load the module's cached inventory of versioned .intunewin files from package storage.
- [Import-AFECNOApp](Import-AFECNOApp.md) — Read an ECNO package's metadata and create a catalog application with its icon.
- [Get-AFIntuneWin32App](Get-AFIntuneWin32App.md) — Read AppFactory-marked Win32 apps from the initialized destination Intune tenant.
- [New-AFIntuneFile](New-AFIntuneFile.md) — Package a prepared PSADT deployment tree into an .intunewin file.
- [Remove-AFIntuneAppAssignments](Remove-AFIntuneAppAssignments.md) — Remove assignments from one verified managed Intune application.
- [Remove-AFIntuneWin32App](Remove-AFIntuneWin32App.md) — Delete one verified AppFactory-managed Intune Win32 application.

## How to read a help page

Each page includes prerequisites, invocation syntax, a parameter table, examples, behavior/limits, output, and a pinned source link. Examples use placeholder IDs and paths. Lower-level helper pages explicitly describe the initialized module context they need; use the Start commands for routine operator workflows.

Local mandatory flags/defaults do not override server validation. API wrappers generally submit only bound arguments. Creation examples explicitly bind enabled to avoid the known API/wrapper default mismatch. Structured assignment filters currently require the web editor or direct API rather than the legacy filters parameter.

Only Remove-AFIntuneAppAssignments and Remove-AFIntuneWin32App among these Public commands declare SupportsShouldProcess. Their WhatIf/Confirm options are documented. Other mutating commands should not be assumed to have those modes.

Private implementation helpers and bundled PSAppDeployToolkit commands are not included as independently supported public AppFactory cmdlets. Both GitHub repositories remain unchanged.

