function Set-AFClientSettings{
  param(
    [Parameter(Mandatory = $true)][string]$configFile,
    [Parameter(Mandatory = $false)][string]$Workspace = $PSScriptRoot,
    [Parameter()][switch]$EnableLogging,
    [Parameter()][string]$LogLevel
  )
  # Enable logging if requested
  if($EnableLogging.IsPresent){
    if(-not $LoggingPath){
      $LoggingPath = $ENV:TEMP
    }
    $log_dir = Join-Path -Path $Workspace -ChildPath "Logs" -AdditionalChildPath "AppFactoryClient-%Date%.csv"
    $paramSetPSFLoggingProvider = @{
      Name         = "logfile"
      InstanceName = "AppFactoryClient"
      FilePath     = $log_dir
      Enabled      = $true
      Wait         = $true
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider
  }    
  # Load configuration and set environment variables
  $configuration = Get-Content -Raw -Path $configFile | ConvertFrom-Json
  $header = @{
    "content-type" = "application/json"
    "Authorization" = "Api-Key $(Get-Secret -Vault $configuration.keyvault_name -Name $configuration.api.key -AsPlainText)"
  }

  $process_tokens = Invoke-RestMethod -Uri "$($configuration.api.url)api/v1/appfactory/tokens/$($configuration.api.client)" -Headers $header -Method Get
  $script:working_folder = Join-Path -Path $Workspace -ChildPath "WorkingFolder"
  $script:api_header = $header
  $script:api_uri = $configuration.api.url
  $script:client_id = $configuration.api.client
  $script:enable_logging = $EnableLogging
  $script:log_level = $LogLevel
  $script:Workspace = Join-Path -Path $Workspace -ChildPath "Workspace"
  $script:keyvault_name = $configuration.keyvault_name
  $script:client_key = $process_tokens.client_key
  $script:application_key = $process_tokens.application_key
  $script:storage_account = $process_tokens.storage_account
  $script:storage_container_public = $process_tokens.public_container
  $script:storage_container_public_sas = $process_tokens.public_sas_token
  $script:storage_container_org = $process_tokens.organization_container
  $script:storage_container_org_sas = $process_tokens.org_sas_token
  $script:retries = $configuration.retries
  $script:appregistration_tenant = $configuration.appregistration.tenantID
  $script:appregistration_client = $configuration.appregistration.clientID
  $script:appregistration_secret = (Get-Secret -Vault $configuration.keyvault_name -Name $configuration.appregistration.secret -AsPlainText)
  $script:app_prefix = $configuration.prefix
}