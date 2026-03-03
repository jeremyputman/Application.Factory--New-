function Add-AppFactoryApplicationBlockingProcess{
  [cmdletbinding()]
  [OutputType([System.Collections.Generic.List[String[]]])]
  param(
    [Parameter()][switch]$interactive,   
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$blockingProcess,
    [Parameter()][ValidateNotNullOrEmpty()][int]$deferCount = 0,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  $ApplicationScriptLines = [System.Collections.Generic.List[String[]]]@()
  if($interactive.IsPresent){
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
      $ApplicationScriptLines.Add("`t`t`Get-Process -Name `"$($item)`" -ErrorAction SilentlyContinue | Stop-Process -Force") | Out-Null
    }
    $ApplicationScriptLines.Add("`t}") | Out-Null      
  }
  else{
    foreach($item in $blockingProcess){
      $ApplicationScriptLines.Add("`tGet-Process -Name `"$($item)`" -ErrorAction SilentlyContinue | Stop-Process -Force") | Out-Null
    }
  }
  return @(,$ApplicationScriptLines)
}