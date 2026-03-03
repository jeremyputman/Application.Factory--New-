function Set-AFSettings{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$api_key,
    [Parameter(Mandatory = $true)][string]$uri,
    [Parameter()][switch]$EnableLogging,
    [Parameter(Mandatory = $false)][string]$LoggingPath,
    [Parameter(Mandatory = $false)][string]$WorkingPath = $ENV:TEMP
  )
  $header = @{
    "content-type" = "application/json"
    "Authorization" = "Api-Key $($api_key)"
  }

  if($EnableLogging.IsPresent){
    if(-not $LoggingPath){
      $LoggingPath = $ENV:TEMP
    }
    $log_dir = Join-Path -Path $LoggingPath -ChildPath "AppFactoryService-%Date%.csv"
    $paramSetPSFLoggingProvider = @{
      Name         = "logfile"
      InstanceName = "AppFactoryService"
      FilePath     = $log_dir
      Enabled      = $true
      Wait         = $true
    }
    Set-PSFLoggingProvider @paramSetPSFLoggingProvider
  }
  $script:working_folder = $WorkingPath
  $script:api_header = $header
  $script:api_uri = $uri
  $script:enable_logging = $EnableLogging
}