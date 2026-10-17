function Set-AFClientAssignmentPlanFilters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Configuration,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Assignments
    )

    # Never silently ignore a legacy policy during rollout.
    if (-not [string]::IsNullOrWhiteSpace(
            [string]$Configuration.filters
        )) {
        throw 'Migrate legacy filters to assignment_filters before publishing.'
    }

    $policyRows = @()
    $property = $Configuration.PSObject.Properties['assignment_filters']

    if ($null -ne $property) {
        if ($property.Value -isnot [System.Array]) {
            throw 'assignment_filters must be a JSON array; use [] for no overrides.'
        }

        $policyRows = @($property.Value)
    }

    # Work on normalized copies, retaining copied assignment settings.
    $bodies = @(
        foreach ($assignment in $Assignments) {
            ConvertTo-AFNativeAssignmentBody -Assignment $assignment
        }
    )

    $seenAssignments = @{}
    foreach ($body in $bodies) {
        $key = Get-AFNativeAssignmentBaseKey -Assignment $body
        if ($seenAssignments.ContainsKey($key)) {
            throw "Duplicate assignment target/intent: $key"
        }
        $seenAssignments[$key] = $true
    }

    $seenOverrides = @{}

    foreach ($row in $policyRows) {
        if ($null -eq $row) {
            throw 'An assignment filter row cannot be null.'
        }

        foreach ($field in @(
                'intent', 'group_name', 'filter_name', 'filter_type'
            )) {
            if (
                $null -eq $row.PSObject.Properties[$field] -or
                $row.$field -isnot [string]
            ) {
                throw "Each assignment filter row requires a string '$field'."
            }
        }

        $intent = $row.intent.Trim().ToLowerInvariant()
        $groupName = $row.group_name.Trim()
        $filterName = $row.filter_name.Trim()
        $mode = $row.filter_type.Trim().ToLowerInvariant()

        if ($intent -notin @('available', 'required', 'uninstall')) {
            throw "Unsupported filter assignment intent: $intent"
        }

        if (-not $groupName) {
            throw 'An assignment filter row requires a group name.'
        }

        if ($mode -notin @('none', 'include', 'exclude')) {
            throw "Unsupported assignment filter mode: $mode"
        }

        if (
            ($mode -eq 'none' -and $filterName) -or
            ($mode -ne 'none' -and -not $filterName)
        ) {
            throw 'Include/Exclude requires a filter; None requires an empty filter name.'
        }

        $groupId = ''
        switch ($groupName) {
            'All Users' {
                $targetType = 'microsoft.graph.allLicensedUsersAssignmentTarget'
            }
            'All Devices' {
                $targetType = 'microsoft.graph.allDevicesAssignmentTarget'
            }
            default {
                $group = Get-AFClientUniqueGraphObject `
                    -Resource 'groups' `
                    -DisplayName $groupName

                $groupId = [string]$group.id
                $targetType = 'microsoft.graph.groupAssignmentTarget'
            }
        }

        $matches = @(
            $bodies | Where-Object {
                [string]$_.intent -eq $intent -and
                ([string]$_.target.'@odata.type').TrimStart('#') -eq
                    $targetType -and
                [string]$_.target.groupId -eq $groupId
            }
        )

        if ($matches.Count -ne 1) {
            throw (
                "Expected one included assignment for '$groupName' " +
                "with intent '$intent'; found $($matches.Count)."
            )
        }

        $body = $matches[0]
        $key = Get-AFNativeAssignmentBaseKey -Assignment $body

        if ($seenOverrides.ContainsKey($key)) {
            throw "More than one filter row targets assignment: $key"
        }
        $seenOverrides[$key] = $true

        $filterId = $null
        if ($mode -ne 'none') {
            $filter = Get-AFClientUniqueGraphObject `
                -Resource 'deviceManagement/assignmentFilters' `
                -DisplayName $filterName

            $filterId = [string]$filter.id
        }

        $body.target.deviceAndAppManagementAssignmentFilterId = $filterId
        $body.target.deviceAndAppManagementAssignmentFilterType = $mode
    }

    # Validate both explicit overrides and filters inherited from copied rows.
    $filterCache = @{}

    foreach ($body in $bodies) {
        $mode = [string]$body.target.deviceAndAppManagementAssignmentFilterType
        $targetType = (
            [string]$body.target.'@odata.type'
        ).TrimStart('#')

        if ($mode -eq 'none') {
            continue
        }

        if ($targetType -eq 'microsoft.graph.exclusionGroupAssignmentTarget') {
            throw 'Filtered group-exclusion assignments require manual review.'
        }

        # Also validates the filter GUID before constructing a Graph URI.
        $normalized = ConvertTo-AFNativeAssignmentBody -Assignment $body
        $filterId = [string](
            $normalized.target.deviceAndAppManagementAssignmentFilterId
        )

        if (-not $filterCache.ContainsKey($filterId)) {
            $filterCache[$filterId] = Invoke-AFNativeGraphRequest `
                -Method GET `
                -Uri "deviceManagement/assignmentFilters/$filterId"
        }

        $filter = $filterCache[$filterId]

        if ([string]$filter.id -ne $filterId) {
            throw "Filter lookup returned an unexpected ID: $filterId"
        }

        if (
            [string]$filter.platform -ne 'windows10AndLater' -or
            [string]$filter.assignmentFilterManagementType -ne 'devices'
        ) {
            throw (
                "Filter '$($filter.displayName)' must be a Windows " +
                'managed-device filter for Win32 publishing.'
            )
        }
    }

    foreach ($body in $bodies) {
        ConvertTo-AFNativeAssignmentBody -Assignment $body
    }
}