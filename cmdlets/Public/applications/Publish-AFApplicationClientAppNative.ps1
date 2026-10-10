function Publish-AFApplicationClientAppNative {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$Configuration,

        [ValidateSet("Auto", "Native", "AzCopy")]
        [string]$UploadTransport = "Auto",

        [string]$AzCopyPath,

        [ValidateRange(300, 86400)]
        [int]$UploadTimeoutSeconds = 21600,

        [ValidateRange(30, 3600)]
        [int]$ProcessingTimeoutSeconds = 900
    )

    if (
        $PSVersionTable.PSVersion.Major -lt 7 -or
        -not $IsWindows
    ) {
        throw "Native publishing requires PowerShell 7 on Windows."
    }

    $script:published_application = $null

    $application = $Configuration.application
    $data = $script:application_data

    if (
        -not $application -or
        -not $data -or
        [string]::IsNullOrWhiteSpace([string]$script:published_version)
    ) {
        throw (
            "Application configuration, downloaded App.json, and " +
            "published version must be initialized before publishing."
        )
    }

    $downloadFolder = Join-Path `
        (Join-Path $script:working_folder "Download") `
        $application.slug

    $packagePath = Join-Path `
        $downloadFolder `
        "$($application.Name).intunewin"

    $workDirectory = Join-Path `
        (Join-Path $script:working_folder "NativeUploads") `
        ([guid]::NewGuid().ToString("N"))

    $diagnosticsDirectory = Join-Path $workDirectory "AzCopy"

    $status = [ordered]@{
        ApplicationName  = [string]$application.Name
        AppFactoryId     = [string]$application.id
        AppId            = ""
        ContentVersionId = ""
        FileId           = ""
        Stage            = "Preflight"
        TransportUsed    = ""
        AzCopyJobId      = ""
        Renewals         = 0
        SizeEncrypted    = 0L
        StartedUtc       = [DateTimeOffset]::UtcNow
        ElapsedSeconds   = 0.0
        WorkDirectory    = $workDirectory
    }

    $script:af_native_upload_status = $status
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $context = $null

    try {
        $package = Get-AFNativeIntunePackage `
            -FilePath $packagePath `
            -WorkDirectory $workDirectory

        $status.SizeEncrypted = $package.SizeEncrypted

        $architectureTable = @{
            x64 = "x64"
            x86 = "x86"
            All = "x64,x86"
        }

        $operatingSystemTable = @{
            W10_1607 = "1607"
            W10_1703 = "1703"
            W10_1709 = "1709"
            W10_1803 = "1803"
            W10_1809 = "1809"
            W10_1903 = "1903"
            W10_1909 = "1909"
            W10_2004 = "2004"
            W10_20H2 = "20H2"
            W10_21H1 = "21H1"
            W10_21H2 = "Windows10_21H2"
            W10_22H2 = "Windows10_22H2"
            W11_21H2 = "Windows11_21H2"
            W11_22H2 = "Windows11_22H2"
            W11_23H2 = "Windows11_23H2"
        }

        $architecture = $architectureTable[
            [string]$data.requirementrule.architecture
        ]

        $minimumRelease = $operatingSystemTable[
            [string]$data.requirementrule.minimumsupportedwindowsrelease
        ]

        if (-not $architecture -or -not $minimumRelease) {
            throw "Unsupported architecture or minimum Windows release."
        }

        $runAs = [string]$data.program.installexperience
        $restartBehavior = [string]$data.program.devicerestartbehavior

        if ($runAs -notin @("system", "user")) {
            throw "Install experience must be system or user."
        }

        if ($restartBehavior -notin @(
            "basedOnReturnCode", "allow", "suppress", "force"
        )) {
            throw "Unsupported device restart behavior."
        }

        # Reject unknown detection types instead of risking stale rule data.
        foreach ($rule in @($data.DetectionRule)) {
            if ($rule.Type -notin @(
                "msi",
                "script",
                "registry_version",
                "registry_existence"
            )) {
                throw "Unsupported detection rule type: $($rule.Type)"
            }
        }

        $detectionRules = @(
            New-AFApplicationClientDetection `
                -application $application `
                -ApplicationFolder $downloadFolder
        )

        if ($detectionRules.Count -eq 0) {
            throw "At least one detection rule is required."
        }

        $displayName = (
            "$script:app_prefix$($application.Name) " +
            "$script:published_version"
        )

        $description = [string]$data.Information.Description

        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = $displayName
        }

        $installMode = if ($Configuration.interactive_install) {
            "Auto"
        }
        else {
            "Silent"
        }

        $uninstallMode = if ($Configuration.interactive_uninstall) {
            "Auto"
        }
        else {
            "Silent"
        }

        $allowUninstall = $false

        if ($null -ne $data.Program.AllowAvailableUninstall) {
            $allowUninstall = [Convert]::ToBoolean(
                $data.Program.AllowAvailableUninstall
            )
        }

        $body = @{
            "@odata.type"                  = "#microsoft.graph.win32LobApp"
            displayName                    = $displayName
            description                    = $description
            publisher                      = [string]$data.Information.Publisher.name
            displayVersion                 = [string]$script:published_version
            fileName                       = $package.FileName
            setupFilePath                  = $package.SetupFile
            installCommandLine             = "Invoke-AppDeployToolkit.exe Install -DeployMode $installMode"
            uninstallCommandLine           = "Invoke-AppDeployToolkit.exe Uninstall -DeployMode $uninstallMode"
            applicableArchitectures        = $architecture
            minimumSupportedWindowsRelease = $minimumRelease
            detectionRules                 = $detectionRules
            requirementRules               = @()
            allowAvailableUninstall        = $allowUninstall
            notes                          = "$($data.Information.Notes)`nAppFactoryID:$($application.id)"
            installExperience              = @{
                "@odata.type"         = "#microsoft.graph.win32LobAppInstallExperience"
                runAsAccount          = $runAs
                deviceRestartBehavior = $restartBehavior
                maxRunTimeInMinutes   = 60
            }
            returnCodes = @(
                @{ returnCode = 0;    type = "success" }
                @{ returnCode = 1707; type = "success" }
                @{ returnCode = 3010; type = "softReboot" }
                @{ returnCode = 1641; type = "hardReboot" }
                @{ returnCode = 1618; type = "retry" }
            )
        }

        foreach ($mapping in @(
            @{
                Source = "minimummemoryinmb"
                Target = "minimumMemoryInMB"
            }
            @{
                Source = "minimumfreediskspaceinmb"
                Target = "minimumFreeDiskSpaceInMB"
            }
        )) {
            $value = $data.requirementrule.($mapping.Source)

            if ($null -ne $value -and "$value" -ne "") {
                $number = [int]$value

                if ($number -lt 0) {
                    throw "Requirement $($mapping.Source) cannot be negative."
                }

                $body[$mapping.Target] = $number
            }
        }

        foreach ($mapping in @(
            @{ Source = "information_url"; Target = "informationUrl" }
            @{ Source = "privacy_url";     Target = "privacyInformationUrl" }
            @{ Source = "owner";           Target = "owner" }
        )) {
            $value = [string]$data.Information.($mapping.Source)

            if (-not [string]::IsNullOrWhiteSpace($value)) {
                $body[$mapping.Target] = $value
            }
        }

        $iconPath = Join-Path $downloadFolder "Icon.png"

        if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
            $body.largeIcon = @{
                "@odata.type" = "#microsoft.graph.mimeContent"
                type          = "image/png"
                value         = [Convert]::ToBase64String(
                    [IO.File]::ReadAllBytes($iconPath)
                )
            }
        }

        # Check explicit AzCopy configuration before creating an app.
        if ($UploadTransport -eq "AzCopy") {
            if (-not $AzCopyPath) {
                $command = Get-Command azcopy.exe `
                    -CommandType Application `
                    -ErrorAction SilentlyContinue |
                    Select-Object -First 1

                if ($command) {
                    $AzCopyPath = $command.Source
                }
            }

            if (-not $AzCopyPath -or -not (
                Test-Path -LiteralPath $AzCopyPath -PathType Leaf
            )) {
                throw "AzCopy was requested but its executable was not found."
            }
        }

        # Avoid reusing a token cached for a previous client's credentials.
        Connect-AFIntuneGraph -Force

        $status.Stage = "CreateApplication"

        $app = Invoke-AFNativeGraphRequest `
            -Method POST `
            -Uri "deviceAppManagement/mobileApps" `
            -Body $body

        if (-not $app.id) {
            throw "Graph did not return an application ID."
        }

        $status.AppId = [string]$app.id
        Save-AFNativePublishCheckpoint -Status $status
        $appUri = "deviceAppManagement/mobileApps/$($app.id)"
        $contentRoot = "$appUri/microsoft.graph.win32LobApp/contentVersions"

        $status.Stage = "CreateContentVersion"

        $version = Invoke-AFNativeGraphRequest `
            -Method POST `
            -Uri $contentRoot `
            -Body @{}

        if (-not $version.id) {
            throw "Graph did not return a content version ID."
        }

        $status.ContentVersionId = [string]$version.id
        Save-AFNativePublishCheckpoint -Status $status
        $filesUri = "$contentRoot/$($version.id)/files"

        $status.Stage = "CreateContentFile"

        $file = Invoke-AFNativeGraphRequest `
            -Method POST `
            -Uri $filesUri `
            -Body @{
                "@odata.type" = "#microsoft.graph.mobileAppContentFile"
                name          = $package.FileName
                size          = [long]$package.Size
                sizeEncrypted = [long]$package.SizeEncrypted
                manifest      = $null
                isDependency  = $false
            }

        if (-not $file.id) {
            throw "Graph did not return a content file ID."
        }

        $status.FileId = [string]$file.id
        Save-AFNativePublishCheckpoint -Status $status
        $fileUri = "$filesUri/$($file.id)"

        $status.Stage = "AzureStorageUriRequest"

        $file = Wait-AFNativeContentFile `
            -FileUri $fileUri `
            -Stage AzureStorageUriRequest `
            -TimeoutSeconds $ProcessingTimeoutSeconds

        $context = @{
            File          = $file
            FileUri       = $fileUri
            Deadline      = [DateTimeOffset]::UtcNow.AddSeconds(
                $UploadTimeoutSeconds
            )
            Renewals      = 0
            TransportUsed = ""
            AzCopyJobId   = ""
        }

        $status.Stage = "UploadContent"
        Save-AFNativePublishCheckpoint -Status $status

        Send-AFNativeIntuneContent `
            -Context $context `
            -PayloadPath $package.PayloadPath `
            -Transport $UploadTransport `
            -AzCopyPath $AzCopyPath `
            -DiagnosticsDirectory $diagnosticsDirectory

        $status.TransportUsed = $context.TransportUsed
        $status.Renewals = $context.Renewals
        $status.AzCopyJobId = $context.AzCopyJobId

        $status.Stage = "CommitFile"
        $commitResponseIssue = ""

        try {
            Invoke-AFNativeGraphRequest `
                -Method POST `
                -Uri "$fileUri/commit" `
                -Body @{
                    fileEncryptionInfo = $package.EncryptionInfo
                } | Out-Null
        }
        catch {
            $httpStatus = [int]$_.Exception.Data["HttpStatus"]

            if ($httpStatus -notin @(0, 408, 500, 502, 503, 504)) {
                throw
            }

            # Do not blindly POST commit again after a lost response.
            $commitResponseIssue = $_.Exception.Message
            Write-Verbose "Commit response was ambiguous; checking file state."
        }

        try {
            $committedFile = Wait-AFNativeContentFile `
                -FileUri $fileUri `
                -Stage CommitFile `
                -TimeoutSeconds $ProcessingTimeoutSeconds
        }
        catch {
            if ($commitResponseIssue) {
                throw (
                    "$($_.Exception.Message)`n" +
                    "Original commit response issue:`n$commitResponseIssue"
                )
            }

            throw
        }

        if (-not $committedFile.isCommitted) {
            throw "Intune did not confirm that the content file is committed."
        }

        $status.Stage = "ActivateContentVersion"

        Invoke-AFNativeGraphRequest `
            -Method PATCH `
            -Uri $appUri `
            -Body @{
                "@odata.type"           = "#microsoft.graph.win32LobApp"
                committedContentVersion = [string]$version.id
            } | Out-Null

        $status.Stage = "WaitForPublishing"
        $publishDeadline = [DateTimeOffset]::UtcNow.AddSeconds(
            $ProcessingTimeoutSeconds
        )

        $lastApp = $null

        while ([DateTimeOffset]::UtcNow -lt $publishDeadline) {
            $lastApp = Invoke-AFNativeGraphRequest `
                -Method GET `
                -Uri $appUri

            if (
                [string]$lastApp.committedContentVersion -eq
                [string]$version.id -and
                [int]$lastApp.uploadState -eq 1 -and
                $lastApp.publishingState -eq "published"
            ) {
                $status.Stage = "Complete"
                $script:published_application = $lastApp

                # Keep AzCopy diagnostics; discard the extracted payload.
                Remove-Item `
                    -LiteralPath $package.PayloadPath `
                    -Force `
                    -ErrorAction SilentlyContinue

                return $lastApp
            }

            Start-Sleep -Seconds 5
        }

        throw (
            "Application did not become ready and published. " +
            "UploadState=$($lastApp.uploadState); " +
            "PublishingState=$($lastApp.publishingState); " +
            "CommittedContentVersion=$($lastApp.committedContentVersion)"
        )
    }
    catch {
        $message = @(
            "Native Win32 publishing failed; no application was deleted."
            "Application: $($status.ApplicationName)"
            "Stage: $($status.Stage)"
            "App ID: $($status.AppId)"
            "Content version ID: $($status.ContentVersionId)"
            "File ID: $($status.FileId)"
            "Encrypted bytes: $($status.SizeEncrypted)"
            "Work directory: $workDirectory"
            "Details: $(Protect-AFNativeDiagnostic -Text $_.Exception.Message)"
        ) -join [Environment]::NewLine

        throw [InvalidOperationException]::new($message, $_.Exception)
    }
    finally {
        if ($context) {
            $status.TransportUsed = $context.TransportUsed
            $status.Renewals = $context.Renewals
            $status.AzCopyJobId = $context.AzCopyJobId
        }

        $stopwatch.Stop()
        $status.ElapsedSeconds = $stopwatch.Elapsed.TotalSeconds
    }
}