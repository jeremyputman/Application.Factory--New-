function Revoke-AFToken{
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
    $body = @{
      "revoked_at" = (Get-Date).ToString("o")
    }
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Patch -body $($body | ConvertTo-Json -Depth 3)
    return $response
  }
  catch{
    Write-Error "Failed to revoke token. $_"
  }
}
