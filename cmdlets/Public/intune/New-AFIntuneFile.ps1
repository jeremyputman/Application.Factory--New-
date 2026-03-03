function New-AFIntuneFile {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"      
  )  
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $IntuneWinAppUtilPath = Join-Path -Path $PSScriptRoot -ChildPath "SupportFiles"  -AdditionalChildPath "IntuneWinAppUtil.exe"
  $OutputPackage = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.intunewin"
  $param = @{
    FilePath          = $IntuneWinAppUtilPath
    ArgumentList      = "-c ""$($AppPublishFolderPath)"" -s ""Invoke-AppDeployToolkit.exe"" -o ""$($AppPublishFolderPath)"" -q"
    LoadUserProfile   = $false
    Passthru          = $true
    UseNewEnvironment = $true
    Wait              = $true
  }  
  $process = Start-Process @param
  if ($process.ExitCode -eq 0) {
    Rename-Item -path $OutputPackage -NewName "$($application.Information.Name).intunewin" -Force
  }
  else {
    throw "Process failed with exit code $($process.ExitCode)"
  }  

}