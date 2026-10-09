function Get-AFClientGraphCollection {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Uri
  )

  do {
    $response = Invoke-AFNativeGraphRequest -Method GET -Uri $Uri

    foreach ($item in @($response.value)) {
      if ($null -ne $item) {
        $item
      }
    }

    $Uri = [string]$response.'@odata.nextLink'
  }
  while ($Uri)
}