# Define Paths (Replace these with actual values before running)
$SourceExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\source_06c45eb4"
$MZipPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs"
$TargetExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\target_307ac129"
$OutputManifest = "$MZipPath\ModifiedManifest2.MF"

# Define Manifest File Paths
$SourceManifestPath = "$SourceExtractPath\META-INF\MANIFEST.MF"
$TargetManifestPath = "$TargetExtractPath\META-INF\MANIFEST.MF"

# Define Keys to Replace
$KeysToReplace = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")

# Ensure Files Exist
if (-not (Test-Path $SourceManifestPath)) { Write-Host "❌ Source Manifest Not Found!"; exit }
if (-not (Test-Path $TargetManifestPath)) { Write-Host "❌ Target Manifest Not Found!"; exit }

### 📌 Function to Read a Manifest File While Preserving Multi-Line Formatting
function Read-ManifestFile {
    param ([string]$filePath)
    $manifestLines = Get-Content -Path $filePath
    $manifestContent = ""

    foreach ($line in $manifestLines) {
        if ($line -match "^\s") { $manifestContent += $line.TrimStart() }
        else { $manifestContent += "`n" + $line }
    }

    return $manifestContent.Trim()
}

### 📌 Function to Extract Values from the Manifest File
function Extract-ManifestValues {
    param ([string]$content, [array]$keys)
    $values = @{}

    foreach ($key in $keys) {
        $regex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"
        $match = [regex]::Match($content, $regex)
        if ($match.Success) {
            $values[$key] = $match.Groups[1].Value  # Preserve formatting
        }
    }
    return $values
}

### 📌 Function to Replace Manifest Values and Preserve Formatting
function Replace-ManifestValues {
    param ([string]$sourceContent, [hashtable]$targetValues, [array]$keys)
    
    foreach ($key in $keys) {
        if ($targetValues.ContainsKey($key) -and $targetValues[$key]) {
            $sourceRegex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"

            # Debugging: Show exact matches before replacement
            $matches = [regex]::Match($sourceContent, $sourceRegex)
            Write-Host "`n🔎 Matching Source Manifest for Key: $key"
            Write-Host "--------------------------------------"
            Write-Host "🔹 Matched Value: '$($matches.Value)'"
            Write-Host "🔹 Replacing With: '$($targetValues[$key])'"
            Write-Host "--------------------------------------`n"

            # Perform replacement **without modifying formatting**
            $replacement = "${key}: $($targetValues[$key])"
            $sourceContent = [regex]::Replace($sourceContent, $sourceRegex, $replacement)
        }
    }
    return $sourceContent
}

### 🚀 **Process Execution Starts Here**
# Read Source and Target Manifest Files
$SourceContent = Read-ManifestFile -filePath $SourceManifestPath
$TargetContent = Read-ManifestFile -filePath $TargetManifestPath

# Extract Values from the Target Manifest
$TargetValues = Extract-ManifestValues -content $TargetContent -keys $KeysToReplace

# Debug: Print Extracted Target Values
Write-Host "`n📝 Target Values from Target Manifest:"
Write-Host "----------------------------------------------------"
foreach ($key in $TargetValues.Keys) { Write-Host "🔹 $key = '$($TargetValues[$key])'" }
Write-Host "----------------------------------------------------`n"

# Replace Values in the Source Manifest
$ModifiedContent = Replace-ManifestValues -sourceContent $SourceContent -targetValues $TargetValues -keys $KeysToReplace

# Save the Modified Manifest File
$ModifiedContent | Set-Content -Path $OutputManifest -Encoding UTF8

Write-Host "✅ Manifest file has been successfully modified and saved as $OutputManifest"

# Debug: Print Extracted New Values from the Modified Manifest
$NewContent = Read-ManifestFile -filePath $OutputManifest
$NewValues = Extract-ManifestValues -content $NewContent -keys $KeysToReplace

Write-Host "`n📝 New Manifest Values After Replacement:"
Write-Host "----------------------------------------------------"
foreach ($key in $NewValues.Keys) { Write-Host "🔹 $key = '$($NewValues[$key])'" }
Write-Host "----------------------------------------------------`n"
