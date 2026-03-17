<#
.SYNOPSIS
    Tests the application object for required file properties.
.DESCRIPTION
    Validates that the application object contains an iconUrl property before proceeding with package creation.
.PARAMETER Application
    The application object to validate. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Throws an error if required properties are missing.
.EXAMPLE
    Test-AFApplicationFiles -Application $app
#>
function Test-AFApplicationFiles {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  # Validate that iconUrl property exists
  if(-not $application.iconUrl){
    throw "Application $($application.information.Name) is missing an iconUrl property. Please add this to the application configuration before creating a package."
  }
}