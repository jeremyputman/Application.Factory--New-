function Start-AFClientProcess {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$configFile,
    [Parameter(Mandatory)][string]$workspace,
    [string]$application_name,
    [switch]$EnableLogging,
    [string]$LogLevel = "Verbose",
    [switch]$Force,
    [switch]$DownloadOnly,

    [switch]$UseNativeUpload,
    [ValidateSet("Auto", "Native", "AzCopy")][string]$UploadTransport = "Auto",
    [string]$AzCopyPath,

    [switch]$SkipPreviousVersionCleanup,
    [string]$ResumePublishedAppId
  )

  $ErrorActionPreference = "Stop"

  if (
    $ResumePublishedAppId -and
    ($Force -or $DownloadOnly)
  ) {
    throw "ResumePublishedAppId cannot be combined with Force or DownloadOnly."
  }

  $script:log_target = "Application Factory Client"

  Set-AFClientSettings `
    -configFile $configFile `
    -Workspace $workspace `
    -EnableLogging:$EnableLogging `
    -LogLevel $LogLevel

  [IO.Directory]::CreateDirectory($script:working_folder) | Out-Null

  # Prevent overlapping client processes using this working folder.
  $lockPath = Join-Path $script:working_folder "client-process.lock"
  $processLock = $null
  $results = [Collections.Generic.List[object]]::new()

  try {
    try {
      $processLock = [IO.File]::Open(
        $lockPath,
        [IO.FileMode]::OpenOrCreate,
        [IO.FileAccess]::ReadWrite,
        [IO.FileShare]::None
      )
    }
    catch {
      throw (
        "Cannot acquire the client-process lock at '$lockPath'. " +
        "Another process may be using this workspace. " +
        $_.Exception.Message
      )
    }

    $attemptLimit = [Math]::Max(1, [int]$script:retries)
    $configurations = @()
    $intuneApps = @()

    # Only repeat setup reads. Never repeat the entire publication loop.
    for ($attempt = 1; $attempt -le $attemptLimit; $attempt++) {
      try {
        $lookup = @{ id = $script:client_id }

        if ($application_name) {
          $lookup.application_id = $application_name
        }

        $configurations = @(
          Get-AFApplicationConfigurations @lookup -ErrorAction Stop
        )

        if (-not $DownloadOnly -and $configurations.Count -gt 0) {
          Connect-AFIntuneGraph -Force

          $filter = [uri]::EscapeDataString(
            "isof('microsoft.graph.win32LobApp') and " +
            "contains(notes,'AppFactoryID:')"
          )

          $intuneApps = @(
            Get-AFClientGraphCollection -Uri (
              "deviceAppManagement/mobileApps?`$filter=$filter"
            )
          )
        }

        break
      }
      catch {
        if ($attempt -eq $attemptLimit) {
          throw
        }

        Write-Warning (
          "Client setup failed; retrying read operations " +
          "($attempt/$attemptLimit). " +
          (Protect-AFNativeDiagnostic -Text $_.Exception.Message)
        )

        Start-Sleep -Seconds 15
      }
    }

    if ($ResumePublishedAppId -and $configurations.Count -ne 1) {
      throw (
        "ResumePublishedAppId requires exactly one configuration. " +
        "Select it using application_name."
      )
    }

    foreach ($configuration in $configurations) {
      $application = $configuration.application
      $appId = [string]$application.id
      $appName = [string]$application.Name

      $version = if (
        $application.latest_version.raw_version
      ) {
        [string]$application.latest_version.raw_version
      }
      else {
        [string]$configuration.version.raw_version
      }

      $script:published_application = $null
      $script:af_native_upload_status = $null
      $script:published_version = $version

      $journal = $null
      $journalPath = ""
      $publicationStarted = $false
      $stage = "Preflight"

      try {
        if (
          [string]::IsNullOrWhiteSpace($appId) -or
          [string]::IsNullOrWhiteSpace($appName) -or
          [string]::IsNullOrWhiteSpace($version)
        ) {
          throw "Application ID, name, and version are required."
        }

        if ($DownloadOnly) {
          Get-AFApplicationClientFiles `
            -configuration $configuration `
            -ErrorAction Stop

          $results.Add([PSCustomObject]@{
              Application = $appName
              Version     = $version
              State       = "Downloaded"
              AppId       = ""
              JournalPath = ""
            })

          continue
        }

        $journalPath = Get-AFClientProcessJournalPath `
          -ApplicationId $appId `
          -Version $version

        $existingJournal = $null

        if (Test-Path -LiteralPath $journalPath -PathType Leaf) {
          $existingJournal = Get-Content `
            -LiteralPath $journalPath `
            -Raw |
          ConvertFrom-Json

          if (
            $existingJournal.ApplicationId -ne $appId -or
            [string]$existingJournal.Version -cne $version
          ) {
            throw "Saved client-process status has an invalid identity."
          }

          if (
            $existingJournal.State -ne "Complete" -and
            -not $ResumePublishedAppId
          ) {
            throw (
              "An unfinished attempt already exists. " +
              "State=$($existingJournal.State); " +
              "Stage=$($existingJournal.Stage); " +
              "AppId=$($existingJournal.AppId); " +
              "Journal=$journalPath. " +
              "Inspect the application before retrying. " +
              "Use ResumePublishedAppId only when it is published."
            )
          }
        }

        $identityPattern = (
          '(?im)^\s*AppFactoryID:' +
          [regex]::Escape($appId) +
          '\s*$'
        )

        $matchingApps = @(
          $intuneApps |
          Where-Object {
            [string]$_.notes -match $identityPattern
          } |
          Sort-Object createdDateTime -Descending
        )

        $sameVersion = @(
          $matchingApps | Where-Object {
            [string]$_.displayVersion -ceq $version
          }
        )

        $readySameVersion = @(
          $sameVersion | Where-Object {
            $null -ne $_.uploadState -and
            [int]$_.uploadState -eq 1 -and
            $_.publishingState -eq "published" -and
            $_.committedContentVersion
          }
        )

        if (-not $ResumePublishedAppId) {
          $unresolved = @(
            $sameVersion | Where-Object {
              [string]$_.id -notin @($readySameVersion.id)
            }
          )

          if ($unresolved.Count -gt 0) {
            throw (
              "This version has unresolved Intune applications: " +
              "$($unresolved.id -join ', '). " +
              "They will not be deleted or automatically republished."
            )
          }

          if ($readySameVersion.Count -gt 0 -and -not $Force) {
            $results.Add([PSCustomObject]@{
                Application = $appName
                Version     = $version
                State       = "AlreadyPublished"
                AppId       = [string]$readySameVersion[0].id
                JournalPath = $journalPath
              })

            continue
          }
        }

        $previousApps = @(
          $matchingApps | Where-Object {
            $null -ne $_.uploadState -and
            [int]$_.uploadState -eq 1 -and
            $_.publishingState -eq "published" -and
            $_.committedContentVersion -and
            [string]$_.id -ne $ResumePublishedAppId
          }
        )

        $keepPrevious = 0

        if (-not $SkipPreviousVersionCleanup) {
          $rawKeep = [string]$configuration.keep_previous_versions

          if (
            -not [int]::TryParse($rawKeep, [ref]$keepPrevious) -or
            $keepPrevious -lt 0
          ) {
            throw "keep_previous_versions must be a nonnegative integer."
          }
        }

        # Validate expected targets and filters before app creation.
        $plan = Get-AFClientAssignmentPlan `
          -Configuration $configuration `
          -PreviousApps $previousApps

        # Validate ESP names before app creation too.
        foreach ($espName in @(
            [string]$configuration.esp_assignments -split "," |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ } |
            Select-Object -Unique
          )) {
          $esp = Get-AFClientUniqueGraphObject `
            -Resource "deviceManagement/deviceEnrollmentConfigurations" `
            -DisplayName $espName

          if (
            $esp.'@odata.type' -ne
            "#microsoft.graph.windows10EnrollmentCompletionPageConfiguration"
          ) {
            throw "'$espName' is not a Windows ESP configuration."
          }
        }

        if (
          $ResumePublishedAppId -and
          $existingJournal.AppId -and
          $existingJournal.AppId -ne $ResumePublishedAppId
        ) {
          throw (
            "ResumePublishedAppId differs from the app ID " +
            "recorded in the unfinished attempt."
          )
        }

        $journal = [ordered]@{
          ApplicationId    = $appId
          ApplicationName  = $appName
          Version          = $version
          TenantId         = [string]$script:appregistration_tenant
          ClientId         = [string]$script:client_id
          Publisher        = if ($UseNativeUpload) { "Native" } else { "Legacy" }
          State            = "Preparing"
          Stage            = "Preflight"
          AppId            = ""
          ContentVersionId = ""
          FileId           = ""
          UploadStage      = ""
          WorkDirectory    = ""
          Error            = ""
          PreviousAppIds   = @($previousApps.id)
          StartedUtc       = [DateTimeOffset]::UtcNow.ToString("o")
          UpdatedUtc       = ""
        }

        if ($ResumePublishedAppId) {
          $stage = "ValidateResumeApplication"

          $published = Assert-AFClientPublishedApp `
            -AppId $ResumePublishedAppId `
            -ApplicationId $appId `
            -Version $version `
            -TimeoutSeconds 0

          $script:published_application = $published
          $journal.AppId = [string]$published.id
          $journal.Publisher = "Existing"
        }
        else {
          $stage = "DownloadFiles"

          # Retry only before publishing begins.
          for (
            $attempt = 1;
            $attempt -le $attemptLimit;
            $attempt++
          ) {
            try {
              $script:application_data = $null

              Get-AFApplicationClientFiles `
                -configuration $configuration `
                -ErrorAction Stop

              $downloadFolder = Join-Path `
              (Join-Path $script:working_folder "Download") `
                $application.slug

              $packagePath = Join-Path `
                $downloadFolder `
                "$appName.intunewin"

              if (
                -not (Test-Path -LiteralPath $packagePath -PathType Leaf) -or
                -not $script:application_data
              ) {
                throw "Downloaded package or App.json is missing."
              }

              $needsScript = @(
                $script:application_data.DetectionRule |
                Where-Object { $_.Type -eq "script" }
              ).Count -gt 0

              if (
                $needsScript -and
                -not (Test-Path `
                    -LiteralPath (Join-Path $downloadFolder "Detection.ps1") `
                    -PathType Leaf)
              ) {
                throw "The required detection script is missing."
              }

              break
            }
            catch {
              if ($attempt -eq $attemptLimit) {
                throw
              }

              Write-Warning (
                "Download failed for '$appName'; retrying " +
                "($attempt/$attemptLimit)."
              )

              Start-Sleep -Seconds 15
            }
          }

          if (-not $UseNativeUpload) {
            Connect-MSIntuneGraph `
              -TenantID $script:appregistration_tenant `
              -ClientID $script:appregistration_client `
              -ClientSecret $script:appregistration_secret |
            Out-Null
          }

          $stage = "Publish"
          $journal.State = "PublishStarted"
          $journal.Stage = $stage

          # This must succeed before any creation request is sent.
          Save-AFClientProcessJournal `
            -Path $journalPath `
            -Journal $journal

          $publicationStarted = $true

          Publish-AFApplicationClientApp `
            -configuration $configuration `
            -UseNativeUpload:$UseNativeUpload `
            -UploadTransport $UploadTransport `
            -AzCopyPath $AzCopyPath `
            -ErrorAction Stop

          if (-not $script:published_application.id) {
            throw "The publisher did not return an application ID."
          }

          $journal.AppId = [string]$script:published_application.id

          if ($UseNativeUpload -and $script:af_native_upload_status) {
            $journal.ContentVersionId =
            [string]$script:af_native_upload_status.ContentVersionId

            $journal.FileId =
            [string]$script:af_native_upload_status.FileId

            $journal.UploadStage =
            [string]$script:af_native_upload_status.Stage

            $journal.WorkDirectory =
            [string]$script:af_native_upload_status.WorkDirectory
          }

          # Save the known ID before checking readiness.
          $journal.State = "PublishedResponseReceived"

          Save-AFClientProcessJournal `
            -Path $journalPath `
            -Journal $journal
        }

        $stage = "ConfirmPublished"

        $script:published_application = Assert-AFClientPublishedApp `
          -AppId $journal.AppId `
          -ApplicationId $appId `
          -Version $version

        $journal.State = "Published"
        $journal.Stage = $stage

        Save-AFClientProcessJournal `
          -Path $journalPath `
          -Journal $journal

        # Apply the exact native plan captured before publishing.
        # Graph authentication refreshes through Invoke-AFNativeGraphRequest.
        $stage = "ApplyAssignments"
        $journal.Stage = $stage

        Save-AFClientProcessJournal `
          -Path $journalPath `
          -Journal $journal

        Set-AFApplicationClientGroups `
          -configuration $configuration `
          -Plan $plan `
          -ErrorAction Stop |
        Out-Null

        $stage = "VerifyAssignments"

        Assert-AFClientAssignments `
          -AppId $journal.AppId `
          -Plan $plan

        $stage = "ApplyESP"

        if ($configuration.esp_assignments) {
          Set-AFApplicationClientESPAssignments `
            -configuration $configuration `
            -ErrorAction Stop |
          Out-Null
        }

        $stage = "PreviousVersionCleanup"
        $journal.Stage = $stage

        Save-AFClientProcessJournal `
          -Path $journalPath `
          -Journal $journal

        if (-not $SkipPreviousVersionCleanup) {
          # Reconfirm the new app before touching previous versions.
          Assert-AFClientPublishedApp `
            -AppId $journal.AppId `
            -ApplicationId $appId `
            -Version $version `
            -TimeoutSeconds 0 |
          Out-Null

          if ($configuration.unassign_previous_assignments) {
            foreach ($previous in $previousApps) {
              Remove-AFIntuneAppAssignments `
                -Id ([guid]$previous.id) `
                -ApplicationId $appId `
                -Version ([string]$previous.displayVersion) `
                -ProtectedAppId $journal.AppId `
                -ErrorAction Stop |
              Out-Null
            }
          }

          for (
            $index = $keepPrevious;
            $index -lt $previousApps.Count;
            $index++
          ) {
            $previous = $previousApps[$index]

            Remove-AFIntuneWin32App `
              -Id ([guid]$previous.id) `
              -ApplicationId $appId `
              -Version ([string]$previous.displayVersion) `
              -ProtectedAppId $journal.AppId `
              -ErrorAction Stop |
            Out-Null
          }
        }        

        $stage = "Complete"
        $journal.State = "Complete"
        $journal.Stage = $stage

        Save-AFClientProcessJournal `
          -Path $journalPath `
          -Journal $journal

        $results.Add([PSCustomObject]@{
            Application = $appName
            Version     = $version
            State       = "Complete"
            AppId       = [string]$journal.AppId
            JournalPath = $journalPath
          })

        Write-AFLogEntry `
          -Message "[$appName] :: Client process completed for version $version." `
          -Tag "Process", $appName
      }
      catch {
        $failureText = Protect-AFNativeDiagnostic `
          -Text $_.Exception.Message

        # Persist a failure only if publishing began or an existing
        # published application was successfully validated.
        # Download/preflight/invalid-resume failures must not overwrite
        # an earlier publication journal.
        if (
          $journal -and
          (
            $publicationStarted -or
            -not [string]::IsNullOrWhiteSpace(
              [string]$journal.AppId
            )
          )
        ) {
          $journal.State = "Failed"
          $journal.Stage = $stage
          $journal.Error = $failureText

          if (
            $publicationStarted -and
            $UseNativeUpload -and
            $script:af_native_upload_status
          ) {
            $uploadStatus = $script:af_native_upload_status

            if ($uploadStatus.AppId) {
              $journal.AppId = [string]$uploadStatus.AppId
            }

            $journal.ContentVersionId =
            [string]$uploadStatus.ContentVersionId

            $journal.FileId = [string]$uploadStatus.FileId
            $journal.UploadStage = [string]$uploadStatus.Stage
            $journal.WorkDirectory = [string]$uploadStatus.WorkDirectory
          }

          try {
            Save-AFClientProcessJournal `
              -Path $journalPath `
              -Journal $journal
          }
          catch {
            Write-Warning (
              "Could not save the final failure status. " +
              "The earlier publishing marker may remain. " +
              $_.Exception.Message
            ) -WarningAction Continue
          }
        }

        $resultAppId = if ($journal) {
          [string]$journal.AppId
        }
        else {
          ""
        }

        $results.Add([PSCustomObject]@{
            Application = $appName
            Version     = $version
            State       = "Failed"
            Stage       = $stage
            AppId       = $resultAppId
            JournalPath = $journalPath
            Error       = $failureText
          })

        Write-Warning (
          "[$appName] failed at '$stage'. " +
          "No automatic republication or failed-app deletion " +
          "will be attempted. $failureText"
        ) -WarningAction Continue

        # Continue with other configurations, never retry this publication.
        continue
      }
    }

    $script:af_client_process_results = @($results.ToArray())
    $results.ToArray()

    $failed = @(
      $results | Where-Object { $_.State -eq "Failed" }
    )

    if ($failed.Count -gt 0) {
      throw (
        "$($failed.Count) application(s) failed. " +
        "Inspect the returned results and saved status files. " +
        "Published applications were not automatically recreated."
      )
    }
  }
  finally {
    if ($processLock) {
      $processLock.Dispose()
    }
  }
}