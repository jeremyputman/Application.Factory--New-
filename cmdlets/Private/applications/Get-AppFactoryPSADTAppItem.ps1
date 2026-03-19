<#
.SYNOPSIS
    Gets the latest PSADT application item version.
.DESCRIPTION
    Determines the most recent version for a PSADT application and returns it as a custom object.
.OUTPUTS
    PSCustomObject with Version and URI properties.
.EXAMPLE
    Get-AppFactoryPSADTAppItem -application $appObj
#>
function Get-AppFactoryPSADTAppItem {
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application
  )
  # Determine the latest version for the PSADT application
  if($application.sourcefiles.versions.count -eq 0){
    $version = "1.0"
  }
  else{
    $version = $application.sourcefiles.versions[-1].name
  }
  # Build and return the result object
  $PSObject = [PSCustomObject]@{
    "Version" = $version
    "URI" = $null
  }
  return $PSObject  
}