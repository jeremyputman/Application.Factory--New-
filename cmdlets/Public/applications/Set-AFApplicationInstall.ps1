function Set-AFApplicationInstall{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )
  if ($application.install.Type -eq "None") {
    return
  }  
  $installScript = [System.Collections.Generic.List[String]]@()
  $installScript.Add("    ## <Perform Installation tasks here>") | Out-Null

  $installerPath = "`$adtSession.dirFiles"
  # If the application is to use a mounted WIM
  if ($application.install.wim) {
    throw "Not Implemented - WIM"
    # TODO: Install - WIM
  }
  # If application installer is set, and it is not the default setup filename, use it as the installer path
  if($application.install.installer -and $application.install.installer -ne "===SETUPFILENAME==="){
    $setup_install = $application.install.installer
  }
  else{
    $setup_install = $application.SourceFiles.AppSetupFileName
  }
  $params = @{
    directory          = $installerPath
    AppSetupFileName   = $setup_install
    argumentList       = $application.install.argumentList
    secureArgumentList = $application.install.secureArgumentList
    SuccessExitCodes   = $application.install.SuccessExitCodes
    rebootExitCodes    = $application.install.rebootExitCodes
    ignoreExitCodes    = $application.install.ignoreExitCodes  
    LogLevel           = $LogLevel  
  }  
  if($application.Program.InstallExperience -eq "User"){
    $params.add("userInstall",$true)
  }

  switch ($application.install.type) {
    'script' {
      throw "Not Implemented - Script"
      # TODO: Install - SCRIPT
    }
    'powershell' {
      throw "Not Implemented - PowerShell"
      # TODO: Install - PowerShell
    }
    'ecno' {
      throw "Not Implemented - ECNO"
      # TODO: Install - ECNO
    }
    'exe' {
      throw "Not Implemented - EXE"
      # TODO: Install - EXE
    }
    'msi' {
      $params.add("Transforms", $application.install.Transforms)
      $params.add("Action", "Install")
      $params.add("additionalArgumentList", $application.install.additionalArgumentList)
      $params.add("SkipMSIAlreadyInstalledCheck", $application.Install.SkipMSIAlreadyInstalledCheck)
      foreach ($line in $((Add-AppFactoryAppMSI @params).SyncRoot)) {
        $installScript.Add($line)
      }        
    }
  }
  if ($application.install.wim) {
    throw "Not Implemented - WIM"
    # TODO: Install - WIM
  }

  if ($application.install.conflictingProcessEnd) {
    $params = @{
      interactive     = $false
      blockingProcess = $application.install.conflictingProcessEnd
      LogLevel        = $LogLevel
    }
    foreach ($line in $((Add-AppFactoryApplicationBlockingProcess @params -LogLevel $LogLevel).SyncRoot)) {
      $installScript.Add($line)
    }
  }  

  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $ToolkitFile = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.ps1"
  $outputFile = Get-Content -Path $ToolkitFile
  $outputFile -replace "    ## <Perform Installation tasks here>",$($installScript -join "`r`n") | Set-Content -Path $ToolkitFile -Encoding "utf8" -Force -Confirm:$false
}