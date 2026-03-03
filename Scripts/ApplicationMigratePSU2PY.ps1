Clear-Host
Import-Module -Name "C:\DevOps\Application.Factory\Module\Application.Factory" -Force

$API_KEY = "### API KEY ###"
$BASE_API = "### APP FACTORY URI ###"

# Admin
Set-AFSettings -api_key $API_KEY -uri $BASE_API

# Get the list of clients
$dataPath = "C:\Support\test\Application-Factory-Applications"
$application_path = Join-Path -Path $dataPath -ChildPath "Apps"
$applications = Get-ChildItem -Path $application_path -Filter "*.json" -Recurse

# appsourcemap
$appsource = @{
  "StorageAccount" = "azure_storage"
  "Winget" = "winget"
  "Evergreen" = "evergreen"
  "SharePoint" = "sharepoint"
  "PSADT" = "psadt"
  "ECNO" = "ecno"
  "Local Storage" = "local_storage"
}

# Create Applications
foreach($application in $applications){
  $data = Get-Content -Path $application.FullName | ConvertFrom-JSON
  $body = @{
    id = $data.GUID
  }
  foreach($key in $data.information.PSObject.Properties.Name){
    if($key -eq "AppFolderName"){continue}
    if($data.Information.$key){
      $body[$key.ToLower()] = $data.information.$key
    }
  }
  foreach($key in $data.sourcefiles.PSObject.Properties.Name){
    if($key -in @("packageversion","packagesource", "filteroptions", "intunepackage", "ExtraFiles")){continue}
    if($data.sourcefiles.$key -and $null -ne $data.sourcefiles.$key){
      if($key -eq "AppSource"){
        $body[$key.ToLower()] = $appsource[$data.sourcefiles.$key]
      }
      else {
        $body[$key.ToLower()] = $data.sourcefiles.$key
      }
    }
  }
  foreach($key in $data.sourcefiles.FilterOptions.PSObject.Properties.Name){
    $body["filter_$($key.ToLower())"] = $data.sourcefiles.FilterOptions.$key
  }
  foreach($key in $data.install.PSObject.Properties.Name){
    if($data.install.$key -and $null -ne $data.install.$key){
      if($data.install.$key -eq "===SETUPFILENAME==="){continue}
      $val = $data.install.$key
      if(-not [int]::TryParse($val, [ref]$null) -and $key -notin @("script")){
        $val = $val.tolower()
      } 
      if($key -eq "script"){
        $val = $val -join "`r`n"
      }      
      $body["install_$($key.ToLower())"] = $val
    }
  }
  foreach($key in $data.uninstall.PSObject.Properties.Name){
    if($data.uninstall.$key -and $null -ne $data.uninstall.$key){
      if($data.uninstall.$key -eq "===SETUPFILENAME==="){continue}
      $val = $data.uninstall.$key
      if(-not [int]::TryParse($val, [ref]$null) -and $key -notin @("script")){
        $val = $val.tolower()
      }
      if($key -eq "script"){
        $val = $val -join "`r`n"
      }
      $body["uninstall_$($key.ToLower())"] = $val
    }
  }  
  foreach($key in $data.program.PSObject.Properties.Name){
    if($key -in @("uninstallcommand", "installcommand","InstallCommandInteractive","UninstallCommandInteractive")){continue}
    if($data.program.$key){
      $val = $data.program.$key.tolower()
      if($key -in @("allowavailableuninstall")){
        $val = [bool]$val
      }
      $body[$key.ToLower()] = $val
    }
  }   
  foreach($key in $data.RequirementRule.PSObject.Properties.Name){
    if($data.RequirementRule.$key -and $null -ne $data.RequirementRule.$key){
      $val = $data.RequirementRule.$key.tolower()
      if($key -eq "minimumsupportedwindowsrelease"){
        $val = $val.toUpper()
      }
      $body["$($key.ToLower())"] = $val
    }
  } 
  foreach($key in $data.DetectionRule[0].PSObject.Properties.Name){
    if($key -eq "DetectionType"){continue}
    if($data.DetectionRule[0].$key){
      $val = $data.DetectionRule[0].$key
      if($val -eq "<replaced_by_pipeline>"){continue}
      if($key -eq "keypath"){
        $val = ($val -split "\\")[-1]
      }
      if($key -in @("Check32BitOn64System", "runas32bit", "enforcesignaturecheck")){
        $val = [bool]$val
      }
      if($key -eq "type"){
        if($val -eq "registry"){
          if($data.DetectionRule[0].DetectionMethod -eq "versioncomparison"){
            $val = "registry_version"
          }
          else{
            $val = "registry_existence"
          }
        }
        elseif($val -eq "script"){
          $val = "script"
        }
        elseif($val -eq "MSI"){
          $val = "msi"
        }        
      }
      if($key -eq "scriptfile"){
        $detection_script_path = Join-Path -Path $application.Directory.FullName -ChildPath $val
        $val = Get-Content -Path $detection_script_path -Raw
      }

      if($key -eq "detectionmethod" -and $val -eq "versioncomparison"){
        $val = "versionComparison"
      }
      if($key -eq "detectionmethod" -and $val -eq "Existence"){
        $val = "existence"
      }      
      if($key -eq "detectionmethod" -and $val -eq "Existence"){
        $val = "existence"
      }         

  

      $body["detection_$($key.ToLower())"] = $val
    }
  }    

  #return New-AFApplication @body | ConvertTo-JSON -depth 5 | Set-Clipboard
  New-AFApplication @body
  #break
}

  # $sections = @{
  #   detectionrule   = @('detection_type', 'detection_scriptfile', 'detection_enforcesignaturecheck', 'detection_runas32bit', 'detection_detectionmethod', 'detection_keypath', 'detection_valuename', 'detection_operator', 'detection_productversionoperator', 'detection_value', 'detection_check32biton64system')
  # }


    # [Parameter()][string]$notes,
    # [Parameter()][string]$owner,
    # [Parameter()][string]$information_url,
    # [Parameter()][string]$privacy_url,
    # [Parameter(Mandatory = $true)][ValidateSet('azure_storage', 'winget', 'evergreen', 'sharepoint', 'psadt', 'ecno', 'local_storage')][string]$appsource,
    # [Parameter()][string]$appid,
    # [Parameter()][string]$appsetupfilename,
    # [Parameter()][string]$storageaccountcontainername,
    # [Parameter()][string]$filter_architecture,
    # [Parameter()][string]$filter_platform,
    # [Parameter()][string]$filter_channel,
    # [Parameter()][string]$filter_type,
    # [Parameter()][string]$filter_installer_type,
    # [Parameter()][string]$filter_release,
    # [Parameter()][string]$filter_language,
    # [Parameter()][string]$filter_imagetype,
    # [Parameter()][string]$dependson,
    # [Parameter()][bool]$active,
    # [Parameter()][datetime]$lastupdate,
    # [Parameter()][bool]$pauseupdate,
    # [Parameter()][string[]]$publishto,
    # [Parameter()][string]$versions,
    # [Parameter(Mandatory = $true)][ValidateSet('none', 'script', 'powershell', 'ecno', 'exe', 'msi')][string]$install_type,
    # [Parameter()][string]$install_argumentList,
    # [Parameter()][string]$install_additionalArgumentList,
    # [Parameter()][bool]$install_secureArgumentList,
    # [Parameter()][string]$install_installer,
    # [Parameter()][string]$install_transforms,
    # [Parameter()][bool]$install_SkipMSIAlreadyInstalledCheck,
    # [Parameter()][string]$install_script,
    # [Parameter()][bool]$install_wim,
    # [Parameter()][string]$install_successExitCodes,
    # [Parameter()][string[]]$install_rebootExitCodes,
    # [Parameter()][string[]]$install_ignoreExitCodes,
    # [Parameter()][string[]]$install_conflictingProcessStart,
    # [Parameter()][string[]]$install_conflictingProcessEnd,
    # [Parameter(Mandatory = $true)][ValidateSet('none', 'msi', 'exe', 'name', 'guid', 'ecno', 'script', 'powershell')][string]$uninstall_type,
    # [Parameter()][string]$uninstall_name,
    # [Parameter()][string]$uninstall_namematch,
    # [Parameter()][string]$uninstall_productcode,
    # [Parameter()][string]$uninstall_filterscript,
    # [Parameter()][string]$uninstall_argumentlist,
    # [Parameter()][string]$uninstall_additionalargumentlist,
    # [Parameter()][bool]$uninstall_secureargumentlist,
    # [Parameter()][string]$uninstall_script,
    # [Parameter()][string]$uninstall_installer,
    # [Parameter()][bool]$uninstall_wim,
    # [Parameter()][bool]$uninstall_dirfiles,
    # [Parameter()][string[]]$uninstall_ignoreexitcodes,
    # [Parameter()][string[]]$uninstall_conflictingprocessstart,
    # [Parameter()][string[]]$uninstall_conflictingprocessend,
    # [Parameter()][ValidateSet('user', 'system')][string]$installeexperience,
    # [Parameter()][ValidateSet('suppress', 'force', 'basedOnReturnCode', 'allow')][string]$devicerestartbehavior,
    # [Parameter()][bool]$allowavailableuninstall,
    # [Parameter()][ValidateSet('W10_1607', 'W10_1703', 'W10_1709', 'W10_1809', 'W10_1909', 'W10_2004', 'W10_20H2', 'W10_21H1', 'W10_21H2', 'W10_22H2', 'W11_21H2', 'W11_22H2')][string]$minimumsupportedwindowsrelease,
    # [Parameter()][ValidateSet('x86', 'x64', 'all', 'arm64')][string]$architecture,
    # [Parameter()][int]$minimumfreediskspaceinmb,
    # [Parameter()][int]$minimummemoryinmb,
    # [Parameter(Mandatory = $true)][ValidateSet('msi', 'registry_version', 'registry_existence', 'script')][string]$detection_type,
    # [Parameter()][string]$detection_scriptfile,
    # [Parameter()][bool]$detection_enforcesignaturecheck,
    # [Parameter()][bool]$detection_runas32bit,
    # [Parameter()][ValidateSet('existence', 'versionComparison')][string]$detection_detectionmethod,
    # [Parameter()][string]$detection_keypath,
    # [Parameter()][string]$detection_valuename,
    # [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_operator,
    # [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_productversionoperator,
    # [Parameter()][string]$detection_value,
    # [Parameter()][bool]$detection_check32biton64system