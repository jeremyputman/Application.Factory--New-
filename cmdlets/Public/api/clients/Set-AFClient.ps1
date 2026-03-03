function Set-AFClient{
  [CmdletBinding()]
  param(
    [Alias("name")][Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$id,
    [Parameter()][ValidateNotNullOrEmpty()][string[]]$assigned_groups
  )
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }  
  $endpoint = "$($script:api_uri)api/v1/clients/$($id)"
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -body $($PSBoundParameters | ConvertTo-JSON) -Method Patch
    return $response
  }
  catch{
    if(($_.ErrorDetails.Message | ConvertFrom-Json).detail){
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).detail
    }
    else{
      $error_message = ($_.ErrorDetails.Message | ConvertFrom-Json).name
    }
    Write-Error "Failed to update client. $error_message"
  }  

}