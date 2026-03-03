function Get-AFApplicationInstaller{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][PSCustomObject]$Application,
    [Parameter(Mandatory = $true)][PSCustomObject]$CurrentVersion,
    [Parameter()][ValidateSet("Output", "Verbose")][string]$LogLevel = "Verbose"    
  )
  $AppSetupFolderPath = Join-Path -Path $script:working_folder -ChildPath "Installers" -AdditionalChildPath $application.slug
  if (-not(Test-Path -Path $AppSetupFolderPath -PathType "Container")) {
    try {
      New-Item -Path $AppSetupFolderPath -ItemType "Container" -ErrorAction "Stop" | Out-Null
    }
    catch [System.Exception] {
      throw "[$($application.Information.Name)] Failed to create '$($Path)' with error message: $($_.Exception.Message)"
    }
  }  
  $OutFilePath = Join-Path -Path $AppSetupFolderPath -ChildPath $application.SourceFiles.AppSetupFileName
  if($script:enable_logging){
    Write-PSFMessage -Message "[<c='green'>$($application.information.Name)</c>] :: Downloading setupfile <c='green'>$($CurrentVersion.URI)</c>" -Level $LogLevel -Tag "Application","$($application.information.Name)","Evergreen" -Target "Application Factory Service"
  }
  switch ($Application.SourceFiles.AppSource) {
    'azure_storage' {
      throw "Not Implemented - Azure Storage"
      # TODO: Installer - Azure Storage
    }
    'sharepoint' {
      throw "Not Implemented - SharePoint"
      # TODO: Installer - SharePoint
    }
    'psadt' {}
    'ecno' {
      throw "Not Implemented - ECNO"
      # TODO: Installer - ECNO
    }
    'local_storage' {
      throw "Not Implemented - Local Storage"
      # TODO: Installer - Local Storage
    }  
    default {
      try{
        Invoke-WebRequest -Uri $CurrentVersion.URI -OutFile $OutFilePath -UseBasicParsing -ErrorAction "Stop"
      }
      catch{
        throw "[$($application.Information.Name)] Failed to download setup file from '$($CurrentVersion.URI)' with error message: $($_.Exception.Message)"
      }
    }
  }  
}