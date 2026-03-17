function Get-AFApplicationConfigurations{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$true)][string]$id,
    [Parameter()][string]$application_id
  )      
  # Validate API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  

  # Build endpoint URL
  $endpoint = "$($script:api_uri)api/v1/appfactory/$($id)"
  if($application_id){
    $endpoint = "$($endpoint)/$($application_id)"
  }

  # Call API and handle response
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve application list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }    

}