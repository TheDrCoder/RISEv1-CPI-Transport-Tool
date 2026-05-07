# Dummy string with at least 300 characters
$inputString = "0020000562 00000000 2025011520250715005056B2D9DD1EEFB4FF276349AE2A14 0"

# Substring from character 193 to 252 (PowerShell uses 0-based indexing)
$startIndex = 193  # 193rd character
$length = 32       # 252 - 193 + 1

# Check if the string is long enough
if ($inputString.Length -ge ($startIndex + $length)) {
    $substring = $inputString.Substring($startIndex, $length)
    Write-Host "Substring (193 to 252): $substring"
} else {
    Write-Host "The input string is not long enough to extract characters 193 to 252."
}
