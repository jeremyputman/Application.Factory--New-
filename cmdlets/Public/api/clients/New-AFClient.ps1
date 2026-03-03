function New-AFClient{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$name,
    [Parameter()][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/clients/"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($PSBoundParameters | ConvertTo-JSON) -Method Post
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to create client. $error_message"
  }  

}