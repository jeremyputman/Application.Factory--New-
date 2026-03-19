function Write-AFLogEntry{
  [cmdletbinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [Parameter()][string]$FunctionName,
    [Parameter()][string]$Level,
    [Parameter()][string[]]$Tag,
    [Parameter()][string]$Target
  )
  if($script:enable_logging){
    if (-not $FunctionName) {
      $stack = Get-PSCallStack
      $FunctionName = $stack[1].FunctionName
    }
    if(-not $level){
      $level = $script:log_level
    }
    Write-PSFMessage -Message $Message -FunctionName $FunctionName -Level  $Level -Tag $Tag -Target $Target
  }
}