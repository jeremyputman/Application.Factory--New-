function New-AFApplicationPackage {
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"        
  )
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $application.slug
  $AppPublishFolderPath = Join-Path -Path $script:working_folder -ChildPath "Publish" -AdditionalChildPath $application.slug
  $ToolkitFile = Join-Path -Path $AppPublishFolderPath -ChildPath "Invoke-AppDeployToolkit.ps1"
  Remove-Item -Path $AppPublishFolderPath -Force -Recurse -ErrorAction SilentlyContinue
  try {
    New-Item -Path $AppPublishFolderPath -ItemType Directory -ErrorAction "Stop" | Out-Null
  }
  catch {
    throw "[$($application.Information.Name)] Failed to create '$($AppPublishFolderPath)' with error message: $($_.Exception.Message)"
  }
  try {
    Copy-Item -Path "$($PSScriptRoot)\Templates\PSADT\*" -Destination $AppPublishFolderPath -Recurse -Force -Confirm:$false
  }
  catch {
    throw "[$($application.Information.Name)] Unable to copy template files: $($_.Exception.Message)"
  }
  if ($application.SourceFiles.AppSource -ne "PSADT") {
    try {
      Copy-Item -Path "$($AppSetupFolderPath)\*" -Destination "$($AppPublishFolderPath)\Files" -Recurse -Force -Confirm:$false
    }
    catch {
      throw "[$($application.Information.Name)] Unable to copy template files: $($_.Exception.Message)"
    }
  }
  $requireAdmin = $true
  if ($application.Program.InstallExperience -eq "User") {
    $requireAdmin = $false
  }
  $ToolkitContent = Get-Content -Path $ToolkitFile -Raw
  $ToolkitContent = $ToolkitContent -replace "###INTUNEAPPNAME###", $application.Information.Name
  $ToolkitContent = $ToolkitContent -replace "###APPPUBLISHER###", $application.Information.Publisher.Name
  $ToolkitContent = $ToolkitContent -replace "###VERSION###", $CurrentVersion.Version
  $ToolkitContent = $ToolkitContent -replace "###APPARCH###", $application.RequirementRule.Architecture
  if ($application.install.conflictingProcessStart) {
    $ToolkitContent = $ToolkitContent -replace "###APPSTOCLOSESTART###", "$($application.install.conflictingProcessStart -join "','")"  
  }
  else {
    $ToolkitContent = $ToolkitContent -replace "'###APPSTOCLOSESTART###'", ""
  }
  if ($application.uninstall.conflictingProcessStart) {
    $ToolkitContent = $ToolkitContent -replace "###APPSTOCLOSESTARTEND###", "'$($application.uninstall.conflictingProcessStart -join "','")"
  }
  else {
    $ToolkitContent = $ToolkitContent -replace "'###APPSTOCLOSESTARTEND###'", ""
  }
      

  $ToolkitContent = $ToolkitContent -replace "###AppLang###", "English"
  $ToolkitContent = $ToolkitContent -replace "'###REQUIREADMIN###'", "`$$($requireAdmin)"
  $ToolkitContent = $ToolkitContent -replace "###APPDATE###", (Get-Date).ToShortDateString()
  $InstallerContent = Get-Content -Path "$($ApplicationDirectory)\install.ps1" -ErrorAction SilentlyContinue
  $UninstallerContent = Get-Content -Path "$($ApplicationDirectory)\uninstall.ps1" -ErrorAction SilentlyContinue
  $ToolKitInstallStart = $ToolkitContent -split "    ## <Perform Installation tasks here>"
  $ToolkitUninstallStart = $ToolKitInstallStart[1] -split "    ## <Perform Uninstallation tasks here>"
  $NewContent = [System.Collections.Generic.List[string]]::new()
  foreach ($line in $ToolKitInstallStart[0]) {
    $NewContent.Add($line)
  }
  $NewContent.Add("    ## <Perform Installation tasks here>")
  foreach ($line in $InstallerContent) {
    $NewContent.Add(($line -replace "###SETUPFILENAME###", $($application.SourceFiles.AppSetupFileName)))
  }
  foreach ($line in $ToolkitUninstallStart[0]) {
    $NewContent.Add($line)
  }
  $NewContent.Add("    ## <Perform Uninstallation tasks here>")
  foreach ($line in $UninstallerContent) {
    $NewContent.Add(($line -replace "###SETUPFILENAME###", $($application.SourceFiles.AppSetupFileName)))
  }      
  foreach ($line in $ToolkitUninstallStart[1]) {
    $NewContent.Add($line)
  }
  Out-File -InputObject $NewContent -FilePath $ToolkitFile -Encoding "utf8" -Force -Confirm:$false
  $iconPath = Join-Path -Path $AppPublishFolderPath -ChildPath "Icon.png"
  Invoke-WebRequest -Uri $application.IconURL -OutFile $iconPath -ErrorAction SilentlyContinue
  if($application.DetectionRule.Type -eq "Script"){
    $detection_script = Join-Path -Path $AppPublishFolderPath -ChildPath "detection.ps1"
    $application.detectionrule.scriptfile -replace "###VERSION###", $CurrentVersion.Version | Out-File -FilePath $detection_script -Encoding "utf8" -Force -Confirm:$false
  }
}