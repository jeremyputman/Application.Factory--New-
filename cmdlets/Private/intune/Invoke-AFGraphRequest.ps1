function Invoke-AFGraphRequest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet("GET", "POST", "PUT", "PATCH", "DELETE")][string]$Method,
    [Parameter(Mandatory)][string]$Uri,
    [Parameter()]$Body,
    [Parameter()][ValidateRange(1, 10)][int]$MaxAttempts = 6,
    [Parameter()][ValidateSet("v1.0", "beta")][string]$ApiVersion = "beta"
  )

  if ($Uri -notmatch '^https://') {
    $Uri = "https://graph.microsoft.com/$ApiVersion/$($Uri.TrimStart('/'))"
  }

  $attempt = 0

  while ($attempt -lt $MaxAttempts) {
    $attempt++

    Connect-AFIntuneGraph

    $headers = @{
      Authorization = "Bearer $($script:graph_access_token)"
      Accept        = "application/json"
    }

    $params = @{
      Uri         = $Uri
      Method      = $Method
      Headers     = $headers
      ErrorAction = "Stop"
    }

    if ($null -ne $Body) {
      $params.ContentType = "application/json"

      if ($Body -is [string]) {
        $params.Body = $Body
      }
      else {
        $params.Body = $Body | ConvertTo-Json -Depth 20
      }
    }

    try {
      return Invoke-RestMethod @params
    }
    catch {
      $statusCode = $null
      $retryAfter = $null
      $responseBody = $null

      if ($_.Exception.Response) {
        try {
          $statusCode = [int]$_.Exception.Response.StatusCode
        }
        catch {}

        try {
          $retryAfter = $_.Exception.Response.Headers.RetryAfter.Delta.TotalSeconds
        }
        catch {}

        try {
          $responseBody = $_.ErrorDetails.Message
        }
        catch {}
      }

      # An expired/invalid token can be refreshed immediately.
      if ($statusCode -eq 401 -and $attempt -lt $MaxAttempts) {
        Connect-AFIntuneGraph -Force
        continue
      }

      # Retry only failures that have a reasonable chance of succeeding
      # without changing the request.
      $retryableStatusCodes = @(
        408, # Request timeout
        429, # Throttled
        500,
        502,
        503,
        504
      )

      if ($statusCode -in $retryableStatusCodes -and $attempt -lt $MaxAttempts) {
        if ($retryAfter) {
          $delay = [Math]::Max(1, [int][Math]::Ceiling($retryAfter))
        }
        else {
          # Exponential backoff:
          # 2, 4, 8, 16, 32 seconds, capped at 60.
          $delay = [Math]::Min(60,[Math]::Pow(2, $attempt))
          # Small jitter prevents simultaneous clients from retrying at exactly the same moment.
          $delay += Get-Random -Minimum 0 -Maximum 4
        }

        if ($script:enable_logging) {
          Write-AFLogEntry `
            -Message "[Application Factory] :: Graph request returned HTTP $statusCode. Retry $attempt/$MaxAttempts in $delay seconds. URI: $Uri" `
            -Level "Warning" `
            -Tag "Intune"
        }
        Start-Sleep -Seconds $delay
        continue
      }

      $details = @(
        "Microsoft Graph request failed."
        "Method: $Method"
        "URI: $Uri"
      )

      if ($statusCode) {
        $details += "HTTP Status: $statusCode"
      }

      if ($responseBody) {
        $details += "Graph Response: $responseBody"
      }

      $details += "Exception: $($_.Exception.Message)"

      throw ($details -join [Environment]::NewLine)
    }
  }

  throw "Microsoft Graph request failed after $MaxAttempts attempts. Method: $Method URI: $Uri"
}