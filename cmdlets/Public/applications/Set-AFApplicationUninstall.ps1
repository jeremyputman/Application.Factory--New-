function Set-AFApplicationUninstall{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )  
  if ($application.Uninstall.Type -eq "None") {
    return
  }
  $uninstallScript = [System.Collections.Generic.List[String]]@()
  $uninstallScript.Add("    ## <Perform Uninstallation tasks here>") | Out-Null  
  if($application.Uninstall.dirFiles -or $application.Uninstall.type -eq "ECNO"){
    $uninstallerPath = "`$adtSession.dirFiles"
  }
  else{
    $uninstallerPath = ""
  } 
  if ($application.Uninstall.wim) {
    throw "Not Implemented - WIM"
    # TODO: Uninstall - WIM
  }    
  if($application.Uninstall.installer -and $application.Uninstall.installer -ne "===SETUPFILENAME==="){
    $setup_uninstall = $application.Uninstall.installer
  }
  else{
    $setup_uninstall = $application.SourceFiles.AppSetupFileName
  }  
  $params = @{
    directory          = $uninstallerPath
    AppSetupFileName   = $setup_uninstall
    argumentList       = $application.Uninstall.argumentList
    secureArgumentList = $application.Uninstall.secureArgumentList
    SuccessExitCodes   = $application.Uninstall.SuccessExitCodes
    rebootExitCodes    = $application.Uninstall.rebootExitCodes
    ignoreExitCodes    = $application.Uninstall.ignoreExitCodes  
    LogLevel           = $LogLevel  
  }  
  switch ($application.Uninstall.type) {
    'msi' {
      throw "Not Implemented - MSI"
      # TODO: Uninstall - MSI
    } 
    'exe' {
      throw "Not Implemented - EXE"
      # TODO: Uninstall - EXE
    } 
    'name' {
      $execute = "Uninstall-ADTApplication -Name `"$($application.Uninstall.namematch)`""
      if($application.Uninstall.filterScript){$execute = "$($execute) -filterScript `{$($application.Uninstall.filterScript)`}"}
      $uninstallScript.Add("`t$($execute)")  | Out-Null      
    } 
    'guid' {
      throw "Not Implemented - GUID"
      # TODO: Uninstall - GUID
    } 
    'ecno' {
      throw "Not Implemented - ECNO"
      # TODO: Uninstall - ECNO
    } 
    'script' {
      throw "Not Implemented - Script"
      # TODO: Uninstall - SCRIPT
    } 
    'powershell' {
      throw "Not Implemented - Powershell"
      # TODO: Uninstall - PowerShell
    }
  }
  if ($application.Uninstall.wim) {
    throw "Not Implemented - WIM"
    # TODO: Uninstall - WIM
  }  
  if ($application.Uninstall.conflictingProcessEnd) {
    $params = @{
      interactive     = $false
      blockingProcess = $application.Uninstall.conflictingProcessEnd
      LogLevel        = $LogLevel
    }
    foreach ($line in $((Add-AppFactoryApplicationBlockingProcess @params -LogLevel $LogLevel).SyncRoot)) {
      $uninstallScript.Add($line)
    }
  } 
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $ToolkitFile = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.ps1"
  $outputFile = Get-Content -Path $ToolkitFile
  $outputFile -replace "    ## <Perform Uninstallation tasks here>",$($uninstallScript -join "`r`n") | Set-Content -Path $ToolkitFile -Encoding "utf8" -Force -Confirm:$false       
}