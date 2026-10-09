function Update-AFNativeUploadSas {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Context,
        [switch]$Force
    )

    if ([DateTimeOffset]::UtcNow -ge $Context.Deadline) {
        throw "Native content upload exceeded its overall timeout."
    }

    $expiration = Get-AFNativeSasExpiration -File $Context.File

    if (
        -not $Force -and
        $expiration -gt [DateTimeOffset]::UtcNow.AddMinutes(3)
    ) {
        return
    }

    if ($Context.Renewals -ge 100) {
        throw "Native content upload exceeded the SAS renewal limit."
    }

    $oldSas = [string]$Context.File.azureStorageUri
    $oldResource = ([uri]$oldSas).GetLeftPart([UriPartial]::Path)
    $Context.Renewals++

    try {
        Invoke-AFNativeGraphRequest `
            -Method POST `
            -Uri "$($Context.FileUri)/renewUpload" | Out-Null
    }
    catch {
        $status = [int]$_.Exception.Data["HttpStatus"]

        # An ambiguous response may still have initiated renewal.
        if ($status -notin @(0, 408, 500, 502, 503, 504)) {
            throw
        }

        Write-Verbose "Renewal response was ambiguous; checking file state."
    }

    $renewed = Wait-AFNativeContentFile `
        -FileUri $Context.FileUri `
        -Stage AzureStorageUriRenewal `
        -PreviousSasUri $oldSas

    $newResource = ([uri]$renewed.azureStorageUri).GetLeftPart(
        [UriPartial]::Path
    )

    if ($newResource -cne $oldResource) {
        throw "SAS renewal changed the destination blob; upload stopped."
    }

    $Context.File = $renewed
}