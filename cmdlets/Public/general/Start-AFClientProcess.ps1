function Start-AFClientProcess {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][string]$application_name,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel = "Verbose",
    [Parameter()][switch]$Force,
    [Parameter()][switch]$DownloadOnly
  )
  # Set Application Factory API settings
  $params = @{
    configFile    = $configFile
    EnableLogging = $EnableLogging.IsPresent
    LogLevel      = $LogLevel
    Workspace     = $workspace
  }  
  $script:log_target = "Application Factory Client"
  Set-AFClientSettings @params
  # Get current list of applications

  for ($tries = 0; $tries -lt $script:retries; $tries++) {
    $err = $false
    try {
      $params = @{
        id = $script:client_id
      }
      if($application_name){
        $params.application_id = $application_name
      }
      $configurations = Get-AFApplicationConfigurations @params
      Write-AFLogEntry -Message "[Application Factory] :: There are <c='green'>$($configurations.count)</c> applications configured in AppFactory"  -Tag "Process"
      if($configurations.count -eq 0){
        Write-AFLogEntry -Message "[Application Factory] :: No applications found for processing."  -Level  "Warning" -Tag "Process"
        return
      }
      Write-AFLogEntry -Message "[Application Factory] :: Getting Current Intune Application List." -Tag "Process"
      Connect-MSIntuneGraph -TenantID $script:appregistration_tenant -ClientID $script:appregistration_client -ClientSecret $script:appregistration_secret | Out-Null
      $app_params = @{}
      if($application_name){
        $app_params.DisplayName = "$($script:app_prefix)$($application_name)*"
      }
      elseif($script:app_prefix){
        $app_params.DisplayName = "$($script:app_prefix)*"
      }
      $intune_apps = Get-IntuneWin32App @app_params
      foreach($configuration in $configurations){
        Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Starting Process" -Tag "Process", $configuration.application.Name
        # Determine what version we should be looking for
        if($configuration.application.latest_version.raw_version){
          $script:published_version = $configuration.application.latest_version.raw_version
        }
        else{
          $script:published_version = $configuration.version.raw_version
        }
        $current_deployed = $intune_apps | Where-Object {$_.Notes -match "AppFactoryID:$($configuration.application.id)"} | Sort-Object createdDateTime -descending
        if($current_deployed -and $current_deployed.displayversion -eq $script:published_version -and -not $Force.IsPresent){
          Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Application with version $($script:published_version) already exists in Intune. Skipping deployment." -Level "Warning" -Tag "Process", $configuration.application.Name
        }
        else{
          if ($Force.IsPresent) {
            Write-AFLogEntry  -Message "[<c='green'>$($configuration.application.Name)</c>] :: <c='yellow'>Force flag</c> is set " -Tag "Process", $configuration.application.Name
          }          
          try{
            Get-AFApplicationClientFiles -configuration $configuration
            Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Downloaded files." -Tag "Applications", "$($configuration.application.Name)"
            if($DownloadOnly.IsPresent){
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: <c='yellow'>Download only flag</c> is set. Skipping upload and assignment." -Level "Warning" -Tag "Process", $configuration.application.Name
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Completed Process" -Tag "Process", $configuration.application.Name
              continue
            }
            Publish-AFApplicationClientApp -configuration $configuration
            Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Created Intune File." -Tag "Applications", "$($configuration.application.Name)"
            if($configuration.copy_previous_assignments -and $current_deployed.count -gt 0){
              Copy-AFApplicationClientGroups -intune_apps $current_deployed
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Copied group assignments." -Tag "Applications", "$($configuration.application.Name)"
            }
            Set-AFApplicationClientGroups -configuration $configuration
            Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Set group assignments." -Tag "Applications", "$($configuration.application.Name)"
            if($configuration.esp_assignments){
              Set-AFApplicationClientESPAssignments -configuration $configuration
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Added ESP assignments." -Tag "Applications", "$($configuration.application.Name)"
            }
            if($configuration.unassign_previous_assignments){
              foreach($app in $current_deployed){
                $originalWarningPreference = $WarningPreference
                $WarningPreference = 'SilentlyContinue'
                Remove-IntuneWin32AppAssignment -id $app.id -WarningAction SilentlyContinue | Out-Null
                $WarningPreference = $originalWarningPreference
              }
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Unassigned previous assignments." -Tag "Applications", "$($configuration.application.Name)"
            }
            for($x = $configuration.keep_previous_versions; $x -lt $current_deployed.count; $x++){
              Remove-IntuneWin32App -id $current_deployed[$x].id
            }
            Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Removed previous versions." -Tag "Applications", "$($configuration.application.Name)"
          }
          catch{
            $err = $true
            $display_name = "$($script:app_prefix)$($configuration.application.Name)*"
            $failed_app = Get-IntuneWin32App -DisplayName $display_name
            foreach($id in $(($failed_app | Where-Object {$_.uploadState -eq 0} | Select-Object id).id)){
              Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Upload failed. Cleaning up Intune application." -Level "Warning" -Tag "Process", $configuration.application.Name
              Remove-IntuneWin32App -id $id
            }            
            Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: $($_.Exception.Message)" -Level "Error" -Tag "Process", $configuration.application.Name
            continue
          }
        }
        # Determine output file path for installer
        $OutFilePath = Join-Path -Path $script:working_folder -ChildPath "Download" -AdditionalChildPath $configuration.application.slug
        Remove-Item -Path $OutFilePath -Recurse -Force -ErrorAction "SilentlyContinue" | Out-Null
        Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] :: Completed Process" -Tag "Process", "$($configuration.application.Name)"
      }
    }
    catch {
      $err = $true
      Write-AFLogEntry -Message $_.Exception.Message -Level "Error" -Tag "Process", "$($configuration.application.Name)"
      $_
    }
    finally {

    }
    


    if (-not $err) {
      break
    }
    else {
      Write-AFLogEntry -Message "[Application Factory] :: Errors encountered during processing. Retrying... ($($tries+1)/$($script:retries))" -Level "Warning" -Tag "Process"
      Start-Sleep -Seconds 180
    }
  }
  $OutFilePath = Join-Path -Path $script:working_folder -ChildPath "Download"
  Remove-Item -Path $OutFilePath -Recurse -Force -ErrorAction "SilentlyContinue" | Out-Null
}