function Remove-AFToken{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][string]$prefix
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/tokens/$($prefix)"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Delete
    return $response
  }
  catch{
    Write-Error "Failed to delete token. $_"
  }
}
