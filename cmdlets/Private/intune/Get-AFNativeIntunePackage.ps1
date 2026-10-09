function Get-AFNativeIntunePackage {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$FilePath,
    [Parameter(Mandatory)][string]$WorkDirectory
  )

  $source = Get-Item -LiteralPath $FilePath -ErrorAction Stop

  if ($source.PSIsContainer -or $source.Extension -ne ".intunewin") {
    throw "Expected an .intunewin package: $FilePath"
  }

  [IO.Directory]::CreateDirectory($WorkDirectory) | Out-Null

  $archive = [IO.Compression.ZipFile]::OpenRead($source.FullName)

  try {
    $metadataEntries = @(
      $archive.Entries | Where-Object {
        $_.FullName.Replace('\', '/') -ieq
        "IntuneWinPackage/Metadata/Detection.xml"
      }
    )

    if ($metadataEntries.Count -ne 1) {
      throw "Package must contain exactly one Detection.xml."
    }

    $settings = [Xml.XmlReaderSettings]::new()
    $settings.DtdProcessing = [Xml.DtdProcessing]::Prohibit
    $settings.XmlResolver = $null
    $settings.MaxCharactersInDocument = 1MB

    $metadataStream = $metadataEntries[0].Open()
    $reader = $null

    try {
      $reader = [Xml.XmlReader]::Create($metadataStream, $settings)
      $document = [Xml.XmlDocument]::new()
      $document.XmlResolver = $null
      $document.Load($reader)
    }
    finally {
      if ($reader) {
        $reader.Dispose()
      }

      $metadataStream.Dispose()
    }

    $info = $document.ApplicationInfo

    if (-not $info) {
      throw "Detection.xml does not contain ApplicationInfo."
    }

    $innerName = [string]$info.FileName
    $setupFile = [string]$info.SetupFile

    if (
      [string]::IsNullOrWhiteSpace($innerName) -or
      $innerName -match '[/\\]' -or
      [string]::IsNullOrWhiteSpace($setupFile)
    ) {
      throw "Detection.xml has an invalid FileName or SetupFile."
    }

    $originalSize = 0L

    if (
      -not [long]::TryParse(
        [string]$info.UnencryptedContentSize,
        [ref]$originalSize
      ) -or
      $originalSize -le 0
    ) {
      throw "Detection.xml has an invalid UnencryptedContentSize."
    }

    $encryption = @{
      "@odata.type"        = "#microsoft.graph.fileEncryptionInfo"
      encryptionKey        = [string]$info.EncryptionInfo.EncryptionKey
      macKey               = [string]$info.EncryptionInfo.MacKey
      initializationVector = [string]$info.EncryptionInfo.InitializationVector
      mac                  = [string]$info.EncryptionInfo.Mac
      profileIdentifier    = [string]$info.EncryptionInfo.ProfileIdentifier
      fileDigest           = [string]$info.EncryptionInfo.FileDigest
      fileDigestAlgorithm  = [string]$info.EncryptionInfo.FileDigestAlgorithm
    }

    if (
      $encryption.profileIdentifier -ne "ProfileVersion1" -or
      $encryption.fileDigestAlgorithm -ne "SHA256"
    ) {
      throw "Only ProfileVersion1 packages with SHA256 are supported."
    }

    $expectedLengths = @{
      encryptionKey        = 32
      macKey               = 32
      initializationVector = 16
      mac                  = 32
      fileDigest           = 32
    }

    foreach ($field in $expectedLengths.Keys) {
      try {
        $decoded = [Convert]::FromBase64String($encryption[$field])
      }
      catch {
        throw "Detection.xml has invalid Base64 in $field."
      }

      if ($decoded.Length -ne $expectedLengths[$field]) {
        throw "Detection.xml has an invalid $field length."
      }
    }

    $payloadEntries = @(
      $archive.Entries | Where-Object {
        $_.FullName.Replace('\', '/') -ieq
        "IntuneWinPackage/Contents/$innerName"
      }
    )

    if ($payloadEntries.Count -ne 1) {
      throw "Package must contain exactly one encrypted payload."
    }

    $payloadPath = Join-Path $WorkDirectory "payload.intunewin"
    $inputStream = $payloadEntries[0].Open()
    $outputStream = [IO.File]::Create($payloadPath)

    try {
      $inputStream.CopyTo($outputStream)
    }
    finally {
      $inputStream.Dispose()
      $outputStream.Dispose()
    }

    $encryptedSize = (Get-Item -LiteralPath $payloadPath).Length

    if ($encryptedSize -le 48) {
      throw "Encrypted payload is too short."
    }

    $stream = [IO.File]::OpenRead($payloadPath)
    $hmac = $null

    try {
      $header = [byte[]]::new(48)
      $offset = 0

      while ($offset -lt $header.Length) {
        $read = $stream.Read(
          $header,
          $offset,
          $header.Length - $offset
        )

        if ($read -eq 0) {
          throw "Unexpected end of encrypted payload."
        }

        $offset += $read
      }

      $headerMac = [byte[]]::new(32)
      $headerIV = [byte[]]::new(16)

      [Buffer]::BlockCopy($header, 0, $headerMac, 0, 32)
      [Buffer]::BlockCopy($header, 32, $headerIV, 0, 16)

      if (
        [Convert]::ToBase64String($headerMac) -cne $encryption.mac -or
        [Convert]::ToBase64String($headerIV) -cne
        $encryption.initializationVector
      ) {
        throw "Encrypted payload header does not match Detection.xml."
      }

      # ProfileVersion1 HMAC covers the IV and ciphertext.
      $stream.Position = 32
      $hmac = [Security.Cryptography.HMACSHA256]::new(
        [Convert]::FromBase64String($encryption.macKey)
      )

      $actualMac = [Convert]::ToBase64String(
        $hmac.ComputeHash($stream)
      )

      if ($actualMac -cne $encryption.mac) {
        throw "Encrypted payload HMAC validation failed."
      }
    }
    finally {
      if ($hmac) {
        $hmac.Dispose()
      }

      $stream.Dispose()
    }

    [PSCustomObject]@{
      SourcePath     = $source.FullName
      PayloadPath    = $payloadPath
      FileName       = $innerName
      SetupFile      = $setupFile
      Size           = $originalSize
      SizeEncrypted  = $encryptedSize
      EncryptionInfo = $encryption
    }
  }
  finally {
    $archive.Dispose()
  }
}