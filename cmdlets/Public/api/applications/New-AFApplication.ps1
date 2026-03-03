function New-AFApplication {
  [cmdletbinding()]
  param(
    [Parameter()][string]$id,
    [Alias("DisplayName")][Parameter(Mandatory = $false)][string]$name,
    [Parameter(Mandatory = $false)][string]$description,
    [Parameter(Mandatory = $false)][string]$publisher,
    [Parameter()][string]$notes,
    [Parameter()][string]$owner,
    [Alias("informationurl")][Parameter()][string]$information_url,
    [Alias("privacyurl")][Parameter()][string]$privacy_url,
    [Parameter(Mandatory = $false)][ValidateSet('azure_storage', 'winget', 'evergreen', 'sharepoint', 'psadt', 'ecno', 'local_storage')][string]$appsource,
    [Parameter()][string]$appid,
    [Parameter()][string]$appsetupfilename,
    [Parameter()][string]$storageaccountcontainername,
    [Parameter()][string]$filter_architecture,
    [Parameter()][string]$filter_platform,
    [Parameter()][string]$filter_channel,
    [Parameter()][string]$filter_type,
    [Alias("filter_installertype")][Parameter()][string]$filter_installer_type,
    [Parameter()][string]$filter_release,
    [Parameter()][string]$filter_language,
    [Parameter()][string]$filter_imagetype,
    [Parameter()][string]$dependson,
    [Parameter()][bool]$active,
    [Parameter()][datetime]$lastupdate,
    [Parameter()][bool]$pauseupdate,
    [Parameter()][string[]]$publishto,
    [Alias("AppVersion")][Parameter()][string[]]$versions,
    [Parameter(Mandatory = $false)][ValidateSet('none', 'script', 'powershell', 'ecno', 'exe', 'msi')][string]$install_type,
    [Parameter()][string]$install_argumentList,
    [Parameter()][string]$install_additionalArgumentList,
    [Parameter()][bool]$install_secureArgumentList,
    [Parameter()][string]$install_installer,
    [Parameter()][string]$install_transforms,
    [Parameter()][bool]$install_SkipMSIAlreadyInstalledCheck,
    [Parameter()][string]$install_script,
    [Parameter()][bool]$install_wim,
    [Parameter()][string]$install_successExitCodes,
    [Parameter()][string[]]$install_rebootExitCodes,
    [Parameter()][string[]]$install_ignoreExitCodes,
    [Parameter()][string[]]$install_conflictingProcessStart,
    [Parameter()][string[]]$install_conflictingProcessEnd,
    [Parameter(Mandatory = $false)][ValidateSet('none', 'msi', 'exe', 'name', 'guid', 'ecno', 'script', 'powershell')][string]$uninstall_type,
    #[Parameter()][string]$uninstall_name,
    [Alias("uninstall_name")][Parameter()][string]$uninstall_namematch,
    [Parameter()][string]$uninstall_productcode,
    [Parameter()][string]$uninstall_filterscript,
    [Parameter()][string]$uninstall_argumentlist,
    [Parameter()][string]$uninstall_additionalargumentlist,
    [Parameter()][bool]$uninstall_secureargumentlist,
    [Parameter()][string]$uninstall_script,
    [Parameter()][string]$uninstall_installer,
    [Parameter()][bool]$uninstall_wim,
    [Parameter()][bool]$uninstall_dirfiles,
    [Parameter()][string[]]$uninstall_ignoreexitcodes,
    [Parameter()][string[]]$uninstall_conflictingprocessstart,
    [Parameter()][string[]]$uninstall_conflictingprocessend,
    [Parameter()][ValidateSet('user', 'system')][string]$installexperience,
    [Parameter()][ValidateSet('suppress', 'force', 'basedOnReturnCode', 'allow')][string]$devicerestartbehavior,
    [Parameter()][bool]$allowavailableuninstall,
    [Parameter()][ValidateSet('W10_1607', 'W10_1703', 'W10_1709', 'W10_1809', 'W10_1909', 'W10_2004', 'W10_20H2', 'W10_21H1', 'W10_21H2', 'W10_22H2', 'W11_21H2', 'W11_22H2')][string]$minimumsupportedwindowsrelease,
    [Parameter()][ValidateSet('x86', 'x64', 'all', 'arm64')][string]$architecture,
    [Parameter()][int]$minimumfreediskspaceinmb,
    [Parameter()][int]$minimummemoryinmb,
    [Parameter(Mandatory = $false)][ValidateSet('msi', 'registry_version', 'registry_existence', 'script')][string]$detection_type,
    [Parameter()][string]$detection_scriptfile,
    [Parameter()][bool]$detection_enforcesignaturecheck,
    [Parameter()][bool]$detection_runas32bit,
    [Parameter()][ValidateSet('existence', 'versionComparison')][string]$detection_detectionmethod,
    [Parameter()][string]$detection_keypath,
    [Parameter()][string]$detection_valuename,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_operator,
    [Parameter()][ValidateSet('notConfigured', 'equals', 'notEquals', 'greaterThanOrEqual', 'greaterThan', 'lessThanOrEqual', 'lessThan')][string]$detection_productversionoperator,
    [Parameter()][string]$detection_value,
    [Parameter()][bool]$detection_check32biton64system
  )
  if (-not $script:api_header) {
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  # Base Endpoint for Applications
  $endpoint = "$($script:api_uri)api/v1/applications/"
  # Create list of sections
  $sections = @{
    information     = @('name', 'description', 'publisher', 'notes', 'owner', 'information_url', 'privacy_url')
    sourcefiles     = @('appsource', 'appid', 'appsetupfilename', 'storageaccountcontainername', 'dependson', 'active', 'lastupdate', 'pauseupdate', 'publishto', 'versions')
    filteroptions   = @('filter_architecture', 'filter_platform', 'filter_channel', 'filter_type', 'filter_installer_type', 'filter_release', 'filter_language', 'filter_imagetype')
    install         = @('install_type', 'install_argumentList', 'install_additionalArgumentList', 'install_secureArgumentList', 'install_installer', 'install_transforms', 'install_SkipMSIAlreadyInstalledCheck', 'install_script', 'install_wim', 'install_successExitCodes', 'install_rebootExitCodes', 'install_ignoreExitCodes', 'install_conflictingProcessStart', 'install_conflictingProcessEnd')
    uninstall       = @('uninstall_type', 'uninstall_name', 'uninstall_namematch', 'uninstall_productcode', 'uninstall_filterscript', 'uninstall_argumentlist', 'uninstall_additionalargumentlist', 'uninstall_secureargumentlist', 'uninstall_script', 'uninstall_installer', 'uninstall_wim', 'uninstall_dirfiles', 'uninstall_ignoreexitcodes', 'uninstall_conflictingprocessstart', 'uninstall_conflictingprocessend')
    program         = @('installexperience', 'devicerestartbehavior', 'allowavailableuninstall')
    requirementrule = @('minimumsupportedwindowsrelease', 'architecture', 'minimumfreediskspaceinmb', 'minimummemoryinmb')
    detectionrule   = @('detection_type', 'detection_scriptfile', 'detection_enforcesignaturecheck', 'detection_runas32bit', 'detection_detectionmethod', 'detection_keypath', 'detection_valuename', 'detection_operator', 'detection_productversionoperator', 'detection_value', 'detection_check32biton64system')
  }

  $body = @{}
  if($PSBoundParameters.ContainsKey("id")){
    $body["id"] = $id
  }
  foreach ($section in $sections.Keys) {
    foreach ($param in $sections[$section]) {
      $body_key = ($param -replace 'uninstall_', '' -replace 'install_', '' -replace 'detection_', '' -replace 'filter_', '')
      if ($section -eq "filteroptions") {
        if (-not $body.ContainsKey("sourcefiles")) {
          $body["sourcefiles"] = @{}
        }
        if ($PSBoundParameters.ContainsKey($param)) {
          if (-not $body["sourcefiles"].ContainsKey($section)) {
            $body["sourcefiles"][$section] = @{}
          }
          $body["sourcefiles"][$section][$body_key] = $PSBoundParameters[$param]
        }
      }
      else {
        if ($PSBoundParameters.ContainsKey($param)) {
          if (-not $body.ContainsKey($section)) {
            $body[$section] = @{}
          }
          $body[$section][$body_key] = $PSBoundParameters[$param]
        }        
      }
    }
  }
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($body | ConvertTo-JSON -Depth 5) -Method Post
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to create application. $error_message"
  }  

}