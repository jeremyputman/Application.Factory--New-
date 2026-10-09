function Get-AFNativeHttpFailure {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Management.Automation.ErrorRecord]$Record
  )

  $response = $Record.Exception.Response
  $status = 0
  $requestId = ""
  $retrySeconds = 0.0

  if ($response) {
    try {
      $status = [int]$response.StatusCode
    }
    catch {}

    try {
      $requestId = @($response.Headers.GetValues("request-id"))[0]
    }
    catch {}

    if (-not $requestId) {
      try {
        $requestId = @(
          $response.Headers.GetValues("x-ms-request-id")
        )[0]
      }
      catch {}
    }

    $retryValue = ""
    try {
      $retryValue = @(
        $response.Headers.GetValues("Retry-After")
      )[0]
    }
    catch {}

    if ($retryValue) {
      $seconds = 0.0

      if ([double]::TryParse($retryValue, [ref]$seconds)) {
        $retrySeconds = [Math]::Max(0, $seconds)
      }
      else {
        $retryDate = [DateTimeOffset]::MinValue

        if ([DateTimeOffset]::TryParse(
            $retryValue,
            [ref]$retryDate
          )) {
          $retrySeconds = [Math]::Max(
            0,
            ($retryDate - [DateTimeOffset]::UtcNow).TotalSeconds
          )
        }
      }
    }
  }

  $detail = $Record.ErrorDetails.Message

  if (-not $detail) {
    $detail = $Record.Exception.Message
  }

  [PSCustomObject]@{
    Status       = $status
    RequestId    = $requestId
    RetrySeconds = $retrySeconds
    Detail       = Protect-AFNativeDiagnostic -Text $detail
  }
}
