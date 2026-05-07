# ===========================================
# 🚀 Fixed PowerShell Script - Upload SAP CPI Artifact
# ===========================================

# Set Variables
$ArtifactFile = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\mod_17d71917.zip"
$AccessToken = "eyJhbGciOiJSUzI1NiIsImprd..."  # Replace with a valid token
$PackageId = "SWMXCustomerEnhancementS4C4PostProcess"
$ArtifactId = "mod_3465c3e0-a4eb-4ece-9f5e-c9731927ce25"
$ArtifactName = "Modified_Artifact_Test"
$TargetBaseUrl = "https://swmx-test-lucfr9vh.it-cpi005.cfapps.eu20.hana.ondemand.com"
$UploadUrl = "$TargetBaseUrl/api/v1/IntegrationDesigntimeArtifacts"

# ** Validate File Existence **
if (-not (Test-Path $ArtifactFile)) {
    Write-Host "❌ ERROR: Artifact file not found: $ArtifactFile"
    exit 1
}

# ** Read ZIP File as Binary Stream **
$FileBytes = [System.IO.File]::ReadAllBytes($ArtifactFile)

# ** Debugging Information **
Write-Host "📂 Artifact File Path: $ArtifactFile"
Write-Host "🎯 Upload URL: $UploadUrl"
Write-Host "📦 Package ID: $PackageId"
Write-Host "🆔 Artifact ID: $ArtifactId"
Write-Host "📄 Reading ZIP File... (Size: $($FileBytes.Length) bytes)"

# ** Set Headers **
$Headers = @{
    "Authorization" = "Bearer $AccessToken"
    "Accept"        = "application/json"
}

# ** Create Multi-Part Form Data Body **
$Body = @{
    "PackageId" = $PackageId
    "Id"        = $ArtifactId
    "Name"      = $ArtifactName
    "file"      = [System.IO.File]::ReadAllBytes($ArtifactFile)  # Upload as binary file
}

# ** Send API Request (POST Method) using Multi-Part Form Data **
try {
    Write-Host "📡 Sending Upload Request..."
    $response = Invoke-RestMethod -Uri $UploadUrl -Headers $Headers -Method Post -Form $Body

    Write-Host "✅ Upload Successful! Response from Server:"
    Write-Host $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Upload Failed!"
    Write-Host "🔴 Error Message: $_"
}
