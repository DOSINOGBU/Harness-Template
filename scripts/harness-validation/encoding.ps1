function Get-DocumentationEncodingFiles {
    $files = @()
    $agentsPath = Resolve-RepoRelativePath -RelativePath "AGENTS.md"
    $docsPath = Resolve-RepoRelativePath -RelativePath "docs"
    $checklistsPath = Resolve-RepoRelativePath -RelativePath ".harness/checklists"

    if (Test-Path -LiteralPath $agentsPath) {
        $files += Get-Item -LiteralPath $agentsPath
    }

    if (Test-Path -LiteralPath $docsPath) {
        $files += Get-ChildItem -LiteralPath $docsPath -Recurse -Filter "*.md" -File
    }

    if (Test-Path -LiteralPath $checklistsPath) {
        $files += Get-ChildItem -LiteralPath $checklistsPath -Filter "*.md" -File
    }

    return @($files | Sort-Object FullName -Unique)
}

function New-StringFromCodePoints {
    param(
        [int[]]$CodePoints
    )

    $characters = @()

    foreach ($codePoint in $CodePoints) {
        $characters += [char]$codePoint
    }

    return -join $characters
}

function Get-LineNumberFromByteIndex {
    param(
        [byte[]]$Bytes,
        [int]$ByteIndex
    )

    if ($ByteIndex -lt 0) {
        return 0
    }

    $lineNumber = 1
    $lastIndex = [Math]::Min($ByteIndex, $Bytes.Length - 1)

    for ($index = 0; $index -le $lastIndex; $index += 1) {
        if ($Bytes[$index] -eq 10) {
            $lineNumber += 1
        }
    }

    return $lineNumber
}

function Get-SafeEncodingSample {
    param(
        [string]$Text
    )

    $sample = ($Text -replace '\s+', ' ').Trim()
    $sample = $sample -replace '[\x00-\x1F\x7F-\x9F]', '?'

    if ($sample.Length -gt 80) {
        return $sample.Substring(0, 80)
    }

    return $sample
}

function Get-ByteDecodeSample {
    param(
        [byte[]]$Bytes,
        [int]$ByteIndex
    )

    $fallbackUtf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $false
    $startIndex = [Math]::Max(0, $ByteIndex - 30)
    $length = [Math]::Min(80, $Bytes.Length - $startIndex)

    return Get-SafeEncodingSample -Text ($fallbackUtf8.GetString($Bytes, $startIndex, $length))
}

function Get-MojibakeSuspicion {
    param(
        [string]$Content
    )

    $replacementCharacter = [regex]::Escape((New-StringFromCodePoints -CodePoints @(0xFFFD)))
    $knownMojibakeTokens = @(
        ("?" + (New-StringFromCodePoints -CodePoints @(0x0080))),
        ("?" + (New-StringFromCodePoints -CodePoints @(0xAFA9))),
        ("?" + (New-StringFromCodePoints -CodePoints @(0xBA2F))),
        ("?" + (New-StringFromCodePoints -CodePoints @(0xC496)))
    )
    $latinMojibakePrefixes = @(
        (New-StringFromCodePoints -CodePoints @(0x00EC)),
        (New-StringFromCodePoints -CodePoints @(0x00ED)),
        (New-StringFromCodePoints -CodePoints @(0x00EB)),
        (New-StringFromCodePoints -CodePoints @(0x00EA)),
        (New-StringFromCodePoints -CodePoints @(0x00C3)),
        (New-StringFromCodePoints -CodePoints @(0x00C2))
    )
    $latinMojibakePattern = (($latinMojibakePrefixes | ForEach-Object { [regex]::Escape($_) }) -join "|")
    $patterns = @(
        @{ Reason = "replacement_character"; Pattern = $replacementCharacter },
        @{ Reason = "c1_control"; Pattern = '[\x80-\x9F]' },
        @{ Reason = "latin_mojibake_prefix"; Pattern = $latinMojibakePattern }
    )

    foreach ($token in $knownMojibakeTokens) {
        $patterns += @{ Reason = "known_mojibake_token"; Pattern = [regex]::Escape($token) }
    }

    $lines = @($Content -split "\r?\n")

    for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex += 1) {
        foreach ($pattern in $patterns) {
            if ($lines[$lineIndex] -match $pattern.Pattern) {
                return [pscustomobject]@{
                    Line = $lineIndex + 1
                    Reason = $pattern.Reason
                    Sample = Get-SafeEncodingSample -Text $lines[$lineIndex]
                }
            }
        }
    }

    return $null
}

function Test-DocumentationEncoding {
    $strictUtf8 = New-Object System.Text.UTF8Encoding -ArgumentList $false, $true
    $files = @(Get-DocumentationEncodingFiles)
    $findingCount = 0

    foreach ($file in $files) {
        $relativePath = Get-RepoRelativePath -FullPath $file.FullName
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $content = ""

        try {
            $content = $strictUtf8.GetString($bytes)
        }
        catch [System.Text.DecoderFallbackException] {
            $byteIndex = $_.Exception.Index
            $findingCount += 1
            Add-HarnessWarning -Check "document-encoding" -Metadata @{
                path = $relativePath
                line = Get-LineNumberFromByteIndex -Bytes $bytes -ByteIndex $byteIndex
                reason = "invalid_utf8"
                sample = Get-ByteDecodeSample -Bytes $bytes -ByteIndex $byteIndex
            }
            continue
        }

        $suspicion = Get-MojibakeSuspicion -Content $content

        if ($null -eq $suspicion) {
            continue
        }

        $findingCount += 1
        Add-HarnessWarning -Check "document-encoding" -Metadata @{
            path = $relativePath
            line = $suspicion.Line
            reason = $suspicion.Reason
            sample = $suspicion.Sample
        }
    }

    if ($findingCount -eq 0) {
        Write-HarnessLog -Check "document-encoding" -Status "success" -Metadata @{
            scanned = $files.Count
        }
    }
}
