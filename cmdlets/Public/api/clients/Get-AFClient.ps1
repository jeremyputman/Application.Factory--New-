function Get-AFClient{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$false)][string]$id
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/clients/"
  if($PSBoundParameters.ContainsKey('id')){
    $endpoint = "$($endpoint)$($id)"
  }
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve client list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }  
}