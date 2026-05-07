function Modify-ManifestFile-And-Archive {
    param (
        [string]$SourceManifestPath,
        [string]$TargetManifestPath,
        [string]$ExtractedSourcePath,   # Path where the extracted source ZIP is
        [string]$OutputZipPath          # Path where the final ZIP should be saved
    )

    Write-Host "📂 Starting Modification of Source Manifest File..."
    Write-Host "📜 Source Manifest Path: $SourceManifestPath"
    Write-Host "📜 Target Manifest Path: $TargetManifestPath"
    Write-Host "📦 Extracted Source Directory: $ExtractedSourcePath"
    Write-Host "📁 Final ZIP Will Be Created At: $OutputZipPath"

    # ** Ensure Both Files Exist **
    if (-not (Test-Path $SourceManifestPath)) {
        Write-Host "❌ Source Manifest file not found!"
        return $null
    }
    if (-not (Test-Path $TargetManifestPath)) {
        Write-Host "❌ Target Manifest file not found!"
        return $null
    }

    # ** Function to Read & Extract Manifest Values **
    function Fetch-ManifestValues {
        param ([string]$ManifestFilePath)

        # ** Ensure File Exists **
        if (-not (Test-Path $ManifestFilePath)) {
            Write-Host "❌ Manifest file not found: $ManifestFilePath"
            return $null
        }

        # ** Read Manifest File Content (Preserving Multi-Line Values) **
        $manifestLines = Get-Content -Path $ManifestFilePath
        $manifestContent = ""
        foreach ($line in $manifestLines) {
            if ($line -match "^\s") {
                $manifestContent += $line.TrimStart()
            } else {
                $manifestContent += "`n" + $line
            }
        }

        # ** Function to Extract Values from Manifest Content **
        function Extract-ManifestValue {
            param ([string]$content, [string]$key)
            $pattern = "(?ms)^${key}:\s*(.+?)(?=\n\S|$)"
            $match = [regex]::Match($content, $pattern)
            if ($match.Success) {
                return $match.Groups[1].Value.Trim() -replace "\s{2,}", " "
            }
            return ""
        }

        # ** Extract Values **
        $values = @{
            "Bundle-SymbolicName"        = Extract-ManifestValue -content $manifestContent -key "Bundle-SymbolicName"
            "Origin-Bundle-SymbolicName" = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-SymbolicName"
            "Origin-Bundle-Name"         = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-Name"
            "Bundle-Name"                = Extract-ManifestValue -content $manifestContent -key "Bundle-Name"
        }

        return $values
    }

    # ** Fetch & Print BEFORE Modification Values **
    Write-Host "🔍 Fetching BEFORE Modification Manifest Values (Source)"
    $beforeValues = Fetch-ManifestValues -ManifestFilePath $SourceManifestPath
    Write-Host "📄 BEFORE Modification Manifest Values: $($beforeValues | ConvertTo-Json -Depth 2)"

    # ** Fetch Target Values for Replacement **
    Write-Host "🔍 Fetching Target Manifest Values for Replacement"
    $targetValues = Fetch-ManifestValues -ManifestFilePath $TargetManifestPath
    Write-Host "📄 Target Manifest Values to Apply: $($targetValues | ConvertTo-Json -Depth 2)"

    # ** Function to Replace Values in Source Manifest **
    function Replace-ManifestValue {
        param ([string]$content, [string]$key, [string]$newValue)
        $pattern = "(?ms)^(${key}:\s*)(.+?)(?=\n\S|$)"
        if ($content -match $pattern) {
            return $content -replace $pattern, "`$1$newValue"
        }
        return $content
    }

    # ** Read Source Manifest & Modify Content **
    $sourceLines = Get-Content -Path $SourceManifestPath
    $sourceContent = ""
    foreach ($line in $sourceLines) {
        if ($line -match "^\s") {
            $sourceContent += $line.TrimStart()
        } else {
            $sourceContent += "`n" + $line
        }
    }

    # ** Apply Modifications Using Target Values **
    $modifiedSourceContent = $sourceContent
    foreach ($key in $targetValues.Keys) {
        $modifiedSourceContent = Replace-ManifestValue -content $modifiedSourceContent -key $key -newValue $targetValues[$key]
    }

    # ** Write Back Updated Content to Source Manifest **
    $modifiedSourceContent -split "`n" | Set-Content -Path $SourceManifestPath -Encoding UTF8
    Write-Host "✅ Successfully Modified Source Manifest File"

    # ** Fetch & Print AFTER Modification Values **
    Write-Host "🔍 Fetching AFTER Modification Manifest Values (Source)"
    $afterValues = Fetch-ManifestValues -ManifestFilePath $SourceManifestPath
    Write-Host "📄 AFTER Modification Manifest Values: $($afterValues | ConvertTo-Json -Depth 2)"

    # ** Archive the Updated Source Folder into a New ZIP File **
    Write-Host "📦 Creating ZIP Archive for Transport..."
    if (Test-Path $OutputZipPath) {
        Remove-Item -Path $OutputZipPath -Force
    }
    Compress-Archive -Path "$ExtractedSourcePath\*" -DestinationPath $OutputZipPath -Force
    Write-Host "✅ ZIP Created: $OutputZipPath"

    return @{
        Status          = "success"
        ModifiedZipFile = $OutputZipPath
        BeforeValues    = $beforeValues
        AfterValues     = $afterValues
    }
}
$SourceManifestPath = "C:\temp\CPITransport\Extracted_source\META-INF\MANIFEST.MF"
$TargetManifestPath = "C:\temp\CPITransport\Extracted_target\META-INF\MANIFEST.MF"
$ExtractedSourcePath = "C:\temp\CPITransport\Extracted_source"
$OutputZipPath = "C:\temp\CPITransport\Modified_Artifact.zip"

Modify-ManifestFile-And-Archive -SourceManifestPath $SourceManifestPath -TargetManifestPath $TargetManifestPath -ExtractedSourcePath $ExtractedSourcePath -OutputZipPath $OutputZipPath