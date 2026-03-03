function Set-AFApplicationIcon{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $true)][string]$iconpath
  ) 
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/applications/$($id)/icon"
  $form = @{
    icon = Get-Item -Path $iconpath
  }
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Post -Form $form
    return $response
  }
  catch{
    Write-Error "Failed to upload application icon. $_"
  }
}