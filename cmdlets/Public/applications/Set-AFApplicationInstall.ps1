<#
.SYNOPSIS
    Sets the installation script for an application package.
.DESCRIPTION
    Generates installation script lines based on application metadata, installer type, and configuration, then injects them into the deployment toolkit file.
.PARAMETER Application
    The application object containing metadata and install configuration. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Updates the toolkit file with installation script content.
.EXAMPLE
    Set-AFApplicationInstall -Application $app
#>
function Set-AFApplicationInstall {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )
  # Exit if install type is None
  if ($application.install.Type -eq "None") {
    return
  }
  # Prepare installation script lines
  $installScript = [System.Collections.Generic.List[String]]@()
  $installScript.Add("    ## <Perform Installation tasks here>") | Out-Null
  # Determine installer path and handle WIM mounting
  $installerPath = "`$adtSession.dirFiles"
  if ($application.install.wim -and $application.install.type -in @("exe","msi","script")) {
    $mountPath = Join-Path -Path "$($ENV:ALLUSERSPROFILE)" -ChildPath "AFS" -AdditionalChildPath $application.slug
    $installerPath = "`$mountPath"
    foreach ($line in $((Add-AppFactoryAppWIM -section "start" -MountPath $mountPath -LogLevel $LogLevel).SyncRoot)) {
      $installScript.Add($line)
    }
  }
  # Determine installer filename
  if($application.install.installer -and $application.install.installer -ne "===SETUPFILENAME==="){
    $setup_install = $application.install.installer
  }
  else{
    $setup_install = $application.SourceFiles.AppSetupFileName
  }
  # Prepare parameters for installer functions
  $params = @{
    directory          = $installerPath
    AppSetupFileName   = $setup_install
    argumentList       = $application.install.argumentList
    secureArgumentList = $application.install.secureArgumentList
    SuccessExitCodes   = $application.install.SuccessExitCodes.name
    rebootExitCodes    = $application.install.rebootExitCodes.name
    ignoreExitCodes    = $application.install.ignoreExitCodes.name
    LogLevel           = $LogLevel
  }
  if($application.Program.InstallExperience -eq "User"){
    $params.add("userInstall",$true)
  }
  # Generate install script based on installer type
  switch ($application.install.type) {
    'script' {
      foreach($line in $application.Install.script){
        $installScript.Add("`t$($line)") | Out-Null
      }
    }
    'ecno' {
      $installScript.Add("`tPush-Location $($script:installerPath)")  | Out-Null
      if($userInstall.IsPresent){
        $installScript.Add("`tStart-ADTProcessAsUser -FilePath powershell.exe -ArgumentList `"-ExecutionPolicy Bypass -File _action.ps1 install`"")  | Out-Null
      }
      else{
        $installScript.Add("`tStart-Process -FilePath powershell.exe -ArgumentList `"-ExecutionPolicy Bypass -File _action.ps1 install`" -NoNewWindow -Wait")  | Out-Null
      }
      $installScript.Add("`tPop-Location")  | Out-Null
    }
    'exe' {
      foreach ($line in $((Add-AppFactoryAppEXE @params).SyncRoot)) {
        $installScript.Add($line)
      }
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
  # Add WIM unmount script if needed
  if ($application.install.wim -and $application.install.type -in @("exe","msi","script")) {
    foreach ($line in $(Add-AppFactoryAppWIM -section "end" -MountPath $mountPath -LogLevel $LogLevel).SyncRoot) {
      $installScript.Add($line)
    }
  }
  # Add blocking process handling if specified
  if ($application.install.conflictingProcessEnd.name) {
    $params = @{
      interactive     = $false
      blockingProcess = $application.install.conflictingProcessEnd.name
      LogLevel        = $LogLevel
    }
    foreach ($line in $((Add-AppFactoryApplicationBlockingProcess @params -LogLevel $LogLevel).SyncRoot)) {
      $installScript.Add($line)
    }
  }
  # Inject generated install script into toolkit file
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $ToolkitFile = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.ps1"
  $outputFile = Get-Content -Path $ToolkitFile
  $outputFile -replace "    ## <Perform Installation tasks here>",$($installScript -join "`r`n") | Set-Content -Path $ToolkitFile -Encoding "utf8" -Force -Confirm:$false
}