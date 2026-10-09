function Send-AFNativeAzureBlocks {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][hashtable]$Context,
    [Parameter(Mandatory)][string]$PayloadPath,
    [ValidateRange(1, 64)][int]$BlockSizeMB = 8
  )

  $stream = [IO.File]::OpenRead($PayloadPath)

  try {
    $blockSize = $BlockSizeMB * 1MB
    $blockCount = [Math]::Ceiling($stream.Length / [double]$blockSize)

    if ($blockCount -gt 50000) {
      throw "Payload requires more than 50,000 blocks."
    }

    $buffer = [byte[]]::new($blockSize)
    $ids = [Collections.Generic.List[string]]::new()
    $prefix = [guid]::NewGuid().ToString("N")
    $index = 0

    while ($stream.Position -lt $stream.Length) {
      $count = 0

      while ($count -lt $buffer.Length) {
        $read = $stream.Read(
          $buffer,
          $count,
          $buffer.Length - $count
        )

        if ($read -eq 0) {
          break
        }

        $count += $read
      }

      if ($count -eq 0) {
        throw "Unexpected end of payload while uploading."
      }

      $bytes = if ($count -eq $buffer.Length) {
        $buffer
      }
      else {
        $lastBlock = [byte[]]::new($count)
        [Buffer]::BlockCopy($buffer, 0, $lastBlock, 0, $count)
        $lastBlock
      }

      # Prefix + eight digits always produces equal-length IDs.
      $idText = $prefix + $index.ToString("D8")
      $blockId = [Convert]::ToBase64String(
        [Text.Encoding]::ASCII.GetBytes($idText)
      )

      $query = "comp=block&blockid=$(
                [uri]::EscapeDataString($blockId)
            )"

      Invoke-AFNativeStoragePut `
        -Context $Context `
        -Query $query `
        -Bytes $bytes

      $ids.Add($blockId)
      $index++

      Write-Verbose (
        "Uploaded block {0}/{1}; {2}/{3} bytes." -f
        $index, $blockCount, $stream.Position, $stream.Length
      )
    }

    $xml = '<?xml version="1.0" encoding="utf-8"?><BlockList>'

    foreach ($id in $ids) {
      $xml += "<Latest>$id</Latest>"
    }

    $xml += "</BlockList>"

    Invoke-AFNativeStoragePut `
      -Context $Context `
      -Query "comp=blocklist" `
      -Bytes ([Text.Encoding]::UTF8.GetBytes($xml)) `
      -ContentType "application/xml"

    $Context.TransportUsed = "Native"
  }
  finally {
    $stream.Dispose()
  }
}