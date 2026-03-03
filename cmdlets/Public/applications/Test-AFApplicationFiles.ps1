function Test-AFApplicationFiles{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  if(-not $application.iconUrl){
    throw "Application $($application.information.Name) is missing an iconUrl property. Please add this to the application configuration before creating a package."
  }

}