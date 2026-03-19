<#
  .DESCRIPTION
  This cmdlet is designed to interact with the evergreen powershell module to find the installers for evergreen based installers
  .PARAMETER application
  The application object that we are working for so that we can ensure that get the correct and current data
  .PARAMETER LogLevel
  If logging is enabled, what level of logging do we want, default is verbose.
#>
function Get-AppFactoryEvergreenAppItem{
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][PSCustomObject]$application 
  )
  if($script:enable_logging){
    Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Looking for Evergreen Application with AppID: <c='green'>$($application.SourceFiles.AppID)</c>"  -Tag "Application","$($application.information.Name)","Evergreen"
  }

  # Construct array list to build the dynamic filter list
  $FilterList = [System.Collections.Generic.List[PSCustomObject]]@()
  # Process known filter properties and add them to array list if present on current object
  if ($Application.SourceFiles.FilterOptions.Architecture) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Architecture Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Architecture)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Architecture -eq ""$($Application.SourceFiles.FilterOptions.Architecture)""") | Out-Null
  }
  if ($Application.SourceFiles.FilterOptions.Platform) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Platform Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Platform)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Platform -eq ""$($Application.SourceFiles.FilterOptions.Platform)""") | Out-Null
  }
  if ($Application.SourceFiles.FilterOptions.Channel) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Channel Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Channel)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Channel -eq ""$($Application.SourceFiles.FilterOptions.Channel)""") | Out-Null
  }
  if ($Application.SourceFiles.FilterOptions.Type) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Type Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Type)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Type -eq ""$($Application.SourceFiles.FilterOptions.Type)""") | Out-Null
  }
  if ($Application.SourceFiles.FilterOptions.InstallerType) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: InstallerType Filter: <c='green'>$($Application.SourceFiles.FilterOptions.InstallerType)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.InstallerType -eq ""$($Application.SourceFiles.FilterOptions.InstallerType)""") | Out-Null
  }
  if ($Application.SourceFiles.FilterOptions.Release) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Release Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Release)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Release -eq ""$($Application.SourceFiles.FilterOptions.Release)""") | Out-Null
  }  
  if ($Application.SourceFiles.FilterOptions.Language) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: Language Filter: <c='green'>$($Application.SourceFiles.FilterOptions.Language)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.Language -eq ""$($Application.SourceFiles.FilterOptions.Language)""") | Out-Null
  }    
  if ($Application.SourceFiles.FilterOptions.ImageType) {
    if($script:enable_logging){
      Write-AFLogEntry -Message "[<c='green'>$($application.information.Name)</c>] :: ImageType Filter: <c='green'>$($Application.SourceFiles.FilterOptions.ImageType)</c>" -Tag "Application","$($application.information.Name)","Evergreen"
    }
    $FilterList.Add("`$PSItem.ImageType -eq ""$($Application.SourceFiles.FilterOptions.ImageType)""") | Out-Null
  } 
  # Construct script block from filter list array
  $FilterExpression = [scriptblock]::Create(($FilterList -join " -and ")) 
  # Get the evergreen app based on dynamic filter list
  if($FilterList.Count -gt 0){
    $EvergreenApp = Get-EvergreenApp -Name $application.SourceFiles.AppID | Where-Object -FilterScript $FilterExpression | Sort-Object Version -Descending | Select-Object -first 1
  }
  else{
    $EvergreenApp = Get-EvergreenApp -Name $application.SourceFiles.AppID | Sort-Object Version -Descending | Select-Object -first 1
  }
  # Only return the top item
  $PSObject = [PSCustomObject]@{
    "Version" = $EvergreenApp.version
    "URI" = $EvergreenApp.URI
  }
  return $PSObject
}