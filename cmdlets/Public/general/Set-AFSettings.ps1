<#
.SYNOPSIS
    Sets Application Factory configuration and environment variables.
.DESCRIPTION
    Loads configuration from a JSON file, sets up logging if enabled, and initializes script-scoped variables for API, storage, and workspace settings.
.PARAMETER configFile
    The path to the configuration JSON file. (Mandatory)
.PARAMETER Workspace
    The workspace path for environment setup. Defaults to script root.
.PARAMETER EnableLogging
    Enables logging if specified.
.OUTPUTS
    None. Sets script-scoped variables for use in other functions.
.EXAMPLE
    Set-AFSettings -configFile 'config.json' -Workspace 'C:\Workspace' -EnableLogging
#>
function Set-AFSettings {
  [CmdletBinding()]
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
    $log_dir = Join-Path -Path $Workspace -ChildPath "Logs" -AdditionalChildPath "AppFactoryService-%Date%.csv"
    $paramSetPSFLoggingProvider = @{
      Name         = "logfile"
      InstanceName = "AppFactoryService"
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
  $script:working_folder = Join-Path -Path $Workspace -ChildPath "WorkingFolder"
  $script:api_header = $header
  $script:api_uri = $configuration.api.url
  $script:enable_logging = $EnableLogging
  $script:log_level = $LogLevel
  $script:Workspace = Join-Path -Path $Workspace -ChildPath "Workspace"
  $script:LocalStorage = Join-Path -Path $Workspace -ChildPath "LocalStorage"
  $script:keyvault_name = $configuration.keyvault_name
  $script:storage_installers = $configuration.storage.installers
  $script:sharepointurl = $configuration.sharepoint.sharepointurl
  $script:sharepoint_certificateFile = $configuration.sharepoint.certificateFile
  $script:sharepointsite = $configuration.sharepoint.sharepointsite
  $script:sharepoint_certificateSecret = $configuration.sharepoint.certificateSecret
  $script:sharepoint_clientId = $configuration.sharepoint.clientId
  $script:sharepoint_tenant = $configuration.sharepoint.tenant
  $script:sharepoint_documentLibrary = $configuration.sharepoint.documentLibrary
  $script:storage_container_public = $configuration.storage.public
  $script:client_key = $configuration.client_key
  $script:application_key = $configuration.application_key
  $script:storage_packages = $configuration.storage.packages
}