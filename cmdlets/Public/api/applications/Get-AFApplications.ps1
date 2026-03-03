function Get-AFApplications{
  [cmdletbinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/applications/"
  if($PSBoundParameters.ContainsKey('id')){
    $endpoint = "$($endpoint)$($id)"
  }
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve application list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }    
}