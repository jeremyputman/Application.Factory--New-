function Get-AFApplicationClientFiles{
  [CmdletBinding()]
  param(  
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$configuration
  )
  $download_folder = Join-Path -Path $script:working_folder -ChildPath "Download" -AdditionalChildPath $configuration.application.slug
  if(Test-Path $download_folder){
    Remove-Item -Path $download_folder -Force -Recurse -ErrorAction SilentlyContinue
  }
  New-Item -Path $download_folder -ItemType Directory | Out-Null
  # Make sure that we are using the correct path and SAS token based on the container type for the application
  if($configuration.application.container -ne "private"){
    $container_name = $script:storage_container_public
    $container_sas = $script:storage_container_public_sas
  }
  else{
    $container_name = $script:storage_container_org
    $container_sas = $script:storage_container_org_sas
  }
  # Check to see if we are looking for GUID or for App Name for folders
  if($script:application_key -eq "guid"){
    $lookup_value = $configuration.application.id
  }
  else{
    $lookup_value = $configuration.application.slug
  }
  $filelist = @("$($configuration.application.Name).intunewin","Icon.png", "Detection.ps1", "App.json")
  foreach($file in $filelist){
    try{
      $blob_url = "$($script:storage_account)/$container_name/$($lookup_value)/$($script:published_version)/$($file)"
      $blob = "$($blob_url)?$($container_sas)"
      $destination = Join-Path -Path $download_folder -ChildPath $file
      try{
        Invoke-WebRequest -Uri $blob -OutFile $destination -ErrorAction Stop | Out-Null
      }
      catch{
        if($file -eq "Detection.ps1"){
          continue
        }
        throw $_
      }      
      if ($script:enable_logging) {
        Write-AFLogEntry -Message "[<c='green'>$($configuration.application.Name)</c>] Downloaded file '$file'" -Tag "Application", "$($configuration.application.Name)"
      }      
    }
    catch{
      Write-AFLogEntry -Level Warning -Message "[<c='green'>$($configuration.application.Name)</c>] :: Failed to download file '$file' at url '$blob_url' for application '$($configuration.application.Name)' with error message: $($_.Exception.Message)"
      continue
    }
  }
  $script:application_data = Get-Content -Path (Join-Path -Path $download_folder -ChildPath "App.json") | ConvertFrom-Json -Depth 10
}