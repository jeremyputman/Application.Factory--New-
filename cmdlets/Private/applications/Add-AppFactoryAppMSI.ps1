function Add-AppFactoryAppMSI{
  [cmdletbinding()]
  [OutputType([System.Collections.Generic.List[String[]]])]
  param(
    [Parameter()][String]$directory,    
    [Parameter(Mandatory = $true, ParameterSetName = "AppSetupFileName")][ValidateNotNullOrEmpty()][String]$AppSetupFileName,
    [Parameter(Mandatory = $true, ParameterSetName = "productcode")][ValidateNotNullOrEmpty()][String]$productcode,
    [Parameter()][ValidateSet("Install", "Uninstall")][string]$Action = "Install",
    [Parameter()][string]$argumentList,
    [Parameter()][string]$additionalArgumentList,
    [Parameter()][bool]$secureArgumentList,
    [Parameter()][bool]$SkipMSIAlreadyInstalledCheck,
    [Parameter()][string]$Transforms,
    [Parameter()][switch]$userInstall,
    [Parameter()][int[]]$SuccessExitCodes,
    [Parameter()][int[]]$rebootExitCodes,
    [Parameter()][int[]]$ignoreExitCodes,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"
  )
  $ApplicationScriptLines = [System.Collections.Generic.List[String[]]]@()
  if($PSBoundParameters.ContainsKey("AppSetupFileName") -and $AppSetupFileName){
    if($directory -ne ""){
      $executePath = "`"`$($($directory))\`$(`$AppSetupFileName)`""
    }
    else{
      $executePath = "`"`$(`$AppSetupFileName)`""
    }
    if($userInstall.IsPresent){
      $execute = "Start-ADTMsiProcessAsUser -Action `"$($Action)`" -FilePath $($executePath)"
    }
    else{
      $execute = "Start-ADTMsiProcess -Action `"$($Action)`" -FilePath $($executePath)"
    }
    $ApplicationScriptLines.Add("`t`$AppSetupFileName = `"$($AppSetupFileName)`"") | Out-Null
  }
  else{
    if($userInstall.IsPresent){
      $execute = "Start-ADTMsiProcessAsUser -Action `"$($Action)`" -productcode `"$($productcode)`""
    }
    else{
      $execute = "Start-ADTMsiProcess -Action `"$($Action)`" -productcode `"$($productcode)`""
    }
  }
  if ($PSBoundParameters.ContainsKey("Transforms")  -and $Transforms) {
    $ApplicationScriptLines.Add("`t`$Transforms = `"$($Transforms)`"") | Out-Null
    $execute = "$($execute) -Transforms `"`$($($directory))\`$(`$Transforms)`""
  }
  if ($PSBoundParameters.ContainsKey("additionalArgumentList") -and $additionalArgumentList) {
    $ApplicationScriptLines.Add("`t`$additionalArgumentList = `"$($additionalArgumentList)`"") | Out-Null
    $execute = "$($execute) -AdditionalArgumentList `$additionalArgumentList"
  }   
  if ($PSBoundParameters.ContainsKey("argumentList") -and $argumentList) {
    $ApplicationScriptLines.Add("`t`$argumentList = `"$($argumentList)`"") | Out-Null
    $execute = "$($execute) -argumentList `$argumentList"
  }  
  if ($PSBoundParameters.ContainsKey("secureArgumentList") -and $secureArgumentList) {$execute = "$($execute) -secureArgumentList"}  
  if ($PSBoundParameters.ContainsKey("SkipMSIAlreadyInstalledCheck") -and $SkipMSIAlreadyInstalledCheck) {$execute = "$($execute) -SkipMSIAlreadyInstalledCheck"}  
  if ($PSBoundParameters.ContainsKey("SuccessExitCodes") -and $SuccessExitCodes) {$execute = "$($execute) -SuccessExitCodes $($SuccessExitCodes -join ",")"}  
  if ($PSBoundParameters.ContainsKey("rebootExitCodes") -and $rebootExitCodes) {$execute = "$($execute) -rebootExitCodes $($rebootExitCodes -join ",")"}  
  if ($PSBoundParameters.ContainsKey("ignoreExitCodes") -and $ignoreExitCodes) {$execute = "$($execute) -ignoreExitCodes $($ignoreExitCodes -join ",")"}  
  $ApplicationScriptLines.Add("`t$($execute)") | Out-Null
  return @(,$ApplicationScriptLines)  		    
}