# Define Paths (Replace these with actual values before running)
$SourceExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\source_06c45eb4"
$MZipPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs"
$TargetExtractPath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\target_307ac129"
$OutputManifest = "$MZipPath\ModifiedManifest35.MF"

# Define Manifest File Paths
$SourceManifestPath = "$SourceExtractPath\META-INF\MANIFEST.MF"
$TargetManifestPath = "$TargetExtractPath\META-INF\MANIFEST.MF"

# Define Keys to Replace
$KeysToReplace = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")

# Ensure Files Exist
if (-not (Test-Path $SourceManifestPath)) { Write-Host "❌ Source Manifest Not Found!"; exit }
if (-not (Test-Path $TargetManifestPath)) { Write-Host "❌ Target Manifest Not Found!"; exit }

### 📌 Function to Read Manifest File (Preserving Multi-Line Formatting)
function Read-ManifestFile {
    param ([string]$filePath)
    $manifestLines = Get-Content -Path $filePath
    $manifestContent = ""

    foreach ($line in $manifestLines) {
        if ($line -match "^\s") { $manifestContent += "`n" + $line }  # Preserve leading spaces for continuation lines
        else { $manifestContent += "`n" + $line }
    }
    return $manifestContent.Trim()
}

### 📌 Function to Extract Multi-Line Values Without Modifying Format

function Extract-ManifestValues {
    param ([string]$content, [array]$keys)
    $values = @{}

    foreach ($key in $keys) {
        $regex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"
        $match = [regex]::Match($content, $regex)
        if ($match.Success) {
            $values[$key] = $match.Value  # Preserve full multi-line format
        }
    }
    return $values
}


<#
function Extract-ManifestValues {
    param ([string]$content, [array]$keys)
    $values = @{}

    foreach ($key in $keys) {
        $regex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"
        $match = [regex]::Match($content, $regex)
        if ($match.Success) {
            $values[$key] = $match.Value  # Preserve full multi-line format
        }
    }
    return $values
}
#>

### 📌 Function to Replace Multi-Line Values While Keeping Original Formatting

function Replace-ManifestValues {
    param ([string]$sourceContent, [hashtable]$targetValues, [array]$keys)
    
    foreach ($key in $keys) {
        if ($targetValues.ContainsKey($key) -and $targetValues[$key]) {
            $sourceRegex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"

            # Debugging: Show exact matches before replacement
            $matches = [regex]::Match($sourceContent, $sourceRegex)
            Write-Host "`n🔎 Matching Source Manifest for Key: $key"
            Write-Host "--------------------------------------"
            Write-Host "🔹 Matched Value (Source): '$($matches.Value)'"
            Write-Host "🔹 Replacing With (Target): '$($targetValues[$key])'"
            Write-Host "--------------------------------------`n"

            # Perform precise replacement while keeping multi-line structure
            $sourceContent = [regex]::Replace($sourceContent, $sourceRegex, $targetValues[$key])
        }
    }
    return $sourceContent
}


<#
function Replace-ManifestValues {
    param ([string]$sourceContent, [hashtable]$targetValues, [array]$keys)
    
    foreach ($key in $keys) {
        if ($targetValues.ContainsKey($key) -and $targetValues[$key]) {
            $sourceRegex = "(?m)^${key}:\s*(.*(?:\r?\n\s+.*)*)"

            # Debugging: Show exact matches before replacement
            $matches = [regex]::Match($sourceContent, $sourceRegex)
            Write-Host "`n🔎 Matching Source Manifest for Key: $key"
            Write-Host "--------------------------------------"
            Write-Host "🔹 Matched Value (Source): '$($matches.Value)'"
            Write-Host "🔹 Replacing With (Target): '$($targetValues[$key])'"
            Write-Host "--------------------------------------`n"

            # Perform precise replacement while keeping multi-line structure
            $sourceContent = [regex]::Replace($sourceContent, $sourceRegex, $targetValues[$key])
        }
    }
    return $sourceContent
}

#>

# Function to save the manifest file while preserving multi-line formatting
function Save-ManifestFile {
    param (
        [string]$filePath,
        [string[]]$contentLines
    )

    # Open the file with UTF-8 encoding (without BOM)
    $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
    $streamWriter = [System.IO.StreamWriter]::new($filePath, $false, $utf8NoBOM)

    try {
        foreach ($line in $contentLines) {
            # Write each line exactly as it appears in memory
            $streamWriter.WriteLine($line)
        }
    } finally {
        $streamWriter.Close()
    }

    Write-Host "✅ Manifest file has been successfully modified and saved as $filePath (without BOM, preserving line breaks)"
}



# Function to save content without BOM in PowerShell 5.1
# Function to save content without BOM while preserving line breaks
function Save-FileWithoutBOM {
    param (
        [string]$filePath,
        [string]$content
    )

    # Ensure line endings are CRLF
    $content = $content -replace "`r?`n", "`r`n"  

    # Split content into individual lines and write manually
    $utf8NoBOM = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines($filePath, $content -split "`r`n", $utf8NoBOM)

    Write-Host "✅ Manifest file has been successfully modified and saved as $filePath (without BOM, with preserved line breaks)"
}


### 📌 Function to Process Manifest Replacement (Everything in One Function)
function Process-ManifestReplacement {
    param (
        [string]$sourceFile,
        [string]$targetFile,
        [string]$outputFile
        
    )
    $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")

    # Read Source and Target Manifest Files
    $sourceContent = Read-ManifestFile -filePath $sourceFile
    $targetContent = Read-ManifestFile -filePath $targetFile

    # Extract Values from Target Manifest
    $TargetValues = Extract-ManifestValues -content $targetContent -keys $keys

    # Debug: Print Extracted Target Values
    Write-Host "`n📝 Extracted Target Values:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $TargetValues.Keys) { Write-Host "🔹 $key = '$($TargetValues[$key])'" }
    Write-Host "----------------------------------------------------`n"

    # Ensure the first line does not contain BOM or extra characters
#$ModifiedContent = $ModifiedContent -replace "^\uFEFF", ""  # Remove BOM if present
#$ModifiedContent = $ModifiedContent -replace "^\s*", ""  # Remove leading spaces

# Convert modified content to an array of lines and save
 # Save the Modified Manifest File
    $ModifiedContent | Set-Content -Path $outputFile -Encoding UTF8
    Write-Host "✅ Manifest file has been successfully modified and saved as $outputFile"

    # Debug: Verify Final Values After Replacement
    $NewContent = Read-ManifestFile -filePath $outputFile
    $NewValues = Extract-ManifestValues -content $NewContent -keys $keys

    Write-Host "`n📝 New Manifest Values After Replacement:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $NewValues.Keys) { Write-Host "🔹 $key = '$($NewValues[$key])'" }
    Write-Host "----------------------------------------------------`n"
}

### 🚀 **Execute the Function**
Process-ManifestReplacement -sourceFile $SourceManifestPath -targetFile $TargetManifestPath -outputFile $OutputManifest 
