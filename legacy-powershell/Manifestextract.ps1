# **Determine Current Script Path Dynamically**
if ($PSScriptRoot) {
    $global:BasePath = "$PSScriptRoot\CPITransportTool_Data"
} else {
    $global:BasePath = "$(Get-Location)\CPITransportTool_Data"
}

# **Ensure Main Working Directory Exists**
if (-not (Test-Path $global:BasePath)) {
    New-Item -ItemType Directory -Path $global:BasePath | Out-Null
    Write-Host "📂 Created Working Directory: $global:BasePath"
}

# **Define and Ensure Subdirectories Exist**
$global:ZipPath = "$global:BasePath\ZIPs"             # Store ZIP files
$global:ExtractPath = "$global:ZipPath\Extracted"      # Extracted ZIP contents

@($global:ZipPath, $global:ExtractPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ | Out-Null
        Write-Host "📂 Created Directory: $_"
    }
}


Write-Host "✅ Working Directory Setup Completed!"




function Test-Extract-Manifest {
    param (
        [string]$ManifestFilePath
    )

    Write-Host "📂 Testing Manifest Extraction from: $ManifestFilePath"

    # ** Ensure the Manifest file exists before proceeding **
    if (-not (Test-Path $ManifestFilePath)) {
        Write-Host "❌ Manifest file not found: $ManifestFilePath"
        return $null
    }

    # ** Read Manifest File Content **
    #$manifestContent = Get-Content -Path $ManifestFilePath -Raw

     # ** Read Manifest File Content (Preserve Line Breaks) **
    $manifestLines = Get-Content -Path $ManifestFilePath

    # ** Join Wrapped Lines Correctly (Handling Multi-Line Values) **
    $manifestContent = ""
    foreach ($line in $manifestLines) {
        if ($line -match "^\s") {
            # If line starts with a space, it's a continuation → append without newline
            $manifestContent += $line.TrimStart()
        } else {
            # Otherwise, it's a new key → add a new line before appending
            $manifestContent += "`n" + $line
        }
    }

    # ** Function to extract values properly, including multi-line ones **
    function Extract-ManifestValue {
        param ([string]$content, [string]$key)

        # ** Look for key and capture everything until the next key starts **
        $pattern = "(?ms)^${key}:\s*(.+?)(?=\n\S|$)"

        $match = [regex]::Match($content, $pattern)

        if ($match.Success) {
            return $match.Groups[1].Value.Trim() -replace "\s{2,}", " "
        }
        return ""
    }

    # ** Extract values using updated function **
    $bundleSymbolicName = Extract-ManifestValue -content $manifestContent -key "Bundle-SymbolicName"
    $originBundleSymbolicName = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-SymbolicName"
    $originBundleName = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-Name"
    $bundleName = Extract-ManifestValue -content $manifestContent -key "Bundle-Name"

    # ** Debugging: Print Extracted Values to Console **
    Write-Host "📝 Extracted Manifest Values:"
    Write-Host "----------------------------------"
    Write-Host "🔹 Bundle-SymbolicName:        $bundleSymbolicName"
    Write-Host "🔹 Origin-Bundle-SymbolicName: $originBundleSymbolicName"
    Write-Host "🔹 Origin-Bundle-Name:         $originBundleName"
    Write-Host "🔹 Bundle-Name:                $bundleName"
    Write-Host "----------------------------------"

    # ** Return Extracted Data as Object **
    $manifestData = @{
        BundleSymbolicName        = $bundleSymbolicName
        OriginBundleSymbolicName  = $originBundleSymbolicName
        OriginBundleName          = $originBundleName
        BundleName                = $bundleName
        ManifestPath              = $ManifestFilePath
    }

    Write-Host "✅ Extracted Manifest Details: $($manifestData | ConvertTo-Json -Depth 2)"
    return $manifestData
}
 #** 2️⃣ Define Manifest File Path for Testing **
$ManifestFilePath = "C:\temp\CPITransport\Extracted_target\META-INF\MANIFEST.MF"

# ** 3️⃣ Execute the Function and Capture the Result **
$extractedData = Test-Extract-Manifest -ManifestFilePath $ManifestFilePath

# ** 4️⃣ Display Results in PowerShell **
Write-Host "`n🎯 Final Extracted Data:"
Write-Host ($extractedData | ConvertTo-Json -Depth 3)

# ** 5️⃣ Pause to View Output (For Manual Execution) **
Read-Host "Press Enter to exit..."