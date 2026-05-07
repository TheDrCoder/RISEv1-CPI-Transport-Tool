# Read ZIP file bytes
$FileBytes = [System.IO.File]::ReadAllBytes("C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\NewMod1.zip")

# Convert to Base64
$Base64Content = [Convert]::ToBase64String($FileBytes)

# Save to test file
$Base64Content | Out-File "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\test_base64.txt"
