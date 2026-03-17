<#
.SYNOPSIS
    Creates an Intune Win32 application package file for the application.
.DESCRIPTION
    Uses IntuneWinAppUtil.exe to package the application for Intune deployment, renames the output file, and handles process exit codes.
.PARAMETER Application
    The application object containing metadata and source information. (Mandatory)
.PARAMETER LogLevel
    The logging level for output messages. Defaults to 'Verbose'.
.OUTPUTS
    None. Creates an .intunewin package file in the publish folder.
.EXAMPLE
    New-AFIntuneFile -Application $app
#>
function New-AFIntuneFile {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )  
  # Prepare paths for publish folder and IntuneWinAppUtil
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $IntuneWinAppUtilPath = Join-Path -Path $PSScriptRoot -ChildPath "SupportFiles"  -AdditionalChildPath "IntuneWinAppUtil.exe"
  $OutputPackage = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.intunewin"
  # Prepare parameters for process start
  $param = @{
    FilePath          = $IntuneWinAppUtilPath
    ArgumentList      = "-c ""$($AppPublishFolderPath)"" -s ""Invoke-AppDeployToolkit.exe"" -o ""$($AppPublishFolderPath)"" -q"
    LoadUserProfile   = $false
    Passthru          = $true
    UseNewEnvironment = $true
    Wait              = $true
  }
  # Start packaging process and handle output
  $process = Start-Process @param
  if ($process.ExitCode -eq 0) {
    Rename-Item -path $OutputPackage -NewName "$($application.Information.Name).intunewin" -Force
  }
  else {
    throw "Process failed with exit code $($process.ExitCode)"
  }  

}