# Define Paths (Replace with actual values)
$SourceExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\source_06c45eb4"
$MZipPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs"
$TargetExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\target_307ac129"

# Expected file paths
$SourceManifestPath = "$SourceExtractPath\META-INF\MANIFEST.MF"
$TargetManifestPath = "$TargetExtractPath\META-INF\MANIFEST.MF"
$OutputZipPath = "$MZipPath\Modified_Artifact.zip"

# 🚀 Function to Extract Manifest Values
function Extract-ManifestValue {
    param ([string]$content, [string]$key)
    $pattern = "(?m)^${key}:\s*(.+?)(?=\n\S|$)"
    $match = [regex]::Match($content, $pattern)
    if ($match.Success) { return $match.Groups[1].Value.Trim() }
    return ""
}

# 🚀 Function to Fix Manifest Formatting
function Fix-Manifest-Formatting {
    param ([string]$content)

    Write-Host "🛠 Fixing Manifest Formatting..."
    $content = $content -replace "^\uFEFF", ""   # Remove BOM if present
    $content = $content -replace "\r", ""       # Remove carriage returns
    $content = $content -replace "\n\s", " "    # Fix incorrect line breaks
    return $content
}

# 🚀 Function to Modify Manifest File
function Modify-ManifestFile {
    param ([string]$SourceManifestPath, [string]$TargetManifestPath)

    Write-Host "🚀 Modifying Manifest File..."

    # Read Source and Target Manifest **without BOM**
    $sourceContent = [System.IO.File]::ReadAllText($SourceManifestPath, [System.Text.Encoding]::UTF8) | Fix-Manifest-Formatting
    $targetContent = [System.IO.File]::ReadAllText($TargetManifestPath, [System.Text.Encoding]::UTF8) | Fix-Manifest-Formatting

    # Extract values from Target Manifest
    $replacementValues = @{
        "Bundle-SymbolicName"        = Extract-ManifestValue -content $targetContent -key "Bundle-SymbolicName"
        "Origin-Bundle-SymbolicName" = Extract-ManifestValue -content $targetContent -key "Origin-Bundle-SymbolicName"
        "Origin-Bundle-Name"         = Extract-ManifestValue -content $targetContent -key "Origin-Bundle-Name"
        "Bundle-Name"                = Extract-ManifestValue -content $targetContent -key "Bundle-Name"
    }
    
      # **📝 Print Extracted Values in Console for Debugging**
    Write-Host "`n📝 Replacement Values Extracted from Target Manifest:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $replacementValues.Keys) {
        Write-Host "🔹 $key = '$($replacementValues[$key])'"
    }
    Write-Host "----------------------------------------------------`n"

    # Function to Replace Values in Manifest
    function Replace-ManifestValue {
        param (
            [string]$content,
            [string]$key,
            [string]$newValue
        )

        # **Ensure spaces remain intact**
        $newValue = $newValue -replace "_", " "   # Fix underscores
        $newValue = $newValue -replace "\r", ""   # Remove carriage returns
        $newValue = $newValue -replace "\n", " "  # Replace unintended newlines with spaces

        # **Correct Java Manifest formatting (Max line length: 72 chars)**
        $lineLengthLimit = 72
        $formattedValue = "${key}: "  
        $remainingText = $newValue

        while ($remainingText.Length -gt $lineLengthLimit - $formattedValue.Length) {
            $formattedValue += $remainingText.Substring(0, $lineLengthLimit - $formattedValue.Length) + "`n "
            $remainingText = $remainingText.Substring($lineLengthLimit - $formattedValue.Length)
        }
        $formattedValue += $remainingText  

        # **Replace the key's value in the manifest content**
        $pattern = "(?ms)^(${key}:\s*)(.+?)(?=\n\S|$)"
        if ($content -match $pattern) {
            return $content -replace $pattern, "`$1$formattedValue"
        }

        return $content
    }

    # Modify Source Manifest
    foreach ($key in $replacementValues.Keys) {
        $sourceContent = Replace-ManifestValue -content $sourceContent -key $key -newValue $replacementValues[$key]
    }

    # ✅ **Write to Manifest File WITHOUT BOM**
    $utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false  
    [System.IO.File]::WriteAllText($SourceManifestPath, $sourceContent, $utf8NoBomEncoding)

    Write-Host "✅ Manifest Modified Successfully Without BOM!"
}

# 🚀 Preserve Folder Structure While Creating ZIP
function Create-Zip {
    param ([string]$ExtractedPath, [string]$ZipPath)

    Write-Host "📦 Creating ZIP Archive..."
    if (Test-Path $ZipPath) { Remove-Item -Path $ZipPath -Force }

    # Load required .NET assembly
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    # Create ZIP file
    $zipStream = [System.IO.File]::Create($ZipPath)
    $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

    # Add files while preserving directory structure
    Get-ChildItem -Path $ExtractedPath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($ExtractedPath.Length + 1) -replace "\\", "/"
        $entry = $zipArchive.CreateEntry($relativePath)
        $stream = $entry.Open()
        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Close()
    }

    # Close ZIP
    $zipArchive.Dispose()
    $zipStream.Close()

    Write-Host "✅ ZIP Created Successfully: $ZipPath"
}

# 🚀 Convert ZIP to Base64
function Convert-ZipToBase64 {
    param ([string]$ZipPath)

    Write-Host "🔄 Converting ZIP to Base64..."
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    $base64String = [Convert]::ToBase64String($bytes)
    
    # Save Base64 to file
    $base64FilePath = "$ZipPath.base64.txt"
    $base64String | Set-Content -Path $base64FilePath -Encoding UTF8

    Write-Host "✅ Base64 Output saved to: $base64FilePath"
    return $base64String
}

# 🚀 Run Steps
Write-Host "🔍 Running Local Test..."

# Step 1: Modify Manifest
Modify-ManifestFile -SourceManifestPath $SourceManifestPath -TargetManifestPath $TargetManifestPath

# Step 2: Create ZIP Archive
Create-Zip -ExtractedPath $SourceExtractPath -ZipPath $OutputZipPath

# Step 3: Convert ZIP to Base64
$base64Zip = Convert-ZipToBase64 -ZipPath $OutputZipPath

# Step 4: Print Base64 Output
Write-Host "📋 Base64 ZIP Content (Copy this for Postman):"
#Write-Output $base64Zip

Write-Host "🎯 Testing Completed! Check the ZIP and Base64 output."
