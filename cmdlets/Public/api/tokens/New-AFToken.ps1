function New-AFToken{
  [CmdletBinding()]
  param(
    [parameter(Mandatory = $true)][string]$name,
    [parameter(Mandatory = $true)][datetime]$expires_at
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }
  $endpoint = "$($script:api_uri)api/v1/tokens/"
  try{
    $body = @{
      "name" = $name
      "expires_at" = $expires_at.ToString("o")
    }
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Post -body $($body | ConvertTo-Json -Depth 3)
    return $response
  }
  catch{
    Write-Error "Failed to create token. $_"
  }
}
