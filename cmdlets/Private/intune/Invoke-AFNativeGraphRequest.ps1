function Invoke-AFNativeGraphRequest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][ValidateSet("GET", "POST", "PATCH", "DELETE")][string]$Method,
    [Parameter(Mandatory)][string]$Uri,
    [Parameter()]$Body,
    [ValidateRange(1, 10)][int]$MaxAttempts = 6
  )

  if ($Uri -notmatch '^https://') {
    $Uri = "https://graph.microsoft.com/beta/$($Uri.TrimStart('/'))"
  }

  $parsedUri = [uri]$Uri

  if (
    $parsedUri.Scheme -ne "https" -or
    $parsedUri.Host -ne "graph.microsoft.com"
  ) {
    throw "Native Graph requests must target graph.microsoft.com over HTTPS."
  }

  $clientRequestId = [guid]::NewGuid().ToString()

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    Connect-AFIntuneGraph

    $request = @{
      Uri         = $Uri
      Method      = $Method
      TimeoutSec  = 60
      ErrorAction = "Stop"
      Headers     = @{
        Authorization              = "Bearer $script:graph_access_token"
        Accept                     = "application/json"
        "client-request-id"        = $clientRequestId
        "return-client-request-id" = "true"
      }
    }

    if ($PSBoundParameters.ContainsKey("Body")) {
      $request.ContentType = "application/json"

      $json = if ($Body -is [string]) {
        $Body
      }
      else {
        ConvertTo-Json -InputObject $Body -Depth 30 -Compress
      }

      $request.Body = [Text.Encoding]::UTF8.GetBytes($json)
    }

    try {
      return Invoke-RestMethod @request
    }
    catch {
      $failure = Get-AFNativeHttpFailure -Record $_

      if ($failure.Status -eq 401 -and $attempt -lt $MaxAttempts) {
        Connect-AFIntuneGraph -Force
        continue
      }

      # GET/PATCH/DELETE are safe to repeat here.
      # POST is repeated only for explicit throttling.
      $canRetry = (
        $failure.Status -eq 429 -or
        (
          $Method -ne "POST" -and
          $failure.Status -in @(0, 408, 500, 502, 503, 504)
        )
      )

      if ($canRetry -and $attempt -lt $MaxAttempts) {
        $delay = if ($failure.RetrySeconds -gt 0) {
          [Math]::Ceiling($failure.RetrySeconds)
        }
        else {
          [Math]::Min(60, [Math]::Pow(2, $attempt)) +
          (Get-Random -Minimum 0 -Maximum 4)
        }

        # Keep excessively long throttling waits explicit.
        if ($delay -le 300) {
          Write-Verbose (
            "Graph HTTP {0}; attempt {1}/{2}; retry in {3}s." -f
            $failure.Status, $attempt, $MaxAttempts, $delay
          )

          Start-Sleep -Seconds $delay
          continue
        }
      }

      $message = @(
        "Native Graph request failed."
        "Method: $Method"
        "URI: $(Protect-AFNativeDiagnostic -Text $Uri)"
        "HTTP status: $($failure.Status)"
        "Request ID: $($failure.RequestId)"
        "Client request ID: $clientRequestId"
        "Retry-After seconds: $($failure.RetrySeconds)"
        "Response: $($failure.Detail)"
      ) -join [Environment]::NewLine

      $exception = [InvalidOperationException]::new($message)
      $exception.Data["HttpStatus"] = $failure.Status
      $exception.Data["RequestId"] = $failure.RequestId
      $exception.Data["ClientRequestId"] = $clientRequestId

      throw $exception
    }
  }
}