<#
.SYNOPSIS
    Generates script lines to mount or dismount a WIM file for application installation.
.DESCRIPTION
    Builds PowerShell script lines to handle mounting and dismounting of WIM files using ADT functions.
.OUTPUTS
    System.Collections.Generic.List[String[]]
.EXAMPLE
    Add-AppFactoryAppWIM -section start -MountPath 'C:\Mount'
#>
function Add-AppFactoryAppWIM{
  [cmdletbinding()]
  [OutputType([System.Collections.Generic.List[String[]]])]
  param(
    [Parameter(Mandatory = $true)][ValidateSet("start","end")][string]$section,
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$MountPath
  ) 
  $ApplicationScriptLines = [System.Collections.Generic.List[String[]]]@() 
  # Add script lines for mounting or dismounting WIM files
  if($section -eq "start"){
    # Mount the WIM file
    $ApplicationScriptLines.Add("`t`$mountPath = `"$($MountPath)`"")  | Out-Null
    $ApplicationScriptLines.Add("`t`$wimFile = Get-Childitem -Path `"`$(`$adtSession.dirFiles)`" -Filter `"*.wim`"")  | Out-Null
    $ApplicationScriptLines.Add("`t`$wimPath = Join-Path `$adtSession.dirFiles -ChildPath `$wimFile")  | Out-Null
    $ApplicationScriptLines.Add("`tMount-ADTWimFile -ImagePath `$wimPath -Path `$mountPath -Index 1")  | Out-Null 
  }
  else{
    # Dismount the WIM file
    $ApplicationScriptLines.Add("`tDismount-ADTWimFile -Path `"$($MountPath)`"")  | Out-Null 
  }
  # Return the generated script lines
  return @(,$ApplicationScriptLines)
}