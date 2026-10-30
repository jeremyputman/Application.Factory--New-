# Start-AFClientProcess

Publish versioned packages from Azure storage into a client's Intune tenant, then verify dependencies, assignments, ESP selections, and eligible cleanup.

## Prerequisites

Use PowerShell 7.5 or later on Windows. Import the built module and prepare the client JSON, enabled client configuration, package storage assets, secret-vault access, and destination Graph consent. This function initializes client settings itself.

Examples use `$packageConfig = 'C:\AppFactory\Settings\package.json'`, `$clientConfig = 'C:\AppFactory\Settings\client.json'`, and `$workspace = 'C:\AppFactory\Run'` where relevant. Replace example paths/IDs/names. For explicit per-client isolation choose a separate workspace. [Configuration formats](configuration.md).

## Syntax

```powershell
Start-AFClientProcess -configFile <string> -workspace <string> [-application_name <string>] [-EnableLogging] [-LogLevel <string>] [-Force] [-RetryFailed] [-DownloadOnly] [-UseNativeUpload] [-UploadTransport <string>] [-AzCopyPath <string>] [-SkipPreviousVersionCleanup] [-ResumePublishedAppId <string>] [<CommonParameters>]
```

## Parameters

| Parameter | Type | Required locally | Declared default | Use and constraints |
| --- | --- | --- | --- | --- |
| `-configFile` | `string` | Yes | Not specified | Path to the JSON configuration file. Start/Set-AFSettings use package-service JSON; Start/Set-AFClientSettings use client-publisher JSON. |
| `-workspace` | `string` | Yes | Not specified | Base working directory. Helpers create/use WorkingFolder and Logs beneath it. Supply an explicit operator-owned path. |
| `-application_name` | `string` | No | Not specified | One AppFactory application UUID or slugified name. Omit to select all enabled configurations for the configured client. |
| `-EnableLogging` | `switch` | No | False | Enable module log messages and configure its PSFramework file provider. |
| `-LogLevel` | `string` | No | `"Verbose"` | Default PSFramework level for routine messages. Use Output for normal operator-facing messages, or Verbose together with -Verbose. Does not itself enable logging. |
| `-Force` | `switch` | No | False | Bypass the usual already-processed version decision. In the client process this can create a duplicate same-version app or replace content; it does not bypass unfinished journals. |
| `-RetryFailed` | `switch` | No | False | Recover failed journals for current enabled configurations: resume published apps, or retry confirmed-missing create attempts. Preserve original journals and skip previous-version cleanup. Cannot combine with Force, DownloadOnly, or ResumePublishedAppId. |
| `-DownloadOnly` | `switch` | No | False | Download package assets without the normal Graph publication/assignment/cleanup workflow. Still loads API/SAS settings and writes local files. |
| `-UseNativeUpload` | `switch` | No | `$true` | Retired-route compatibility switch. Keep true/default; false is rejected. AzCopy is selected separately with UploadTransport. |
| `-UploadTransport` | `string` | No | `"Auto"` | Byte-transfer selection: Auto, Native, or AzCopy. Auto can choose AzCopy for encrypted payloads >=100MB when available. Accepted: "Auto", "Native", "AzCopy". |
| `-AzCopyPath` | `string` | No | Not specified | Path to azcopy.exe. When omitted, a non-Native transport can search PATH. Explicit AzCopy must find an executable. |
| `-SkipPreviousVersionCleanup` | `switch` | No | False | Skip previous-app cleanup for this run. New app publication, dependencies, and assignments still occur. |
| `-ResumePublishedAppId` | `string` | No | Not specified | Exact already-published Intune app ID to validate and resume. Requires one selected configuration and compatible saved state; cannot combine with Force/DownloadOnly. |

“Required locally” describes the parameter declaration. API/server/context requirements can be stricter. A declared default is not proof it is sent: API wrappers generally submit only explicitly bound parameters.

## Example 1: Publish one application by AppFactory UUID

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name '<appfactory-application-uuid>'
```

## Example 2: Publish one application by slug or name

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app'
```

## Example 3: Publish all enabled applications for the configured client

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace
```

## Example 4: Show normal log messages and write the client log file

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -EnableLogging -LogLevel Output
```

## Example 5: Use verbose-level messages

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -EnableLogging -LogLevel Verbose -Verbose
```

## Example 6: Download one application's files without Intune publication

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -DownloadOnly -EnableLogging -LogLevel Output
```

## Example 7: Let Auto select AzCopy or native block transfer

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -UploadTransport Auto `
  -EnableLogging -LogLevel Output
```

## Example 8: Explicitly use AzCopy from a known path

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -UploadTransport AzCopy `
  -AzCopyPath 'C:\Tools\AzCopy\azcopy.exe' -EnableLogging -LogLevel Output
```

## Example 9: Use AzCopy found on PATH

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -UploadTransport AzCopy `
  -EnableLogging -LogLevel Output
```

## Example 10: Use native block transfer only

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -UploadTransport Native `
  -EnableLogging -LogLevel Output
```

## Example 11: Publish while retaining all prior applications for review

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -SkipPreviousVersionCleanup `
  -EnableLogging -LogLevel Output
```

## Example 12: Force an intentional same-version republish

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name 'example-app' -Force -EnableLogging -LogLevel Output
```

## Example 13: Resume a validated, already-published application

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -application_name '<appfactory-application-uuid>' `
  -ResumePublishedAppId '<already-published-intune-app-uuid>' `
  -EnableLogging -LogLevel Output
```

## Example 14: Preserve emitted result objects even when the final aggregate error is thrown

```powershell
$captured = [System.Collections.Generic.List[object]]::new()
try {
  Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
    -EnableLogging -LogLevel Output |
    ForEach-Object { $captured.Add($_) }
}
catch {
  Write-Warning $_.Exception.Message
}
$captured | Format-Table Application, Role, Version, State, AppId
$captured | Where-Object State -eq 'Failed' |
  Select-Object Application, Stage, Error, JournalPath
```

## Example 15: Retry failed applications as a batch

```powershell
Start-AFClientProcess -configFile $clientConfig -workspace $workspace `
  -RetryFailed -EnableLogging -LogLevel Output
```

Add `-application_name '<appfactory-application-uuid>'` to limit recovery to one application. Keep the original workspace and client configuration.

RetryFailed processes only saved `State=Failed` attempts for the current configured version and enabled publication roles. Completed and unattempted configurations return `Skipped` with `Operation=RetryNotRequired`. Older unfinished versions still block processing and must be inspected; the switch does not silently upgrade a failed attempt to a newer version.

A fully published recorded Intune app uses the same validation and completion path as ResumePublishedAppId. A recorded ID that returns an explicit HTTP 404 can be recreated only for an original Create operation while replace_in_place is disabled and no other app represents the same identity/version/role. Absence is checked again after downloading, before any publication request.

Partial uploads, missing/invalid IDs, incompatible resume schemas, ownership or version mismatches, and ambiguous Graph failures remain blocked with per-application errors. Missing replacement or reconciliation targets are never recreated. RetryFailed does not delete failed Intune applications or resume an unfinished byte upload.

Before replacing active status, the original journal is copied and verified under `WorkingFolder/ClientProcessState/Archive/`. The new journal links to it through `RetrySourceJournal`. Backup or download failure leaves the active failed journal intact. The existing workspace lock covers recovery. Each eligible publication is attempted once per invocation; failures do not restart the batch.

Recovery always skips previous-version cleanup. Dependency, assignment, ESP, and configured reverse-dependency processing still run through the existing workflow. Capture pipeline results as shown in Example 14 to retain per-application failures.

## Behavior and limits

Windows and PowerShell >=7.5 are mandatory, including DownloadOnly. api.client selects the AppFactory client; application_name selects a shared application UUID/slugified name, not an Intune or configuration ID. Omitting it processes all enabled configurations visible for that client. Dependencies can expand the selected work, and updater mode can produce two roles. No TestMode or WhatIf is implemented on this command. Use DownloadOnly for downloads without publication; it is not a full tenant preflight. UseNativeUpload false is rejected.

## Output

Per-configuration objects with Application, Role, Version, State, AppId, and JournalPath. Success can also include Operation/CleanupBlocked; failure includes Stage/Error. The command emits results and then throws an aggregate error if any configuration failed.

## Choose the right mode

| Goal | Options |
| --- | --- |
| One app | `-application_name '<application-uuid-or-slug>'` |
| All enabled client apps | Omit application_name |
| Operator-visible normal messages | `-EnableLogging -LogLevel Output` |
| Verbose messages | `-EnableLogging -LogLevel Verbose -Verbose` |
| Download without publishing | `-DownloadOnly` |
| Auto transport | `-UploadTransport Auto` (default) |
| Explicit AzCopy | `-UploadTransport AzCopy`, optionally `-AzCopyPath` |
| Native blocks only | `-UploadTransport Native` |
| Retain prior apps for review | `-SkipPreviousVersionCleanup` |
| Intentional same-version republish | `-Force` |
| Recover failed client attempts | `-RetryFailed` |
| Continue after app is already published | `-ResumePublishedAppId`, with one selected configuration |

### Logging

EnableLogging configures the PSFramework logfile provider and enables module log calls. The file path is `<workspace>/Logs/AppFactoryClient-%Date%.csv`, with the logging provider expanding the date placeholder. LogLevel selects the default level of routine messages; explicit warning/error calls retain their own level. Output is the operator-facing setting used by the repository's runner scripts. Verbose is the declared default, so include the common `-Verbose` parameter when using that level. PSFramework's configured message filters can still affect host display.

Logs are separate from the result-object pipeline. Avoid merging every PowerShell stream into a result-object collection: that mixes status messages with Application/State objects. Retain failed-attempt journals and redact credential-bearing information before sharing diagnostics.

### Transport behavior

Auto tries AzCopy for encrypted payloads of at least 100 MB when an executable is available; otherwise it uses native block upload. An explicit AzCopy selection must find azcopy.exe through AzCopyPath or PATH. An unsuccessful/unconfirmed AzCopy transfer can fall back to native blocks after stopping AzCopy and clearing partial content. Thus selecting AzCopy does not mean every byte is guaranteed to use it.

UseNativeUpload names the publishing engine, while UploadTransport selects the byte-transfer method. Keep UseNativeUpload at its true default even when using AzCopy. The old IntuneWin32App publishing route has been retired.

### Replacement, force, and assignments

Client configuration replace_in_place controls whether content replaces a verified managed app or a new app is created. Normal in-place replacement preserves assignments and skips ESP writes/previous-app cleanup. The updater role has distinct assignment handling.

Same-version published apps normally enter dependency reconciliation without another upload. Force bypasses that ordinary reuse decision; in create-new mode it can create an additional app for the same version. It does not bypass unfinished-journal or ownership checks.

SkipPreviousVersionCleanup skips prior-app unassignment/deletion but still allows the new publication's assignments/dependencies. Review keep_previous_versions and unassign_previous_assignments in the client configuration before omitting that switch.

### Results and recovery

| State | Meaning |
| --- | --- |
| Downloaded | Download-only step finished |
| Complete | Publication and verification finished |
| DependenciesReconciled | Existing published content reused; dependency reconciliation completed |
| PublishedCleanupBlocked | Publication succeeded; an older app was retained with a recorded reason |
| Failed | Inspect Stage, Error, AppId, and JournalPath |

The process acquires a working-folder lock, continues with other configurations after a per-app failure, emits results, then throws if failures occurred. A failed setup can throw before per-app result objects exist.

State files are under `<workspace>/WorkingFolder/ClientProcessState/`; native upload diagnostics are under `WorkingFolder/NativeUploads/`. Do not delete an unfinished journal to force a retry. Preserve the workspace and inspect the recorded Intune application, especially after an in-place replacement.

Resume requires an already-published exact Intune app ID, exactly one selected configuration before dependency expansion, and compatible saved identity/role/dependency/requirement expectations. Replacement resume checks active content, detection, and architecture too. It cannot combine with Force or DownloadOnly. It is not a general resume command for an unfinished content upload.

## Source

[cmdlets/Public/general/Start-AFClientProcess.ps1](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Public/general/Start-AFClientProcess.ps1)

[Logging helper](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Private/misc/Write-AFLogEntry.ps1) · [Transfer selection](https://github.com/jeremyputman/Application.Factory--New-/blob/232b6b3e2a61ec5ece934a6534c402843afa335d/cmdlets/Private/intune/Send-AFNativeIntuneContent.ps1)


