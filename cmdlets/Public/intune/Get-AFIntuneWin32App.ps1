function Get-AFIntuneWin32App {
  [cmdletbinding(DefaultParameterSetName = 'All')]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'id')][ValidateNotNullOrEmpty()][string]$id,
    [Parameter(Mandatory = $true, ParameterSetName = 'displayName')][ValidateNotNullOrEmpty()][string]$displayName,
    [Parameter()][switch]$failed
  )
  # URI Endpoint
  $endpoint = "deviceAppManagement/mobileApps"
  # Build filters for URI
  $filters =  [System.Collections.Generic.List[PSCustomObject]]@()
  $filters.Add("isof('microsoft.graph.win32LobApp')") | Out-Null
  $filters.Add("contains(notes,'AppFactoryID')") | Out-Null
  if($id){
    $filters.Add("id eq '$($id)'") | Out-Null
  }
  if($displayName){
    $filters.Add("displayName eq '$($displayName)'") | Out-Null
  }   
  if($failed.IsPresent){
    $filters.Add("uploadState eq 0") | Out-Null
  }
  # Create query string for the filter
  $filterList = $filters -join " and "
  $endpoint = "$($endpoint)?`$filter=$($filterList)"
  # Create empty list
  $applicationList =  [System.Collections.Generic.List[PSCustomObject]]@()  
  # Graph Header
  $headers = @{
    Authorization = $Global:AuthenticationHeader.Authorization
    "Content-Type" = "application/json"
  }  
  try{
    $uri = "https://graph.microsoft.com/beta/$($endpoint)"
    do{
      $results = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -StatusCodeVariable statusCode
      if($results.value){
        foreach($item in $results.value){
          $applicationList.add($item)
        }
      }
      $uri = $results."@odata.nextLink"
    }while($null -ne $results."@odata.nextLink")
  }
  catch{
    throw "Unable to get devices. $($_.Exception.Message)"
  }  
  return $applicationList
  
}