# Configuration and prerequisites

These examples explain the JSON fields consumed by the pinned module. Replace placeholders with deployment values. The code review did not install dependencies, register vaults, build packages, or publish into a tenant.

## Import and common paths

```powershell
Import-Module 'C:\AppFactory\Module\Application.Factory\Application.Factory.psd1' -Force
$packageConfig = 'C:\AppFactory\Settings\package.json'
$clientConfig = 'C:\AppFactory\Settings\client.json'
$workspace = 'C:\AppFactory\Run'
```

Use the built module, including Templates and SupportFiles. The build script defaults to version 0.2.0; the source manifest's older version label is not a reliable installed-version check. Use separate workspaces for independent jobs/clients. Package commands recreate local work trees; the client process locks its WorkingFolder against concurrent runs.

Client publication requires **PowerShell 7.5 or later on Windows**. Package providers need their source-specific tools as well. The manifest does not enumerate every dependency. Observed external commands include Get-Secret, PSFramework logging, Azure storage commands, and source-provider commands such as Get-EvergreenApp. Confirm these in the actual runner account's environment.

## Package-service JSON

Save a file such as package.json:

```json
{
  "api": {
    "url": "https://appfactory.example/",
    "key": "appfactory-service-token"
  },
  "keyvault_name": "registered-secret-vault",
  "client_key": "slug",
  "application_key": "guid",
  "storage": {
    "public": "public",
    "installers": "installerstorage",
    "packages": "packagestorage"
  },
  "sharepoint": {
    "tenant": "",
    "clientId": "",
    "sharepointsite": "",
    "sharepointurl": "",
    "certificateFile": "",
    "certificateSecret": "",
    "versionField": "",
    "documentLibrary": ""
  }
}
```

api.key is a **vault secret name**, not a raw API token. keyvault_name identifies a vault registered for Get-Secret. The runner account must already have access to that provider/vault. storage.packages identifies the package account and the vault secret holding its storage key. SharePoint fields depend on the selected adapter.

Keep the trailing slash on api.url: wrappers append api/v1. Package processing needs admin-group API access because it reads sourcefiles and updates version/lastupdate metadata.

The example includes client_key/application_key, which are read by the module but omitted from its sample JSON. Coordinate them with the deployed webapp. Public inventory hardcodes public; the example uses that literal container. Django's client UUID container branch checks id while package code checks guid, so verify naming before adopting UUID client containers. The slug example avoids that mismatch; application_key guid still needs agreement with the webapp's APPLICATION_KEY.

```powershell
Set-AFSettings -configFile $packageConfig -Workspace $workspace
Get-AFApplications
Get-AFClient
```

## Client-publisher JSON

Save a separate client.json:

```json
{
  "api": {
    "url": "https://appfactory.example/",
    "key": "appfactory-client-token",
    "client": "<appfactory-client-uuid>"
  },
  "keyvault_name": "registered-secret-vault",
  "retries": 3,
  "prefix": "Pilot - ",
  "appregistration": {
    "tenantID": "<destination-tenant-uuid>",
    "clientID": "<graph-app-registration-uuid>",
    "secret": "graph-client-secret"
  }
}
```

api.client is an AppFactory client record UUID. appregistration.clientID is the Graph application registration, and tenantID is the destination tenant. appregistration.secret is a vault secret name. These three IDs are not interchangeable.

The API user needs the configured AppFactory user/admin group and client/application visibility. Graph credentials require the tenant's consent/permissions for the chosen app, assignment, group, filter, and ESP operations. Exact minimal permission provisioning remains deployment-specific.

Set-AFClientSettings fetches two-hour read/list SAS tokens from the webapp and loads the Graph secret. Graph helpers obtain an access token on demand. The high-level Start-AFClientProcess calls this initializer itself.

```powershell
Set-AFClientSettings -configFile $clientConfig -Workspace $workspace
Get-AFApplicationConfigurations -id '<appfactory-client-uuid>'
```

## Object context for package helper examples

Where a low-level page uses $app and $version, obtain them in the same initialized session:

```powershell
Set-AFSettings -configFile $packageConfig -Workspace $workspace
$app = Get-AFApplications -id '<application-uuid>'
$version = Test-AFApplicationVersion -Application $app -force
if (-not $app -or -not $version) { throw 'Application/source version is unavailable.' }
```

CurrentVersion means this source discovery object (Version and URI); it is not a catalog Release record. File-generation helpers need installer files and a fresh package tree in the correct order. Prefer Start-AFProcess to coordinate that order.

## Object context for client helper examples

A client helper's configuration object comes from Get-AFApplicationConfigurations, not Get-AFAppConfig. The complete publishing context also includes module-private selected version, downloaded App.json, published application/status, and credentials. Those are initialized by the orchestration path.

Direct helper invocations are shown for maintainers working inside that module context. Do not set ordinary caller $script: variables and assume they initialize the imported module. For downloads use Start-AFClientProcess -DownloadOnly; for tenant publication use Start-AFClientProcess.

## Logging

EnableLogging enables module calls and configures the PSFramework logfile provider. LogLevel selects the routine message level; explicit errors/warnings keep theirs. Use EnableLogging together with LogLevel Output for normal operator-facing messages; Verbose level should include the common -Verbose parameter. Host visibility remains subject to PSFramework configuration.

Package logs: <workspace>/Logs/AppFactoryService-%Date%.csv. Client logs: <workspace>/Logs/AppFactoryClient-%Date%.csv. The provider expands the date placeholder. Preserve client journals after failures and avoid disclosing tokens, secrets, or SAS URLs.

## Baseline limits worth knowing

- Client publishing has no TestMode or WhatIf; DownloadOnly still performs API/storage reads and local writes.
- Force is an intentional republish/rebuild option, not a bypass for unfinished journals.
- Config versions expects a Release UUID; Add-AFApplicationVersion accepts a raw version string.
- Configuration assignment filters are available in the web/direct API, but no structured filter parameter exists in the current wrapper.
- Configuration enabled should be explicitly bound during creation: omission inherits the server's true default.
- End conflicting-process actions, exitcode 0 PATCH, and Set-AFApplication install-experience mapping have source mismatches documented on the relevant pages.

Sources: [package settings](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFSettings.ps1), [client settings](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Set-AFClientSettings.ps1), [client process](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Start-AFClientProcess.ps1).

