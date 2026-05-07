##############################################
# SAP CPI Transport Tool - PowerShell Server
# ===========================================
# This script starts a local web server, serves an HTML UI,
# and handles API requests to fetch SAP CPI integration packages.
##############################################

# ** 1️⃣ START WEBSERVER AND OPEN BROWSER **


# Start the HTTP Listener (PowerShell Web Server)
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:9090/")  # Change port if needed
$listener.Start()
Write-Host "✅ PowerShell Server started at http://localhost:9090/"

# Automatically open the UI in the default web browser
Start-Process "http://localhost:9090/index.html"

# ** 2️⃣ FUNCTION: SERVE STATIC FILES (e.g., `index.html`) **

function Serve-HTMLFile {
    param (
        [string]$RequestedPath,
        $context
    )

    # ** Hardcoded File Path **
    $filePath = "C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\index.html"

    Write-Host "📁 Looking for index.html at: $filePath"

    # ** Serve the HTML File **
    if ($RequestedPath -eq "/" -or $RequestedPath -eq "/index.html") {
        if (Test-Path $filePath) {
            Write-Host "📄 Serving HTML File: $filePath"
            $content = Get-Content -Path $filePath -Raw
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($content)

            # Set response headers
            $context.Response.ContentType = "text/html"
            $context.Response.ContentLength64 = $buffer.Length

            # ** Write the response correctly **
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        } else {
            Write-Host "❌ index.html NOT FOUND at: $filePath"
            $context.Response.StatusCode = 404
        }
        $context.Response.Close()
        return $true  # File served
    }
    return $false  # Not a static file request
}





# ** 3️⃣ FUNCTION: FETCH SAP CPI ACCESS TOKEN **

function Get-AccessToken {
    param (
        [string]$TokenUrl,
        [string]$ClientId,
        [string]$ClientSecret
    )

    Write-Host "🔑 Fetching Access Token from: $TokenUrl"

    if (-not $TokenUrl -or -not $ClientId -or -not $ClientSecret) {
        Write-Host "❌ Missing required parameters for token request."
        return $null
    }

    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    try {
        Write-Host "📡 Sending OAuth token request..."
        $response = Invoke-WebRequest -Uri $TokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        Write-Host "🔄 Token API Response Code: $($response.StatusCode)"
        $jsonResponse = $response.Content | ConvertFrom-Json

        if ($jsonResponse -and $jsonResponse.access_token) {
            Write-Host "✅ Access Token received successfully."
            return $jsonResponse.access_token
        } else {
            Write-Host "⚠️ No access token found in the response."
            return $null
        }
    } catch {
        Write-Host "❌ Error obtaining access token: $($_.Exception.Message)"
        return $null
    }
}

# ** 4️⃣ FUNCTION: FETCH INTEGRATION PACKAGES FROM SAP CPI **

function Fetch-IntegrationPackages {
    param (
        [string]$BaseUrl,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenUrl
    )

    Write-Host "📡 Fetching Integration Packages from: $BaseUrl"

    if (-not $BaseUrl) {
        Write-Host "❌ Missing Base URL. Cannot proceed."
        return $null
    }

    # Step 1: Get OAuth Token
    $AccessToken = Get-AccessToken -TokenUrl $TokenUrl -ClientId $ClientId -ClientSecret $ClientSecret

    if (-not $AccessToken) {
        Write-Host "❌ Failed to obtain access token."
        return $null
    }

    # Construct API URL
    $FullUrl = $BaseUrl + "/api/v1/IntegrationPackages"
    Write-Host "🌍 Calling API: $FullUrl"

    # Set request headers
    $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept        = "application/json, application/atom+xml"
    }

    try {
        $response = Invoke-WebRequest -Uri $FullUrl -Headers $headers -Method Get
        Write-Host "🔄 API Response Code: $($response.StatusCode)"

        $contentType = $response.Headers['Content-Type']

        if ($contentType -like "application/atom+xml*") {
            Write-Host "📄 Processing Atom XML response..."
            $xmlDoc = [xml]$response.Content
            $entries = $xmlDoc.feed.entry

            $packageData = @()
            foreach ($entry in $entries) {
                $properties = $entry.content.properties
                $packageObject = [PSCustomObject]@{
                    Id   = $properties.Id
                    Name = $properties.Name
                }
                $packageData += $packageObject
            }
            return $packageData
        }
        elseif ($contentType -like "application/json*") {
            Write-Host "📝 Processing JSON response..."
            $jsonResponse = $response.Content | ConvertFrom-Json
            return $jsonResponse.d.results
        } else {
            Write-Host "⚠️ Unsupported Content-Type: $contentType"
            return $null
        }
    } catch {
        Write-Host "❌ Error during API call: $_"
        return $null
    }
}

# ** 5️⃣ MAIN LOOP: HANDLE REQUESTS FROM BROWSER UI **

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $urlPath = $request.Url.AbsolutePath

        Write-Host "📩 Incoming API Request: $urlPath"
        Write-Host "🔄 Request Method: $($request.HttpMethod)"

        # ** Serve HTML UI if requested **
        if ($request.HttpMethod -eq "GET" -and ($urlPath -eq "/" -or $urlPath -eq "/index.html")) {
            Serve-HTMLFile -RequestedPath $urlPath -context $context
            continue
        }

        # ** Ensure this is a POST request for API calls **
        if ($request.HttpMethod -ne "POST") {
            Write-Host "⚠️ Invalid request method: $($request.HttpMethod)"
            $response.StatusCode = 405  # Method Not Allowed
            $response.Close()
            continue
        }

        # ** Read JSON Request Body **
        $reader = New-Object System.IO.StreamReader($request.InputStream)
        $bodyText = $reader.ReadToEnd()
        
        Write-Host "📜 Raw JSON Received: $bodyText"

        # ** Parse JSON Safely **
        try {
            $body = $bodyText | ConvertFrom-Json
            Write-Host "✅ Parsed JSON Successfully"
        } catch {
            Write-Host "❌ JSON Parsing Error: $_"
            $response.StatusCode = 400  # Bad Request
            $response.Close()
            continue
        }

        # ** Validate Required Fields **
        if (-not $body.sourceBaseUrl -or -not $body.targetBaseUrl) {
            Write-Host "❌ Missing required fields in request."
            $response.StatusCode = 400  # Bad Request
            $response.Close()
            continue
        }

        # ** Fetch Source & Target Packages **
        $sourcePackages = Fetch-IntegrationPackages -BaseUrl $body.sourceBaseUrl -ClientId $body.sourceClientId -ClientSecret $body.sourceClientSecret -TokenUrl $body.sourceTokenUrl
        $targetPackages = Fetch-IntegrationPackages -BaseUrl $body.targetBaseUrl -ClientId $body.targetClientId -ClientSecret $body.targetClientSecret -TokenUrl $body.targetTokenUrl

        # ** Ensure Response is in JSON Format **
        $response.ContentType = "application/json"
        
        if (-not $sourcePackages) { $sourcePackages = @() }
        if (-not $targetPackages) { $targetPackages = @() }

        $jsonResponse = @{
            sourcePackages = $sourcePackages
            targetPackages = $targetPackages
        } | ConvertTo-Json -Depth 3

        # ** Send Response to Frontend **
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
        Write-Host "✅ Successfully sent integration packages to frontend."

        $response.Close()
    } catch {
        Write-Host "❌ Exception in main loop: $_"
        $response.StatusCode = 500  # Internal Server Error
        $response.Close()
    }
}

