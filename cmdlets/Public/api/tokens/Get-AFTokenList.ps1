function Get-AFTokenList{
  [CmdletBinding()]
  param()
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/tokens/"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve token list. $_"
  }
}
