function Get-AFClientReplacementTarget {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()]
        [object[]]$MatchingApps = @(),

        [Parameter(Mandatory)]
        [string]$ApplicationId,

        # Retained for compatibility with existing callers.
        # ApplicationName does not determine identity.
        [string]$ApplicationName
    )

    $marker = (
        '(?im)^\s*AppFactoryID:' +
        [regex]::Escape($ApplicationId) +
        '\s*$'
    )

    $scoped = @(
        $MatchingApps |
            Where-Object {
                $_.'@odata.type' -eq "#microsoft.graph.win32LobApp" -and
                [string]$_.notes -match $marker
            } |
            Sort-Object createdDateTime, id -Descending
    )

    if ($scoped.Count -eq 0) {
        return $null
    }

    foreach ($app in $scoped) {
        if (
            $null -eq $app.uploadState -or
            [int]$app.uploadState -ne 1 -or
            $app.publishingState -ne "published" -or
            [string]::IsNullOrWhiteSpace(
                [string]$app.committedContentVersion
            )
        ) {
            throw (
                "An owned application is unresolved; replacement stopped. " +
                "AppId=$($app.id); Version=$($app.displayVersion)"
            )
        }
    }

    $candidate = $scoped[0]

    # Revalidate ownership, version, and readiness using the exact AppId.
    $verified = Get-AFNativeManagedApp `
        -Id ([guid]$candidate.id) `
        -ApplicationId $ApplicationId `
        -Version ([string]$candidate.displayVersion)

    if ($null -eq $verified) {
        throw (
            "The selected replacement target disappeared; " +
            "no new app will be created."
        )
    }

    if (
        [string]$verified.committedContentVersion -cne
        [string]$candidate.committedContentVersion
    ) {
        throw "The selected replacement target changed during preflight."
    }

    Write-Verbose "In-place replacement target: $($verified.id)"

    return $verified
}