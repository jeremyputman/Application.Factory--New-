<#
.SYNOPSIS
    Adds script lines to handle blocking processes for application installation.
.DESCRIPTION
    Generates PowerShell script lines to check for and handle processes that may block application installation. Supports interactive and non-interactive modes.
.PARAMETER interactive
    If specified, prompts user to close blocking processes interactively.
.PARAMETER blockingProcess
    Array of process names that block installation.
.PARAMETER deferCount
    Number of times the user can defer closing processes (interactive mode only).
.PARAMETER LogLevel
    Logging verbosity. Default is 'Verbose'.
.OUTPUTS
    System.Collections.Generic.List[String[]]
.EXAMPLE
    Add-AppFactoryApplicationBlockingProcess -interactive -blockingProcess 'notepad','calc' -deferCount 2
#>
function Add-AppFactoryApplicationBlockingProcess{
  [cmdletbinding()]
  [OutputType([System.Collections.Generic.List[String[]]])]
  param(
    [Parameter()][switch]$interactive,   
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$blockingProcess,
    [Parameter()][ValidateNotNullOrEmpty()][int]$deferCount = 0
  )
  # List to hold generated script lines
  $ApplicationScriptLines = [System.Collections.Generic.List[String[]]]@()
  if($interactive.IsPresent){
    # Interactive mode: prompt user to close processes
    $ApplicationScriptLines.Add("`t`$processExist = `$false") | Out-Null
    foreach ($item in $blockingProcess) {
      $ApplicationScriptLines.Add("`tif(Get-Process -Name `"$($item)`" -ErrorAction SilentlyContinue){`$processExist = `$true}") | Out-Null
    }
    $ApplicationScriptLines.Add("`tif (`$adtSession.IsProcessUserInteractive -and `$processExist) {") | Out-Null
    $ApplicationScriptLines.Add("`t`t`$params = @{") | Out-Null
    $ApplicationScriptLines.Add("`t`t`t`"CloseProcesses`" = '$($blockingProcess -join "','")'") | Out-Null
    $ApplicationScriptLines.Add("`t`t`t`"PersistPrompt`" = `$true") | Out-Null
    if ($deferCount -gt 0) {
      $ApplicationScriptLines.Add("`t`t`t`"AllowDefer`" = `$true") | Out-Null
      $ApplicationScriptLines.Add("`t`t`t`"DeferTimes`" = $($deferCount)") | Out-Null
    }
    $ApplicationScriptLines.Add("`t`t}") | Out-Null
    $ApplicationScriptLines.Add("`t`tShow-ADTInstallationWelcome @params") | Out-Null
    $ApplicationScriptLines.Add("`t}") | Out-Null    
    $ApplicationScriptLines.Add("`telse {") | Out-Null
    foreach ($item in $blockingProcess) {
      $ApplicationScriptLines.Add("`t`t`Start-Sleep -Seconds 2") | Out-Null
      $ApplicationScriptLines.Add("`t`t`Get-Process -Name `"$($item)`" -ErrorAction SilentlyContinue | Stop-Process -Force") | Out-Null
    }
    $ApplicationScriptLines.Add("`t}") | Out-Null      
  }
  else{
    foreach($item in $blockingProcess){
      $ApplicationScriptLines.Add("`tStart-Sleep -Seconds 2") | Out-Null
      $ApplicationScriptLines.Add("`tGet-Process -Name `"$($item)`" -ErrorAction SilentlyContinue | Stop-Process -Force") | Out-Null
    }
  }
  return @(,$ApplicationScriptLines)
}