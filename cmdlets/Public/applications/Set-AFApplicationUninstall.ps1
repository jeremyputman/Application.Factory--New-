<#
.SYNOPSIS
    Sets the uninstallation script for an application package.
.DESCRIPTION
    Generates uninstallation script lines based on application metadata, uninstaller type, and configuration, then injects them into the deployment toolkit file.
.PARAMETER Application
    The application object containing metadata and uninstall configuration. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Updates the toolkit file with uninstallation script content.
.EXAMPLE
    Set-AFApplicationUninstall -Application $app
#>
function Set-AFApplicationUninstall {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )  
  # Exit if uninstall type is None
  if ($application.Uninstall.Type -eq "None") {
    return
  }
  # Prepare uninstallation script lines
  $uninstallScript = [System.Collections.Generic.List[String]]@()
  $uninstallScript.Add("    ## <Perform Uninstallation tasks here>") | Out-Null
  # Determine uninstaller path and handle WIM mounting
  if($application.Uninstall.dirFiles -or $application.Uninstall.type -eq "ECNO"){
    $uninstallerPath = "`$adtSession.dirFiles"
  }
  else{
    $uninstallerPath = ""
  }
  if ($application.Uninstall.wim -and $application.Uninstall.type -in @("exe","msi","script")) {
    $mountPath = Join-Path -Path "$($ENV:ALLUSERSPROFILE)" -ChildPath "AFS" -AdditionalChildPath $application.slug
    $uninstallerPath = "`$mountPath"
    foreach ($line in $((Add-AppFactoryAppWIM -section "start" -MountPath $mountPath -LogLevel $LogLevel).SyncRoot)) {
      $uninstallScript.Add($line)
    }  
  }
  # Determine uninstaller filename
  if($application.Uninstall.installer -and $application.Uninstall.installer -ne "===SETUPFILENAME==="){
    $setup_uninstall = $application.Uninstall.installer
  }
  else{
    $setup_uninstall = $application.SourceFiles.AppSetupFileName
  }
  # Prepare parameters for uninstaller functions
  $params = @{
    directory          = $uninstallerPath
    AppSetupFileName   = $setup_uninstall
    argumentList       = $application.Uninstall.argumentList
    secureArgumentList = $application.Uninstall.secureArgumentList
    SuccessExitCodes   = $application.Uninstall.SuccessExitCodes.name
    rebootExitCodes    = $application.Uninstall.rebootExitCodes.name
    ignoreExitCodes    = $application.Uninstall.ignoreExitCodes.name
    LogLevel           = $LogLevel
  }
  # Generate uninstall script based on uninstaller type
  switch ($application.Uninstall.type) {
    'msi' {
      $params.add("Transforms", $application.Uninstall.Transforms)
      $params.add("Action", "Uninstall")
      $params.add("additionalArgumentList", $application.Uninstall.additionalArgumentList)
      foreach ($line in $((Add-AppFactoryAppMSI @params).SyncRoot)) {
        $uninstallScript.Add($line)
      }   
    } 
    'exe' {
      foreach ($line in $((Add-AppFactoryAppEXE @params).SyncRoot)) {
        $uninstallScript.Add($line)
      }  
    } 
    'name' {
      $execute = "Uninstall-ADTApplication -Name `"$($application.Uninstall.namematch)`""
      if($application.Uninstall.filterScript){$execute = "$($execute) -filterScript `{$($application.Uninstall.filterScript)`}"}
      $uninstallScript.Add("`t$($execute)")  | Out-Null      
    } 
    'guid' {
      $uninstallScript.Add("`tUninstall-ADTApplication -ProductCode '$($application.Uninstall.productCode)'")  | Out-Null
    } 
    'ecno' {
      $uninstallScript.Add("`tPush-Location $($script:uninstallerPath)")  | Out-Null 
      if($userInstall.IsPresent){
        $uninstallScript.Add("`tStart-ADTProcessAsUser -FilePath powershell.exe -ArgumentList `"-ExecutionPolicy Bypass -File _action.ps1 remove`"")  | Out-Null   
      }
      else{
        $uninstallScript.Add("`tStart-Process -FilePath powershell.exe -ArgumentList `"-ExecutionPolicy Bypass -File _action.ps1 remove`" -NoNewWindow -Wait")  | Out-Null   
      }      
      $uninstallScript.Add("`tPop-Location")  | Out-Null 
    } 
    'script' {
      foreach($line in $application.Uninstall.script){
        $uninstallScript.Add("`t$($line)") | Out-Null
      }
    } 
  }
  # Add WIM unmount script if needed
  if ($application.Uninstall.wim -and $application.Uninstall.type -in @("exe","msi","script")) {
    foreach ($line in $(Add-AppFactoryAppWIM -section "end" -MountPath $mountPath -LogLevel $LogLevel).SyncRoot) {
      $uninstallScript.Add($line)
    } 
  }
  # Add blocking process handling if specified
  if ($application.Uninstall.conflictingProcessEnd.name) {
    $params = @{
      interactive     = $false
      blockingProcess = $application.Uninstall.conflictingProcessEnd.name
      LogLevel        = $LogLevel
    }
    foreach ($line in $((Add-AppFactoryApplicationBlockingProcess @params -LogLevel $LogLevel).SyncRoot)) {
      $uninstallScript.Add($line)
    }
  }
  # Inject generated uninstall script into toolkit file
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $ToolkitFile = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.ps1"
  $outputFile = Get-Content -Path $ToolkitFile
  $outputFile -replace "    ## <Perform Uninstallation tasks here>",$($uninstallScript -join "`r`n") | Set-Content -Path $ToolkitFile -Encoding "utf8" -Force -Confirm:$false       
}