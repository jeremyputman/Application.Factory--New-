function Start-AFClientProcess {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $true)][string]$workspace,
    [Parameter()][string]$application_name,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][switch]$Force,
    [Parameter()][switch]$DownloadOnly
  )
  # Set Application Factory API settings
  $params = @{
    configFile    = $configFile
    EnableLogging = $EnableLogging.IsPresent
    Workspace     = $workspace
  }  
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
      Write-PSFMessage -Message "There are <c='green'>$($configurations.count)</c> applications configured in AppFactory"  -Level  "Output" -Tag "Process" -Target "Application Factory Client"
      if($configurations.count -eq 0){
        Write-PSFMessage -Message "No applications found for processing."  -Level  "Warning" -Tag "Process" -Target "Application Factory Client"
        return
      }
      Write-PSFMessage -Message "Getting Current Intune Application List."  -Level  "Output" -Tag "Process" -Target "Application Factory Client"
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
        Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Starting Process"  -Level  "Output" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
        # Determine what version we should be looking for
        if($configuration.application.latest_version.raw_version){
          $script:published_version = $configuration.application.latest_version.raw_version
        }
        else{
          $script:published_version = $configuration.version.raw_version
        }
        $current_deployed = $intune_apps | Where-Object {$_.Notes -match "AppFactoryID:$($configuration.application.id)"} | Sort-Object createdDateTime -descending
        if($current_deployed -and $current_deployed.displayversion -eq $script:published_version -and -not $Force.IsPresent){
          Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Application with version $($script:published_version) already exists in Intune. Skipping deployment." -Level "Warning" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
        }
        else{
          try{
            Get-AFApplicationClientFiles -configuration $configuration -LogLevel "Output"   
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Downloaded files." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            if($DownloadOnly.IsPresent){
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Download only flag is set. Skipping upload and assignment." -Level "Warning" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
              continue
            }
            Publish-AFApplicationClientApp -configuration $configuration -LogLevel "Output"
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Created Intune File." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            if($configuration.copy_previous_assignments -and $current_deployed.count -gt 0){
              Copy-AFApplicationClientGroups -intune_apps $current_deployed -LogLevel "Output"
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Copied group assignments." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            }
            Set-AFApplicationClientGroups -configuration $configuration -LogLevel "Output"
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Set group assignments." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            if($configuration.esp_assignments){
              Set-AFApplicationClientESPAssignments -configuration $configuration -LogLevel "Output"
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Added ESP assignments." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            }
            if($configuration.unassign_previous_assignments){
              foreach($app in $current_deployed){
                $originalWarningPreference = $WarningPreference
                $WarningPreference = 'SilentlyContinue'
                Remove-IntuneWin32AppAssignment -id $app.id -WarningAction SilentlyContinue | Out-Null
                $WarningPreference = $originalWarningPreference
              }
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Unassigned previous assignments." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
            }
            for($x = $configuration.keep_previous_versions; $x -lt $current_deployed.count; $x++){
              Remove-IntuneWin32App -id $current_deployed[$x].id
            }
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Removed previous versions." -Level "Output" -Tag "Applications", "$($configuration.application.Name)" -Target "Application Factory Client"
          }
          catch{
            $err = $true
            $failed_app = Get-IntuneWin32App -DisplayName $app_params.DisplayName
            foreach($id in $(($failed_app | Where-Object {$_.uploadState -eq 0} | Select-Object id).id)){
              Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Upload failed. Cleaning up Intune application." -Level "Warning" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
              Remove-IntuneWin32App -id $id
            }            
            Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: $($_.Exception.Message)" -Level "Error" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
            continue
          }
        }
        Write-PSFMessage -Message "[<c='green'>$($configuration.application.Name)</c>] :: Completed Process"  -Level  "Output" -Tag "Process", $configuration.application.Name -Target "Application Factory Client"
      }
    }
    catch {
      $err = $true
      Write-PSFMessage -Message $_.Exception.Message -Level "Error" -Tag "Process" -Target "Application Factory Client"
      $_
    }
    finally {

    }
    


    if (-not $err) {
      break
    }
    else {
      Write-PSFMessage -Message "Errors encountered during processing. Retrying... ($($tries+1)/$($script:retries))" -Level "Warning" -Tag "Process" -Target "Application Factory Client"
      Start-Sleep -Seconds 60
    }
  }
}