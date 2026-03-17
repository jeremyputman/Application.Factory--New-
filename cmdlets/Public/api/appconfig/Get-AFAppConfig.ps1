<#
.SYNOPSIS
    Retrieves application configuration from the Application Factory API.
.DESCRIPTION
    Calls the API to get configuration details for a specific application or all applications if no ID is provided.
.PARAMETER id
    Optional. The ID of the application configuration to retrieve.
.OUTPUTS
    Application configuration object(s) from the API.
.EXAMPLE
    Get-AFAppConfig -id "12345"
#>
function Get-AFAppConfig{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory=$false)][string]$id,
    [Parameter()][bool]$enabled
  )    
  # Validate API header
  if(-not $script:api_header){
    Write-Error "API header not set. Please use Set-AFSettings to set the API key."
    return
  }

  $Parameters = [System.Collections.Generic.List[string]]::new()
  foreach($item in $PSBoundParameters.GetEnumerator()){
    if($item.Key -ne "id"){
      $Parameters.Add("$($item.Key)=$($item.Value)")
    }
  }
  
  # Build endpoint URL
  $endpoint = "$($script:api_uri)api/v1/config/"
  if($PSBoundParameters.ContainsKey('id')){
    $endpoint = "$($endpoint)$($id)"
  }

  $endpoint = if($Parameters.Count -gt 0) {"$($endpoint)?$($Parameters -join '&')"} else {$endpoint}
  
  # Call API and handle response
  try{
    $response = Invoke-RestMethod -Uri $endpoint -Headers $script:api_header -Method Get
    return $response
  }
  catch{
    Write-Error "Failed to retrieve application list. $(($_.ErrorDetails.Message | ConvertFrom-Json).detail)"
  }  
}