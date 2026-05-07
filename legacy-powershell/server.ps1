    ##############################################
    # SAP CPI Transport Tool 
    # ===========================================
    # This script starts a local web server, serves an HTML UI,
    # and handles API requests to fetch SAP CPI integration packages.


    # Developed by Dr. Nineeshu Gupta
    # 2025               

    ##############################################


    # **🔵 Global Variables for Storing API Credentials and Tokens**
    $global:sourceBaseUrl = $null
    $global:sourceClientId = $null
    $global:sourceClientSecret = $null
    $global:sourceTokenUrl = $null
    $global:sourceAccessToken = $null # Will store the access token

    $global:targetBaseUrl = $null
    $global:targetClientId = $null
    $global:targetClientSecret = $null
    $global:targetTokenUrl = $null
    $global:targetAccessToken = $null # Will store the access token

    # Global Variables to Cache Data
    $global:cachedPackages = @{}
    $global:cachedArtifacts = @{}
    $global:cachedArtifactStatus = @{}
    $global:cachedManifests = @{}
    $global:cachedConfigurations = @{}
    $targetZipFilePath = $null
    $sourceZipFilePath = $null
    $global:targetExtractPath = $null
    $global:sourceExtractPath = $null
    $global:ScriptPath = $null
    $global:BasePath = $null
    $global:ZipPath = $null
    $global:ExtractPath = $null
    $global:modifiedZipPath = $null
    $global:modifiedArtifactId = $null
    $global:modifiedArtifactVersion = $null
    $globaltargetArtifactId=$null
    $globalSourceArtifactVersion=$null
    $global:targetArtifactName=$null
    $global:targetPackageID=$null
    $global:CPITenantTYpe=$null



    # **Determine Current Script Path Dynamically**
    if ($PSScriptRoot) {
        $global:BasePath = "$PSScriptRoot\CPITransportTool_Data"
    } else {
        $global:BasePath = "$(Get-Location)\CPITransportTool_Data"
    }

     # **Determine Current Script Path Dynamically**
    if ($PSScriptRoot) {
        $global:ScriptPath = "$PSScriptRoot"
    } else {
        $global:ScriptPath = "$(Get-Location)"
    }
     Write-Host "📂 Created Script Path: $global:ScriptPath"
    # **Ensure Main Working Directory Exists**
    if (-not (Test-Path $global:BasePath)) {
        New-Item -ItemType Directory -Path $global:BasePath | Out-Null
        Write-Host "📂 Created Working Directory: $global:BasePath"
    }

    # **Define and Ensure Subdirectories Exist**
    $global:ZipPath = "$global:BasePath\ZIPs"             # Store ZIP files
    $global:ExtractPath = "$global:ZipPath\Extracted"      # Extracted ZIP contents

     Write-Host "✅ Extract path: $global:ExtractPath"
    @($global:ZipPath, $global:ExtractPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ | Out-Null
            Write-Host "📂 Created Directory: $_"
        }
    }
    Write-Host "✅ Working Directory Setup Completed!"



    # ** 1️⃣ START WEBSERVER AND OPEN BROWSER **

    # Start the HTTP Listener (PowerShell Web Server)
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:9090/") # Change port if needed
    $listener.Start()
    Write-Host "✅ PowerShell Server started at http://localhost:9090/"

    # Automatically open the UI in the default web browser
    Start-Process "http://localhost:9090/index.html"

    # ===========================================
    # DEFINE FUNCTIONS
    ##############################################

    # ** 2️ FUNCTION: SERVE STATIC FILES (e.g., index.html) **
    <#
    function Serve-HTMLFile {
      param(
        [string]$RequestedPath,
        $context
      )

      # ** Hardcoded File Path **
      $filePath = $global:ScriptPath+"/index.html"

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
          $context.Response.OutputStream.Write($buffer,0,$buffer.Length)
        } else {
          Write-Host "❌ index.html NOT FOUND at: $filePath"
          $context.Response.StatusCode = 404
        }
        $context.Response.Close()
        return $true # File served
      }
      return $false # Not a static file request
    }
    #>
    function Serve-StaticFile {
    param(
        [string]$RequestedPath,
        $context
    )

    # Convert URL path to file path dynamically
    $filePath = $global:ScriptPath + $RequestedPath

    # ✅ Ensure the file exists before proceeding
    if (-not (Test-Path $filePath)) {
        Write-Host "❌ File Not Found: $filePath"
        $context.Response.StatusCode = 404
        $context.Response.Close()
        return
    }

    # ✅ Determine Content Type Based on File Extension
    $contentType = "text/plain"
    switch -Regex ($filePath) {
        "\.html$" { $contentType = "text/html" }
        "\.css$" { $contentType = "text/css" }
        "\.js$" { $contentType = "application/javascript" }
        "\.png$" { $contentType = "image/png" }
        "\.jpg$" { $contentType = "image/jpeg" }
        "\.jpeg$" { $contentType = "image/jpeg" }
        "\.ico$" { $contentType = "image/x-icon" }
    }

    # ✅ Serve the file
    Write-Host "📄 Serving File: $filePath"
    $content = [System.IO.File]::ReadAllBytes($filePath)
    $context.Response.ContentType = $contentType
    $context.Response.ContentLength64 = $content.Length
    $context.Response.OutputStream.Write($content, 0, $content.Length)
    $context.Response.Close()
}




    # ** 3 FUNCTION: FETCH SAP CPI ACCESS TOKEN (WITH REUSE) **

    function Get-AccessToken {
      param(
        [string]$TokenUrl,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TenantType # "source" or "target" to determine which token to store
      )

      # ** 2.1.1️⃣ Check if Token is Already Stored **
      if ($TenantType -eq "source" -and $global:sourceAccessToken) {
        Write-Host "🔑 Reusing Existing Access Token for Source CPI Tenant"
        return $global:sourceAccessToken
      }
      if ($TenantType -eq "target" -and $global:targetAccessToken) {
        Write-Host "🔑 Reusing Existing Access Token for Target CPI Tenant"
        return $global:targetAccessToken
      }

      Write-Host "📡 Fetching New Access Token from: $TokenUrl"

      # ** 2.1.2️⃣ Validate Required Parameters **
      if (-not $TokenUrl -or -not $ClientId -or -not $ClientSecret) {
        Write-Host "❌ Missing required parameters for token request."
        return $null
      }

      # ** 2.1.3️⃣ Prepare API Request Body **
      $body = @{
        grant_type = "client_credentials"
        client_id = $ClientId
        client_secret = $ClientSecret
      }

      try {
        # ** 2.1.4️⃣ Make the API Call **
        Write-Host "📡 Sending OAuth token request..."
        $response = Invoke-WebRequest -Uri $TokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        Write-Host "🔄 Token API Response Code: $($response.StatusCode)"
        $jsonResponse = $response.Content | ConvertFrom-Json

        if ($jsonResponse -and $jsonResponse.access_token) {
          Write-Host "✅ Access Token received successfully."

          # ** 2.1.5️⃣ Store Token in Global Variable for Reuse **
          if ($TenantType -eq "source") {
            $global:sourceAccessToken = $jsonResponse.access_token
            Write-Host "🔑 Stored Source Access Token"
          }
          elseif ($TenantType -eq "target") {
            $global:targetAccessToken = $jsonResponse.access_token
            Write-Host "🔑 Stored Target Access Token"
          }

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


    # ** 4 FUNCTION: FETCH INTEGRATION PACKAGES FROM SAP CPI **

    function Fetch-IntegrationPackages {
      param(
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

      $TenantType = if ($BaseUrl -eq $global:sourceBaseUrl) { "source" } else { "target" }

      $AccessToken = Get-AccessToken -TokenUrl $TokenUrl -ClientId $ClientId -ClientSecret $ClientSecret -TenantType $TenantType


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
        Accept = "application/json,application/atom+xml"
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
            $properties = $entry.Content.properties

            # Print all available parameters from API response
            # Write-Host "📜 Package Data Received: $($properties.OuterXml)"

            $packageObject = [pscustomobject]@{
              Id = $properties.Id
              Name = $properties.Name
              Version = $properties.Version
            }
            $packageData += $packageObject
          }
          return $packageData
        }
        elseif ($contentType -like "application/json*") {
          Write-Host "📝 Processing JSON response..."
          $jsonResponse = $response.Content | ConvertFrom-Json
          #Write-Host "📜 JSON Response: $($jsonResponse | ConvertTo-Json -Depth 3)"
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


    # ** 5 FUNCTION: Fetch Integration Artifacts  **

    function Fetch-IntegrationArtifacts {
      param(
        [string]$BaseUrl,
        [string]$PackageId,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenUrl
      )

      Write-Host "📡 Fetching Integration Artifacts for Package ID: $PackageId from $BaseUrl"

      if (-not $BaseUrl -or -not $PackageId) {
        Write-Host "❌ Missing Base URL or Package ID. Cannot proceed."
        return $null
      }

      $TenantType = if ($BaseUrl -eq $global:sourceBaseUrl) { "source" } else { "target" }

      $AccessToken = Get-AccessToken -TokenUrl $TokenUrl -ClientId $ClientId -ClientSecret $ClientSecret -TenantType $TenantType


      if (-not $AccessToken) {
        Write-Host "❌ Failed to obtain access token."
        return $null
      }

      # Step 2: Construct API URL to fetch artifacts
      $ArtifactsUrl = $BaseUrl + "/api/v1/IntegrationPackages('" + $PackageId + "')/IntegrationDesigntimeArtifacts"
      Write-Host "🌍 Calling API: $ArtifactsUrl"

      # Step 3: Set request headers
      $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept = "application/atom+xml"
      }

      try {
        $response = Invoke-WebRequest -Uri $ArtifactsUrl -Headers $headers -Method Get
        Write-Host "🔄 API Response Code: $($response.StatusCode)"


        # ** Debug: Print the Content-Type Header **
        $contentType = $response.Headers['Content-Type']
        Write-Host "📄 Received Content-Type: $contentType"


        if ($contentType -like "application/atom+xml*") {
          Write-Host "📄 Processing Atom XML response..."
          $xmlDoc = [xml]$response.Content
          $entries = $xmlDoc.feed.entry

          $artifactData = @()
          foreach ($entry in $entries) {
            $properties = $entry.properties

            # Debugging: Print all available artifact parameters
            # Write-Host "📜 Artifact Data Received: $($properties.OuterXml)"

            $artifactObject = [pscustomobject]@{
              Id = $properties.Id
              Name = $properties.Name
              Version = $properties.Version
              ModifiedDate = $properties.ModifiedAt
              Status = $properties.Status
              DeployedOn = ""
            }
            $artifactData += $artifactObject
          }
          return $artifactData
        }
        elseif ($contentType -like "application/json*") {
          Write-Host "⚠️ Unexpected JSON Response Detected!"
          Write-Host "📝 Processing JSON response..."
          $jsonResponse = $response.Content | ConvertFrom-Json
          Write-Host "📜 JSON Response: $($jsonResponse | ConvertTo-Json -Depth 3)"
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


    # **  6 FUNCTION: Fetch Integration Artifacts Status and version **

    function Fetch-ArtifactStatus {
      param(
        [string]$BaseUrl,
        [string]$ArtifactId,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenUrl
      )

      Write-Host "📡 Fetching Deployment Status for Artifact ID: $ArtifactId from $BaseUrl"

      if (-not $BaseUrl -or -not $ArtifactId) {
        Write-Host "❌ Missing Base URL or Artifact ID. Cannot proceed."
        return $null
      }

      # Determine the tenant type for reusing access token
      $TenantType = if ($BaseUrl -eq $global:sourceBaseUrl) { "source" } else { "target" }
      $AccessToken = Get-AccessToken -TokenUrl $TokenUrl -ClientId $ClientId -ClientSecret $ClientSecret -TenantType $TenantType

      if (-not $AccessToken) {
        Write-Host "❌ Failed to obtain access token."
        return $null
      }

      # Construct API URL to fetch artifact status
      $ArtifactStatusUrl = "$BaseUrl/api/v1/IntegrationRuntimeArtifacts('$ArtifactId')"
      Write-Host "🌍 Calling API: $ArtifactStatusUrl"

      # Set request headers
      $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept = "application/atom+xml"
      }

      try {
        $response = Invoke-WebRequest -Uri $ArtifactStatusUrl -Headers $headers -Method Get
        Write-Host "🔄 API Response Code: $($response.StatusCode)"

        # ** Debug: Print the Content-Type Header **
        $contentType = $response.Headers['Content-Type']
        Write-Host "📄 Received Content-Type: $contentType"

        if ($contentType -like "application/atom+xml*") {
          Write-Host "📄 Processing Atom XML response..."

          $xmlDoc = [xml]$response.Content
          $entries = $xmlDoc.entry


          foreach ($entry in $entries) {
            $properties = $entry.properties

            # Debugging: Print all available artifact parameters
            #Write-Host "📜 Artifact Status Data Received: $($properties.OuterXml)"

            # Extract Deployment Status & Deployed On
            $status = $properties.Status
            $deployedOn = $properties.DeployedOn
          }
          Write-Host "📝 Status fetched."
          return @{
            Status = $status
            DeployedOn = $deployedOn
          }
          Write-Host "📝 Status variable sent across to main loop."

        }



        elseif ($contentType -like "application/json*") {
          Write-Host "⚠️ Unexpected JSON Response Detected!"
          Write-Host "📝 Processing JSON response..."
          $jsonResponse = $response.Content | ConvertFrom-Json
          Write-Host "📜 JSON Response: $($jsonResponse | ConvertTo-Json -Depth 3)"
          return @{
            Status = $jsonResponse.d.DeploymentStatus
            DeployedOn = $jsonResponse.d.DeployedOn
          }
        }
        else {
          Write-Host "⚠️ Unsupported Content-Type: $contentType"
          return $null
        }
      } catch {
        Write-Host "❌ Error fetching artifact status: $_"
        return $null
      }
    }


    # ** 7 FUNCTION: Fetch Configurable Parameters of an Artifact (with Version)**

    function Fetch-ArtifactConfigurations {
      param(
        [string]$BaseUrl,
        [string]$ArtifactId,
        [string]$Version,
        [string]$ClientId,
        [string]$ClientSecret,
        [string]$TokenUrl,
        [string]$TenantType
      )

      Write-Host "📡 Fetching Configurable Parameters for Artifact ID: $TenantType - $ArtifactId (Version: $Version) from $BaseUrl"

      if (-not $BaseUrl -or -not $ArtifactId -or -not $Version) {
        Write-Host "❌ Missing Base URL, Artifact ID, or Version. Cannot proceed."
        return $null
      }

      # **Determine if it's Source or Target Tenant**
      $TenantType = if ($BaseUrl -eq $global:sourceBaseUrl) { "source" } else { "target" }

      # **Reuse Access Token if available**
      $AccessToken = Get-AccessToken -TokenUrl $TokenUrl -ClientId $ClientId -ClientSecret $ClientSecret -TenantType $TenantType

      if (-not $AccessToken) {
        Write-Host "❌ Failed to obtain access token."
        return $null
      }

      # **Construct API URL (Including Version)**
      $ConfigUrl = "$BaseUrl/api/v1/IntegrationDesigntimeArtifacts(Id='$ArtifactId',Version='$Version')/Configurations"
      Write-Host "🌍 Calling API: $ConfigUrl"

      # **Set Request Headers**
      $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept = "application/atom+xml"
      }

      try {
        # **Call API**
        $response = Invoke-WebRequest -Uri $ConfigUrl -Headers $headers -Method Get
        Write-Host "🔄 API Response Code: $($response.StatusCode)"

        # **Check Content-Type**
        $contentType = $response.Headers['Content-Type']
        Write-Host "📄 Received Content-Type: $contentType"

        if ($contentType -like "application/atom+xml*") {
          Write-Host "📄 Processing Atom XML response..."
          $xmlDoc = [xml]$response.Content
          $entries = $xmlDoc.feed.entry

          # **Extract Configurable Parameters**
          $configData = @()
          foreach ($entry in $entries) {
            $properties = $entry.Content.properties

            # Debugging: Print all available configuration parameters
            #Write-Host "📜 Config Data Received: $($properties.OuterXml)"

            $configObject = [pscustomobject]@{
              Name = $properties.ParameterKey
              Type = $properties.DataType
              Value = $properties.ParameterValue
            }
            $configData += $configObject
          }
          return $configData
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



    # ** 8 FUNCTION: Export AND EXTRACT Artifacts with Unique Naming **

    function Export-Artifact {
      param(
        [string]$BaseUrl,
        [string]$ArtifactId,
        [string]$Token,
        [string]$Version,
        [string]$TenantType # "source" or "target" to differentiate artifacts
      )

      # ** Ensure Unique Naming **
      $UniqueArtifactId = "$TenantType`_$ArtifactId"
      # Generate a Shorter Unique Name (Using First 8 Characters of Hash)
$ShortArtifactId = "$TenantType"+"_"+([System.Guid]::NewGuid().ToString().Substring(0,8))

# Define Paths with Shorter Names
$ArtifactFile = "$global:ZipPath\$ShortArtifactId.zip"
$ExtractPath = "$global:ExtractPath\$ShortArtifactId"


      Write-Host "📝 ExtractPath: $ExtractPath"
      # ** Construct URL Properly (Escaping $value) **
      $Url = "$BaseUrl/api/v1/IntegrationDesigntimeArtifacts(Id='$ArtifactId',Version='$Version')/`$value"

      Write-Host "📥 Downloading Artifact ZIP from: $Url"
      Write-Host "📝 Saving As: $ArtifactFile"

      $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type" = "application/zip"
      }

      try {
       

        # ** Download the ZIP File **
        $response = Invoke-WebRequest -Uri $Url -Headers $Headers -Method Get -OutFile $ArtifactFile


        Write-Host "✅ Successfully downloaded artifact ZIP: $ArtifactFile"

        # ** Extract ZIP File Immediately **
        if (-not (Test-Path $ExtractPath)) {
          New-Item -ItemType Directory -Path $ExtractPath | Out-Null
        } else {
          Write-Host "🔄 Removing existing extracted folder: $ExtractPath"
          Remove-Item -Recurse -Force $ExtractPath
        }

        Expand-Archive -Path $ArtifactFile -DestinationPath $ExtractPath -Force
        Write-Host "✅ ZIP Extracted to: $ExtractPath"

        # ** Store Path in Global Variable for Future Use **
        if ($TenantType -eq "source") {
          $global:sourceExtractPath = $ExtractPath
          Write-Host "New Path= $global:sourceExtractPath"
        } else {
          $global:targetExtractPath = $ExtractPath
           Write-Host "New Path= $global:targetExtractPath"
        }
        Write-Host "Export Check"
        return $ArtifactFile
      }
      catch {
        Write-Host "❌ Error exporting artifact $ArtifactId"
        Write-Host "🔴 Error Message: $($_.Exception.Message)"
        return $null
      }
    }


    # ** 9 FUNCTION: Extract Manifest from Source and Target Iflows

    function Extract-Manifest {
    param (
        [string]$ExtractedPath # Directly passing extracted path
    )

    Write-Host "📂 Extracting Manifest from: $ExtractedPath"

    # ** Ensure the Extracted Path Exists Before Proceeding **
    if (-not (Test-Path $ExtractedPath)) {
        Write-Host "❌ Extracted Path Not Found: $ExtractedPath"
        return $null
    }

    # ** Locate the Manifest.mf file inside the extracted folder **
    $manifestPath = Get-ChildItem -Path $ExtractedPath -Recurse -Filter "MANIFEST.MF" | Select-Object -ExpandProperty FullName

    if (-not $manifestPath) {
        Write-Host "❌ Manifest file not found inside extracted folder."
        return $null
    }

    Write-Host "📜 Manifest File Found at: $manifestPath"    


    # ** Return Extracted Data as Object **
    $manifestData =  $manifestPath
    

    Write-Host "✅ Extracted Manifest Details: $($manifestData | ConvertTo-Json -Depth 2)"
    return $manifestData
}

# ** 10.1 Function to Read Manifest File (Preserving Multi-Line Formatting)
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

# ** 10.2 Function to Extract Multi-Line Values Without Modifying Format
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

# ** 10.3  Function to Replace Multi-Line Values While Keeping Original Formatting
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

# ** 10.4 Function to remove BOM and preserve line breaks
function Remove-BOM {
    param ([string]$filePath)

    # Read the file as bytes to check for BOM
    $bytes = [System.IO.File]::ReadAllBytes($filePath)

    # Check for UTF-8 BOM (EF BB BF) and remove it if present
    if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $bytes = $bytes[3..($bytes.Length - 1)]  # Remove the first 3 BOM bytes
        [System.IO.File]::WriteAllBytes($filePath, $bytes)
        Write-Host "✅ BOM removed from the Manifest file."
    } else {
        Write-Host "✅ No BOM detected, file is already correct."
    }
}

# ** 10.5 Function to Process Manifest Replacement (Everything in One Function)
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

    # Replace Values in the Source Manifest
    $ModifiedContent = Replace-ManifestValues -sourceContent $sourceContent -targetValues $TargetValues -keys $keys

    # Save the Modified Manifest File
    $ModifiedContent | Set-Content -Path $outputFile -Encoding UTF8
    Write-Host "✅ Manifest file has been successfully modified and saved as $outputFile"

# Call function to clean up BOM
Remove-BOM -filePath $outputFile

    # Debug: Verify Final Values After Replacement
    $NewContent = Read-ManifestFile -filePath $outputFile
    $NewValues = Extract-ManifestValues -content $NewContent -keys $keys

    Write-Host "`n📝 New Manifest Values After Replacement:"
    Write-Host "----------------------------------------------------"
    foreach ($key in $NewValues.Keys) { Write-Host "🔹 $key = '$($NewValues[$key])'" }
    Write-Host "----------------------------------------------------`n"
}

# ** 10.6 Preserve Folder Structure While Creating ZIP
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

# ** 10.7Function to Convert ZIP to Base64
function Convert-ZipToBase64 {
    param ([string]$ZipPath)

    Write-Host "🔄 Converting ZIP to Base64..."
    $bytes = [System.IO.File]::ReadAllBytes($ZipPath)
    $base64String = [Convert]::ToBase64String($bytes)
    
    # Save Base64 to file for easy copy-paste
    $base64FilePath = "$ZipPath.base64.txt"
    $base64String | Set-Content -Path $base64FilePath -Encoding UTF8

    Write-Host "✅ Base64 Conversion Completed! Output saved to: $base64FilePath"
    return $base64String
}



    

    # ** 10 FUNCTION: Modify Source Manifest & Create ZIP for Upload **
    function Modify-ManifestFile {
    param (
        [string]$SourceExtractPath,
        [string]$TargetExtractPath
    
    )

    Write-Host "🚀 Starting Manifest Modification Process..."

    # ** Ensure Extracted Paths Exist **
    $SourceManifestPath = $SourceExtractPath+"\META-INF\MANIFEST.MF"
    $TargetManifestPath = $TargetExtractPath+"\META-INF\MANIFEST.MF"
    $ExtractedSourcePath = $SourceExtractPath
    $ShortArtifactId = "mod_" + ([System.Guid]::NewGuid().ToString().Substring(0, 8))
    $OutputZipPath = "$global:ZipPath\$ShortArtifactId.zip"


    if (-not (Test-Path $SourceManifestPath)) {
        Write-Host "❌ Source Manifest file not found: $SourceManifestPath"
        return @{ status = "error"; message = "Source Manifest Not Found." } | ConvertTo-Json -Depth 2
    }
    if (-not (Test-Path $TargetManifestPath)) {
        Write-Host "❌ Target Manifest file not found: $TargetManifestPath"
        return @{ status = "error"; message = "Target Manifest Not Found." } | ConvertTo-Json -Depth 2
    }

    # ** Fetch Manifest Values (Before Modification) **
    function Fetch-ManifestValues {
        param ([string]$ManifestFilePath)

        if (-not (Test-Path $ManifestFilePath)) {
            Write-Host "❌ Manifest file not found: $ManifestFilePath"
            return $null
        }

        # ** Read Manifest File Content (Handling Multi-Line Values) **
        $manifestLines = Get-Content -Path $ManifestFilePath
        $manifestContent = ""
        foreach ($line in $manifestLines) {
            if ($line -match "^\s") { $manifestContent += $line.TrimStart() }
            else { $manifestContent += "`n" + $line }
        }

        # ** Extract Values Using Regex **
        function Extract-ManifestValue {
            param ([string]$content, [string]$key)
            $pattern = "(?ms)^${key}:\s*(.+?)(?=\n\S|$)"
            $match = [regex]::Match($content, $pattern)
            if ($match.Success) { return $match.Groups[1].Value.Trim() -replace "\s{2,}", " " }
            return ""
        }

        return @{
            "Bundle-SymbolicName"        = Extract-ManifestValue -content $manifestContent -key "Bundle-SymbolicName"
            "Origin-Bundle-SymbolicName" = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-SymbolicName"
            "Origin-Bundle-Name"         = Extract-ManifestValue -content $manifestContent -key "Origin-Bundle-Name"
            "Bundle-Name"                = Extract-ManifestValue -content $manifestContent -key "Bundle-Name"
        }
    }

    Write-Host "🔍 Fetching BEFORE Modification Values (Source)..."
    $beforeValues = Fetch-ManifestValues -ManifestFilePath $SourceManifestPath
    Write-Host "📄 BEFORE Modification: $($beforeValues | ConvertTo-Json -Depth 2)"

    Write-Host "🔍 Fetching Target Values for Modification..."
    $targetValues = Fetch-ManifestValues -ManifestFilePath $TargetManifestPath
    Write-Host "📄 Target Values to Apply: $($targetValues | ConvertTo-Json -Depth 2)"

    # ** Function to Modify Manifest Content **
    function Replace-ManifestValue {
        param ([string]$content, [string]$key, [string]$newValue)
        $pattern = "(?ms)^(${key}:\s*)(.+?)(?=\n\S|$)"
        if ($content -match $pattern) { return $content -replace $pattern, "`$1$newValue" }
        return $content
    }

    # ** Modify Manifest File **
    $sourceLines = Get-Content -Path $SourceManifestPath
    $sourceContent = ""
    foreach ($line in $sourceLines) {
        if ($line -match "^\s") { $sourceContent += $line.TrimStart() }
        else { $sourceContent += "`n" + $line }
    }

    $modifiedSourceContent = $sourceContent
    foreach ($key in $targetValues.Keys) {
        $modifiedSourceContent = Replace-ManifestValue -content $modifiedSourceContent -key $key -newValue $targetValues[$key]
    }

    $modifiedSourceContent -split "`n" | Set-Content -Path $SourceManifestPath -Encoding UTF8
    Write-Host "✅ Successfully Modified Source Manifest File"

    Write-Host "🔍 Fetching AFTER Modification Values (Source)..."
    $afterValues = Fetch-ManifestValues -ManifestFilePath $SourceManifestPath
    Write-Host "📄 AFTER Modification: $($afterValues | ConvertTo-Json -Depth 2)"

    # ** Archive the Updated Source Folder into a ZIP File **
    Write-Host "📦 Creating ZIP Archive for Upload..."
    if (Test-Path $OutputZipPath) { Remove-Item -Path $OutputZipPath -Force }
    Compress-Archive -Path "$ExtractedSourcePath\*" -DestinationPath $OutputZipPath -Force

    Write-Host "✅ ZIP Created for Upload: $OutputZipPath"

    $global:modifiedZipPath = $OutputZipPath
    Write-Host "✅ FilePath: $global:modifiedZipPath"

    return @{
    Status = "success"
    ModifiedZipPath = $OutputZipPath
}
}



    # ** 11 FUNCTION: Upload artifact

    function Upload-Artifact {
    param (
        [string]$ArtifactFile,
        [string]$Version,
        [string]$ArtifactId,        
        [string]$Token,
        [string]$ArtifactName
            
        
    )

    # ** Construct API URL **
    $Url = "$global:targetBaseUrl/api/v1/IntegrationDesigntimeArtifacts"+"(Id='$ArtifactId',Version='$Version')"

   Write-Host "📤 Uploading artifact file: $ArtifactFile to package ID: $PackageId"

   #Write-Host "accessToken: $Token"
   write-Host " Uploading:$ArtifactName"

    # ** Set Headers **
    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = "application/json"
    }

    
        # ** Read & Encode ZIP File Content **
        $FileBytes = [System.IO.File]::ReadAllBytes($ArtifactFile)
        $EncodedFileContent = [Convert]::ToBase64String($FileBytes)
        # Save Base64 to file for easy copy-paste
    $base64FilePath = "$ArtifactFile.base64.txt"
    $base64String | Set-Content -Path $base64FilePath -Encoding UTF8        

        # ** Construct API Request Body **
        $Body = @{
            "Name"            = $ArtifactName
            "ArtifactContent" = $EncodedFileContent
        } | ConvertTo-Json -Depth 3

        # ** Send Import Request **
        # ** Logging Request Details **
Write-Host "🔄 Preparing to Upload Artifact: $ArtifactName"
Write-Host $Body
Write-Host "🚀 Sending Upload Request to: $Url"
try {
    $response = Invoke-RestMethod -Uri $Url -Headers $Headers -Method PUT -Body $Body -ContentType "application/json"

    $responseCode=$response.StatusCode
    Write-Host "ResponseCode: $responseCode"
    # ** Log Full Response Data **
    Write-Host "✅ Upload Successful! Server Response:"
    Write-Host "----------------------------------------------------"
    Write-Host ($responseCode | ConvertTo-Json -Depth 10)
    Write-Host "----------------------------------------------------"

    return @{
        Status  = "success"
        Message = "Artifact uploaded successfully!"
        Response = $response
    }
}
    catch {
    # ** Log Detailed Error Information **
    Write-Host "❌ Upload Failed for Artifact: $ArtifactName"
    Write-Host "🔴 Error Message: $($_.Exception.Message)"
    
    # Capture response details if available
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $errorResponse = $reader.ReadToEnd()

        Write-Host "🔴 Full Error Response from Server:"
        Write-Host "----------------------------------------------------"
        Write-Host $errorResponse
        Write-Host "----------------------------------------------------"

        return @{
            Status  = "error"
            Message = "Upload failed. Check logs."
            Error   = $_.Exception.Message
            Response = $errorResponse
        }
    } else {
        return @{
            Status  = "error"
            Message = "Upload failed. No response from server."
            Error   = $_.Exception.Message
        }
    }
}
}




    # ** 12 FUNCTION: Deploy Artifcat on target
    # ===========================================
    # ** Neo SAP CPI **
    function Deploy-Artifact {
    param (
        [string]$BaseUrl,
        [string]$ArtifactId,
        [string]$Token,
        [string]$Version
    )

    Write-Host "🚀 Starting Deployment for Artifact: $ArtifactId (Version: $Version)"

    # ** Construct Deployment URL **
    $deployUrl = "$BaseUrl/api/v1/IntegrationDesigntimeArtifacts(Id='$ArtifactId',Version='$Version')/Deploy"

    Write-Host "🔄 Deploying via URL: $deployUrl"

    # ** Set Request Headers **
    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Accept"        = "application/json"
    }

    try {
        # ** Send Deployment Request **
        $response = Invoke-RestMethod -Uri $deployUrl -Headers $Headers -Method POST
        Write-Host "✅ Deployment Successful for $ArtifactId"

        return @{
            status  = "success"
            message = "Deployment Successful!"
        }
    }
    catch {
        Write-Host "❌ Deployment Failed for $ArtifactId"
        Write-Host "🔴 Error Message: $($_.Exception.Message)"

        return @{
            status  = "error"
            message = "Deployment Failed. Check Logs."
        }
    }
}

    # ** Cloud Foundry SAP CPI **
function Deploy-Artifact-CF {
    param (
        [string]$BaseUrl,
        [string]$ArtifactId,
        [string]$Token,
        [string]$Version
    )

    Write-Host "🚀 Starting Deployment for Cloud Foundry Artifact: $ArtifactId (Version: $Version)"

    # ** Construct Deployment URL **
    $deployUrl = "$BaseUrl/api/v1/DeployIntegrationDesigntimeArtifact?"+"Id='$ArtifactId'&Version='$Version'"
    #"$global:targetBaseUrl/api/v1/IntegrationDesigntimeArtifacts"+"(Id='$ArtifactId',Version='$Version')"

    Write-Host "🔄 Deploying via URL: $deployUrl"

    # ** Set Request Headers **
    $Headers = @{
        "Authorization" = "Bearer $Token"
        "Accept"        = "application/json"
        "Content-Type"  = "application/json"
    }


    try {
        # ** Send Deployment Request **
        $response = Invoke-RestMethod -Uri $deployUrl -Headers $Headers -Method POST -ContentType "application/json"
        Write-Host "✅ Deployment Successful for $ArtifactId"

        return @{
            status  = "success"
            message = "Deployment Successful!"
            response = $response
        }
    }
    catch {
        Write-Host "❌ Deployment Failed for $ArtifactId"
        Write-Host "🔴 Error Message: $($_.Exception.Message)"

        return @{
            status  = "error"
            message = "Deployment Failed. Check Logs."
            error   = $_.Exception.Message
        }
    }
}


# ** 13 FUNCTION: Send Update
    # ===========================================
function Send-Update {
    if (-not $global:DeploymentStatus) { return }

    # ✅ Convert Deployment Status to JSON
    $jsonResponse = $global:DeploymentStatus | ConvertTo-Json -Depth 10

    # ✅ Write to deployment.json File (Async)
    try {
        $jsonResponse | Set-Content -Path "$PSScriptRoot\deployment.json" -Encoding UTF8 -Force
        Write-Host "📡 Deployment Status Updated: $PSScriptRoot\deployment.json"
    } catch {
        Write-Host "❌ Failed to Write Deployment Status: $_"
    }
}










    # ===========================================
    # MAIN SCRIPT EXECUTION
    ##############################################               

    while ($listener.IsListening) {
      try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $urlPath = $request.Url.AbsolutePath

        if ($urlPath -eq "/stop") {
          Write-Host "🛑 STOP request received! Shutting down listener..."

          # Send response to confirm shutdown
          $response.StatusCode = 200
          $response.ContentType = "application/json"
          $stopMessage = @{ Message = "Server shutting down..." } | ConvertTo-Json
          $buffer = [System.Text.Encoding]::UTF8.GetBytes($stopMessage)
          $response.ContentLength64 = $buffer.Length
          $response.OutputStream.Write($buffer,0,$buffer.Length)
          $response.Close()

          # Stop the listener
          $listener.Stop()
          $listener.Close()
          Remove-Variable listener -ErrorAction SilentlyContinue

          exit
        }

        Write-Host "📩 Incoming API Request: $urlPath"
        Write-Host "🔄 Request Method: $($request.HttpMethod)"
        # ✅ Serve deployment.json when requested
if ($urlPath -eq "/deployment.json") {
    $deploymentFilePath = "$PSScriptRoot\deployment.json"

    if (Test-Path $deploymentFilePath) {
        Write-Host "📡 Serving Deployment Status File: $deploymentFilePath"

        $response.StatusCode = 200
        $response.ContentType = "application/json"
        $buffer = [System.IO.File]::ReadAllBytes($deploymentFilePath)
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } else {
        Write-Host "❌ deployment.json Not Found!"
        $response.StatusCode = 404
        $jsonResponse = @{ status = "error"; message = "deployment.json not found" } | ConvertTo-Json
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $response.Close()
    continue
}

        # ✅ Handle SSE for Deployment Status Streaming
if ($urlPath -eq "/deploymentStatusStream") {
    Write-Host "📡 Opening Deployment Status Stream..."


 
    
    # ✅ Set Up SSE Headers
    $response.StatusCode = 200
    $response.ContentType = "text/event-stream"
    $response.Headers.Add("Cache-Control", "no-cache")
    $response.Headers.Add("Connection", "keep-alive")
    
    try {
        while ($true) {
            # ✅ Send the Latest Deployment Status
            Send-Update

            # ✅ Delay before the next update (2 seconds)
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-Host "❌ SSE Stream Error: $_"
    } finally {
        # ✅ Close the Response When Done
        $response.OutputStream.Close()
        Write-Host "🚪 SSE Stream Closed."
    }
    }

        # ** 5.1️⃣ Serve HTML UI if requested **
        if ($request.HttpMethod -eq "GET") {
    Serve-StaticFile -RequestedPath $urlPath -Context $context
    continue
}

        # ** 5.2️⃣ Ensure this is a Valid API Request (Allowing POST & PUT for Import) **
        if ($request.HttpMethod -ne "POST" -and $request.HttpMethod -ne "PUT") {
          Write-Host "⚠️ Invalid request method: $($request.HttpMethod)"
          $response.StatusCode = 405 # Method Not Allowed
          $response.Close()
          continue
        }

        Write-Host "✅ Accepted HTTP Method: $($request.HttpMethod)"

        # ✅ Add Reset Transport API Handling
if ($urlPath -eq "/resetTransport") {
    Write-Host "🔄 Received Reset Transport Request!"

    # ✅ Reset API Credentials and Tokens
    $global:sourceBaseUrl = $null
    $global:sourceClientId = $null
    $global:sourceClientSecret = $null
    $global:sourceTokenUrl = $null
    $global:sourceAccessToken = $null

    $global:targetBaseUrl = $null
    $global:targetClientId = $null
    $global:targetClientSecret = $null
    $global:targetTokenUrl = $null
    $global:targetAccessToken = $null

    # ✅ Reset Cached Data
    $global:cachedPackages = @{}
    $global:cachedArtifacts = @{}
    $global:cachedArtifactStatus = @{}
    $global:cachedManifests = @{}
    $global:cachedConfigurations = @{}
    
    # ✅ Reset Paths and Artifact Variables
    $global:targetZipFilePath = $null
    $global:sourceZipFilePath = $null
    $global:targetExtractPath = $null
    $global:sourceExtractPath = $null
    $global:modifiedZipPath = $null
    $global:modifiedArtifactId = $null
    $global:modifiedArtifactVersion = $null
    $global:targetArtifactName = $null
    $global:targetPackageID = $null
    $globaltargetArtifactId = $null
    $globalSourceArtifactVersion = $null
    $global:CPITenantTYpe=$null

    Write-Host "✅ Transport Data Cleared Successfully!"

    # ✅ Send Response to Frontend
    $response.StatusCode = 200
    $response.ContentType = "application/json"
    $jsonResponse = @{ status = "success"; message = "Transport Reset Successfully!" } | ConvertTo-Json
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.Close()
    continue
}




# ✅ New API for Deployment Status
if ($urlPath -eq "/deploymentStatus") {
    Write-Host "📡 Sending Deployment Status Updates..."
    $jsonResponse = $global:DeploymentStatus | ConvertTo-Json
}

# ✅ New API for Downloading Configuration Backup
elseif ($urlPath -eq "/downloadConfigs") {
    Write-Host "📡 Downloading Original Configurations..."

    $configFilePath = "$PSScriptRoot\Original_Configurations.txt"
    if (Test-Path $configFilePath) {
        $response.ContentType = "application/octet-stream"
        $response.AddHeader("Content-Disposition", "attachment; filename=Original_Configurations.txt")
        $buffer = [System.IO.File]::ReadAllBytes($configFilePath)
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    } else {
        Write-Host "❌ Configuration File Not Found!"
        $jsonResponse = @{ status = "error"; message = "Configuration file not found." } | ConvertTo-Json
    }
}
# ✅ New API for Aborting Deployment
elseif ($urlPath -eq "/abortDeployment") {
    Write-Host "🛑 Aborting Deployment Process..."
    $global:DeploymentStatus = @{ status = "❌ Deployment Aborted"; progress = 100 }
    $jsonResponse = @{ status = "aborted"; message = "Deployment aborted by user." } | ConvertTo-Json
}





        # ** 5.3️⃣ Read JSON Request Body from UI **
        $reader = New-Object System.IO.StreamReader ($request.InputStream)
        $bodyText = $reader.ReadToEnd()

        # Write-Host "📜 Raw JSON Received: $bodyText"

        # ** 5.4️⃣ Parse JSON Request Safely **
        try {
          $body = $bodyText | ConvertFrom-Json
          Write-Host "✅ Parsed JSON Body received from HTML Successfully"
        }
        catch {
          Write-Host "❌ JSON Parsing Error: $_"
          $response.StatusCode = 400 # Bad Request
          $response.Close()
          continue
        }

        # ** 5.5️ Store API Credentials (Only for First Request) **
        if ($body.sourceBaseUrl -and $body.targetBaseUrl -and $body.sourceClientId -and $body.targetClientId) {
          Write-Host "📝 Storing API Credentials for Reuse..."

          $global:sourceBaseUrl = $body.sourceBaseUrl
          $global:sourceClientId = $body.sourceClientId
          $global:sourceClientSecret = $body.sourceClientSecret
          $global:sourceTokenUrl = $body.sourceTokenUrl

          $global:targetBaseUrl = $body.targetBaseUrl
          $global:targetClientId = $body.targetClientId
          $global:targetClientSecret = $body.targetClientSecret
          $global:targetTokenUrl = $body.targetTokenUrl
          $global:CPITenantTYpe = $body.selectedTenantType

           Write-Host "✅ TenantType: $global:CPITenantTYpe"

          Write-Host "✅ API Credentials Stored Successfully!"
        }


        # ** 5.5.1 Fetch Artifact ZIPs for Transport (Source & Target) **
        if ($body.fetchArtifactZip -eq $true) {
          Write-Host "📦 Fetching ZIP files for artifacts: Source ($body.sourceArtifactId) & Target ($body.targetArtifactId)"

          # ** Fetch Source Artifact ZIP **
          $sourceZipFilePath = Export-Artifact -BaseUrl $global:sourceBaseUrl -ArtifactId $body.sourceArtifactId -Token $global:sourceAccessToken -Version $body.sourceArtifactVersion -TenantType "source"

          # ** Fetch Target Artifact ZIP **
          $targetZipFilePath = Export-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $body.targetArtifactId -Token $global:targetAccessToken -Version $body.targetArtifactVersion -TenantType "target"

         $globaltargetArtifactId=$body.targetArtifactId
         $globalSourceArtifactVersion=$body.targetArtifactVersion
         $global:targetArtifactName=$body.targetArtifactName
         
          # ** Validate if ZIPs are downloaded successfully **
          if ($sourceZipFilePath -and $targetZipFilePath) {
            Write-Host "✅ Artifact ZIPs successfully downloaded: Source: $sourceZipFilePath, Target: $targetZipFilePath"

            $jsonResponse = @{
              Status = "success"
              Message = "Artifact ZIPs downloaded successfully!"
              sourceZipFile = $global:sourceExtractPath
              targetZipFile = $global:targetExtractPath
              sourceArtifact = @{
                Id = $body.sourceArtifactId
                Version = $body.sourceArtifactVersion
                Tenant = "source"
              }
              targetArtifact = @{
                Id = $body.targetArtifactId
                Version = $body.targetArtifactVersion
                Tenant = "target"
              }
            } | ConvertTo-Json -Depth 3
          } else {
            Write-Host "❌ Failed to download one or both artifact ZIPs."
            $jsonResponse = @{
              Status = "error"
              Message = "Failed to download one or both artifact ZIPs."
            } | ConvertTo-Json -Depth 3
          }
        }


        # ** 5.6️    Determine API Request Type **

        # ** 5.6.2  Fetch Artifacts **
        if ($body.sourcePackageId -and $body.targetPackageId) {
          # ** STEP 3: Fetch Integration Artifacts (With Caching) **
          Write-Host "📡 Fetching Integration Artifacts for Selected Packages..."


          # ** Unique Identifiers for Source & Target Packages **
          $sourcePackageKey = "source_$body.sourcePackageId"
          $targetPackageKey = "target_$body.targetPackageId"
          $global:targetPackageID=$body.targetPackageId

          # ** Caching for Source Package Artifacts **
          if (-not $global:cachedArtifacts.ContainsKey($sourcePackageKey)) {
            Write-Host "📡 Fetching New Artifacts for Source Package..."
            $sourceArtifacts = Fetch-IntegrationArtifacts -BaseUrl $global:sourceBaseUrl -PackageId $body.sourcePackageId -ClientId $global:sourceClientId -ClientSecret $global:sourceClientSecret -TokenUrl $global:sourceTokenUrl
            $global:cachedArtifacts[$sourcePackageKey] = $sourceArtifacts
          } else {
            Write-Host "📡 Using Cached Artifacts for Source Package..."
            $sourceArtifacts = $global:cachedArtifacts[$sourcePackageKey]
          }

          # ** Caching for Target Package Artifacts **
          if (-not $global:cachedArtifacts.ContainsKey($targetPackageKey)) {
            Write-Host "📡 Fetching New Artifacts for Target Package..."
            $targetArtifacts = Fetch-IntegrationArtifacts -BaseUrl $global:targetBaseUrl -PackageId $body.targetPackageId -ClientId $global:targetClientId -ClientSecret $global:targetClientSecret -TokenUrl $global:targetTokenUrl
            $global:cachedArtifacts[$targetPackageKey] = $targetArtifacts
          } else {
            Write-Host "📡 Using Cached Artifacts for Target Package..."
            $targetArtifacts = $global:cachedArtifacts[$targetPackageKey]
          }




          # ** Fetch Deployment Status & Deployed On for Each Artifact (Source) **
          foreach ($artifact in $sourceArtifacts) {
            $artifactID = $artifact.Id
            $artifactKey = "source_" + "$artifactID"
            Write-Host " Artifact key: $artifactKey"
            $index += 1


            
              Write-Host "📡 Fetching New Status for Source Artifact: $($artifact.Id)"
              Write-Host " Artifact S no: $index"
              $statusData = Fetch-ArtifactStatus -BaseUrl $global:sourceBaseUrl -ArtifactId $artifact.Id -ClientId $global:sourceClientId -ClientSecret $global:sourceClientSecret -TokenUrl $global:sourceTokenUrl
              Write-Host "📝 Status processing in main loop."
              if ($statusData) {
                $artifact.Status = $statusData.Status
                $artifact.DeployedOn = $statusData.DeployedOn
                Write-Host "📝 Status : ($statusData.Status)."

                Write-Host "Added to cache Global variable."
              }
            
          }



          # ** Fetch Deployment Status & Deployed On for Each Artifact (Target) **

          foreach ($artifact in $targetArtifacts) {
            $artifactID = $artifact.Id
            $artifactKey = "target_" + "$artifactID"

            
              Write-Host "📡 Fetching New Status for Source Artifact: $($artifact.Id)"
              $statusData = Fetch-ArtifactStatus -BaseUrl $global:targetBaseUrl -ArtifactId $artifact.Id -ClientId $global:targetClientId -ClientSecret $global:targetClientSecret -TokenUrl $global:targetTokenUrl

              if ($statusData) {
                $artifact.Status = $statusData.Status
                $artifact.DeployedOn = $statusData.DeployedOn
                $global:cachedArtifactStatus[$artifactKey] = @{
                  Status = $statusData.Status
                  DeployedOn = $statusData.DeployedOn
                }
              }
           
          }





          # ** Ensure Response is in JSON Format **
          $response.ContentType = "application/json"
          if (-not $sourceArtifacts) { $sourceArtifacts = @() }
          if (-not $targetArtifacts) { $targetArtifacts = @() }

          $jsonResponse = @{
            sourceArtifacts = $sourceArtifacts
            targetArtifacts = $targetArtifacts
          } | ConvertTo-Json -Depth 3

          Write-Host "✅ Successfully sent integration artifacts to frontend."

        }

        # ** 5.6.3  Fetch Manifest & Configurations for Selected Artifacts **
        elseif ($body.sourceArtifactId -and $body.targetArtifactId) {


          Write-Host "📡 Fetching Manifest & Configurations for Selected Artifacts..."

          # ** Unique Identifiers for Source & Target Artifacts **

          $sourceartifactID = $body.sourceArtifactId
          $targetArtifactId = $body.targetArtifactId
          
          $sourceArtifactKey = "source_$sourceartifactID"
          $targetArtifactKey = "target_$targetArtifactId"

          # ** Fetch & Cache Manifest Data for Source Artifact **
          
            Write-Host "📜 Fetching Manifest for Source Artifact: $sourceArtifactId"
           
             $sourceManifestPath = Extract-Manifest -ExtractedPath $global:sourceExtractPath
             $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")
            # Read Source Manifest File
            $sourceContent = Read-ManifestFile -filePath $sourceManifestPath

            # Extract Values from Target Manifest
            $sourceManifestvalues = Extract-ManifestValues -content $sourceContent -keys $keys
            $sourceManifest = $sourceManifestvalues
            $global:cachedManifests[$sourceArtifactKey] = $sourceManifest
            Write-Host "Path= $global:sourceExtractPath"

          

          # ** Fetch & Cache Manifest Data for Target Artifact **
          
            Write-Host "📜 Fetching Manifest for Target Artifact: $targetArtifactId"
            $targetManifestPath = Extract-Manifest -ExtractedPath $global:targetExtractPath
            $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")
            # Read Source Manifest File
            $targetContent = Read-ManifestFile -filePath $sourceManifestPath

            # Extract Values from Target Manifest
            $targetManifestvalues = Extract-ManifestValues -content $targetContent -keys $keys
            $targetManifest = $targetManifestvalues 
            $global:cachedManifests[$targetArtifactKey] = $targetManifest


          # ** Fetch & Cache Configurations for Source Artifact **
          
            Write-Host "⚙️ Fetching Configurations for Source Artifact: $($sourceArtifactId)"
            $sourceConfigurations = Fetch-ArtifactConfigurations -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Version $body.sourceArtifactVersion -ClientId $global:sourceClientId -ClientSecret $global:sourceClientSecret -TokenUrl $global:sourceTokenUrl -TenantType "source"
            $global:cachedConfigurations[$sourceArtifactKey] = $sourceConfigurations
          

          # ** Fetch & Cache Configurations for Target Artifact **
          
            Write-Host "⚙️ Fetching Configurations for Target Artifact: $($targetArtifactId)"
            $targetConfigurations = Fetch-ArtifactConfigurations -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Version $body.targetArtifactVersion -ClientId $global:targetClientId -ClientSecret $global:targetClientSecret -TokenUrl $global:targetTokenUrl -TenantType "target"
            $global:cachedConfigurations[$targetArtifactKey] = $targetConfigurations
          
          # ** Ensure Response is in JSON Format **
          $response.ContentType = "application/json"
          if (-not $sourceManifest) { $sourceManifest = @() }
          if (-not $targetManifest) { $targetManifest = @() }
          if (-not $sourceConfigurations) { $sourceConfigurations = @() }
          if (-not $targetConfigurations) { $targetConfigurations = @() }
          $jsonResponse = @{
            Status = "success"
            sourceManifest = $sourceManifest
            targetManifest = $targetManifest
            sourceConfigurations = $sourceConfigurations
            targetConfigurations = $targetConfigurations
          } | ConvertTo-Json -Depth 3

          Write-Host "✅ Successfully sent Manifest & Configurations to frontend."
        }
        

        # ** 5.6.4 Modify Source Manifest File for Transport **
        elseif ($body.modifyManifestFile -eq $true) {
            Write-Host "📝 Modifying Source Manifest File for Transport..."

            # Ensure that extracted paths exist
            if (-not (Test-Path $global:sourceExtractPath) -or -not (Test-Path $global:targetExtractPath)) {
                Write-Host "❌ One or both extracted artifact paths are missing!"
                $jsonResponse = @{
                    Status = "error"
                    Message = "Source or Target extracted folder not found. Please re-extract the ZIPs."
                } | ConvertTo-Json -Depth 3
            } else {
                # Call the Modify-ManifestFile function
                # ** Ensure Extracted Paths Exist **
                $SourceManifestPath = $global:sourceExtractPath+"\META-INF\MANIFEST.MF"
                $TargetManifestPath = $global:targetExtractPath+"\META-INF\MANIFEST.MF"
                $modificationResponse = Process-ManifestReplacement -SourceFile $SourceManifestPath -TargetFile $TargetManifestPath -outputFile $SourceManifestPath


                # Step 2: Create ZIP Archive
                $ShortArtifactId = "mod_" + ([System.Guid]::NewGuid().ToString().Substring(0, 8))
    $OutputZipPath = "$global:ZipPath\$ShortArtifactId.zip"
                Create-Zip -ExtractedPath $SourceExtractPath -ZipPath $OutputZipPath
                $global:modifiedZipPath = $OutputZipPath
                
                 $modificationResponse=@{
    Status = "success"
    ModifiedZipPath = $OutputZipPath}

                
                Write-Host "Response : $modificationResponse"
                # ** Extract the 'status' field correctly **
                $modificationStatus = $modificationResponse["status"]  # ✅ Retrieve "status" key correctly
                $modifiedZipPath = $modificationResponse["modifiedZipPath"]  # ✅ Retrieve "modifiedZipPath" key

Write-Host "Status : $modificationStatus"
                if ($modificationStatus -eq "success") {
                    Write-Host "✅ Manifest file successfully modified for transport!"

                    $jsonResponse = @{
                        Status = "success"
                        Message = "Manifest file updated successfully. Ready for transport!"
                    } | ConvertTo-Json -Depth 3
                } else {
                    Write-Host "❌ Failed to modify the manifest file."

                    $jsonResponse = @{
                        Status = "error"
                        Message = "Failed to update the manifest file."
                    } | ConvertTo-Json -Depth 3
                }
            }
        }


         # ** 5.6.5 Upload Modified Artifact to Target Tenant **
         elseif ($body.uploadArtifact -eq $true) {
    Write-Host "📡 Uploading Modified Artifact to Target Tenant..."


    [string]$ArtifactFile,
        [string]$CurrentArtifactName,
        [string]$ArtifactId,
        [string]$PackageId,
        [string]$Token  
    # Use global variables instead of expecting them from request
    $uploadresult = Upload-Artifact -ArtifactFile $global:modifiedZipPath `
                                    -ArtifactId $globaltargetArtifactId `                                     `
                                    -Token $global:targetAccessToken `
                                    -ArtifactName $global:targetArtifactName `
                                    -Version $globalSourceArtifactVersion
                                     
                                    

$uploadStatus=$uploadresult["Status"]
    if ($uploadStatus -eq "success") {
        Write-Host "✅ Upload Successful!"
        $jsonResponse = @{
            Status = "success"
            Message = "Artifact uploaded successfully!"
            targetArtifactId = $globaltargetArtifactId
            targetArtifactVersion = $globalSourceArtifactVersion
        } | ConvertTo-Json -Depth 3
    } else {
        Write-Host "❌ Upload Failed!"
        $jsonResponse = @{
            Status = "error"
            Message = "Artifact upload failed."
        } | ConvertTo-Json -Depth 3
    }
}


        # ** 5.6.6 Deploy Artifact in Target Tenant **
        elseif ($body.deployArtifact -eq $true) {
    Write-Host "📡 Deploying Artifact to Target Tenant: $body.targetArtifactId"

    # ** Call Deploy-Artifact Function **
   if ($global:CPITenantTYpe -eq "cloudFoundry"){
     Write-Host "📡 TenantType: $global:CPITenantTYpe"
    $deployResponse = Deploy-Artifact-CF -BaseUrl $global:targetBaseUrl -ArtifactId $body.targetArtifactId -Token $global:targetAccessToken -Version $body.targetArtifactVersion
    }else{
    $deployResponse = Deploy-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $body.targetArtifactId -Token $global:targetAccessToken -Version $body.targetArtifactVersion
    }

    # ** Send Response to Frontend **
    $jsonResponse = $deployResponse | ConvertTo-Json -Depth 3
    Write-Host "✅ Deployment Status Sent to Frontend."
}


    # ** 5.6.7 Deploy Multiple artifacts in target Tenant **

    
    elseif ($body.deployMultipleArtifacts -eq $true) {
    Write-Host "🚀 Received Multi-Deployment Request"



    $global:DeploymentStatus=@{}

    # Extract artifact pairs from request
    $artifactPairs = $body.artifactPairs
    if (-not $artifactPairs -or $artifactPairs.Count -eq 0) {
        Write-Host "❌ No artifact pairs found in request."
        $jsonResponse = @{ status = "error"; message = "No artifact pairs received." } | ConvertTo-Json
    } else {
        # ✅ Store artifact pairs in global variable for tracking
        $global:DeploymentStatus = @{}

        foreach ($pair in $artifactPairs) {
            # ✅ Extract Data Based on New Structure
            $sourceArtifactId = $pair.sourceArtifactId
            $sourceArtifactName = $pair.sourceArtifactName
            $sourceArtifactVersion = $pair.sourceArtifactVersion

            $targetArtifactId = $pair.targetArtifactId
            $targetArtifactName = $pair.targetArtifactName
            $targetArtifactVersion = $pair.targetArtifactVersion
             
          $sourceArtifactKey = "source_$sourceArtifactId"
          $targetArtifactKey = "target_$targetArtifactId"

            Write-Host "🔄 Processing Pair: $sourceArtifactName → $targetArtifactName"

            # ✅ Step 1: Fetch & Backup Configurations
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Backing Up Configurations..."; progress = 10 }
            Write-Host "📄 Fetching Configurations..."
            Send-Update
            
            $sourceConfig = Fetch-ArtifactConfigurations -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Version $sourceArtifactVersion -Token $global:sourceAccessToken -TenantType "source"
            $targetConfig = Fetch-ArtifactConfigurations -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Version $targetArtifactVersion -Token $global:targetAccessToken -TenantType "target"

            # ✅ Save to Single Configuration File
            $configFilePath = "$PSScriptRoot\Original_Configurations.txt"
            Add-Content -Path $configFilePath -Value "`n-------------------------------------"
            Add-Content -Path $configFilePath -Value "Pair: $sourceArtifactName → $targetArtifactName"
            Add-Content -Path $configFilePath -Value "-------------------------------------"
            Add-Content -Path $configFilePath -Value "Source Configurations: `n$($sourceConfig | Out-String)"
            Add-Content -Path $configFilePath -Value "Target Configurations: `n$($targetConfig | Out-String)"


            # ✅ Step 1: Fetch & Backup Configurations
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetching Source Configuration..."; progress = 3 }
Send-Update
Write-Host "📄 Fetching Configurations for Source Artifact: $sourceArtifactId"

try {
    $sourceConfig = Fetch-ArtifactConfigurations -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Version $sourceArtifactVersion -Token $global:sourceAccessToken -TenantType "source"
} catch {
    Write-Host "❌ Error fetching source configurations: $_"
    $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Source Configurations"; progress = 100 }
    Send-Update
    continue
}
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetched Source Configuration..."; progress = 5 }
Send-Update
# ✅ Update Progress
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetching Target Configuration..."; progress = 8 }
Send-Update
Write-Host "📄 Fetching Configurations for Target Artifact: $targetArtifactId"

try {
    $targetConfig = Fetch-ArtifactConfigurations -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Version $targetArtifactVersion -Token $global:targetAccessToken -TenantType "target"
} catch {
    Write-Host "❌ Error fetching target configurations: $_"
    $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Target Configurations"; progress = 100 }
    Send-Update
    continue
}

$global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetched Target Configuration..."; progress = 10 }
Send-Update
# ✅ Update Progress
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Saving Configurations..."; progress = 13 }
Send-Update

# ✅ Save to Single Configuration File
try {
    $configFilePath = "$PSScriptRoot\Original_Configurations.txt"
    Add-Content -Path $configFilePath -Value "`n-------------------------------------"
    Add-Content -Path $configFilePath -Value "Pair: $sourceArtifactName → $targetArtifactName"
    Add-Content -Path $configFilePath -Value "-------------------------------------"
    Add-Content -Path $configFilePath -Value "Source Configurations: `n$($sourceConfig | Out-String)"
    Add-Content -Path $configFilePath -Value "Target Configurations: `n$($targetConfig | Out-String)"
} catch {
    Write-Host "❌ Error saving configurations: $_"
    $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Save Configurations"; progress = 100 }
    Send-Update
    continue
}

Write-Host "✅ Configuration Backup Complete"
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Saved Configurations Successfully..."; progress = 15 }
Send-Update









            # ✅ Step 1.1: Fetch Zips
             # ** 1.1.1 Fetch Source Artifact ZIP **
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "Exporting Source Artifacts..."; progress = 18 }
             Send-Update
          
          try {
    $sourceZipFilePath = Export-Artifact -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Token $global:sourceAccessToken -Version $sourceArtifactVersion -TenantType "source"
} catch {
    Write-Host "❌ Error exporting Source artifact: $_"
    $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Source Artifact"; progress = 100 }
    Send-Update
    continue
}
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Exported Source Artifacts..."; progress = 20 }
Send-Update

          # ** 1.1.2 Fetch Target Artifact ZIP **

  $global:DeploymentStatus[$targetArtifactId] = @{ status = "Exporting Target Artifacts..."; progress = 22 } 
  Send-Update       
          try {
   $targetZipFilePath = Export-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken -Version $targetArtifactVersion -TenantType "target"
} catch {
    Write-Host "❌ Error exporting Target artifact: $_"
    $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Target Artifact"; progress = 100 }
    Send-Update
    continue
}
$global:DeploymentStatus[$targetArtifactId] = @{ status = "Exported Target Artifacts..."; progress = 25 }
Send-Update    

         $globaltargetArtifactId=$targetArtifactId
         $globalSourceArtifactVersion=$targetArtifactVersion
         $global:targetArtifactName=$targetArtifactName
         
          # ** Validate if ZIPs are downloaded successfully **
          
          if ($sourceZipFilePath -and $targetZipFilePath) {
            Write-Host "✅ Artifact ZIPs successfully downloaded: Source: $sourceZipFilePath, Target: $targetZipFilePath"
            }






             # ✅ Step 1.2: Extract Manifest from source
              Write-Host "📜 Fetching Manifest for Source Artifact: $sourceArtifactId"
           $global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetching Manifest for Source..."; progress = 27 }
           Send-Update    
           try{
             $sourceManifestPath = Extract-Manifest -ExtractedPath $global:sourceExtractPath
             }catch{
             Write-Host "❌ Error fetching source manifest: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Source manifest"; progress = 100 }
             Send-Update
             continue
             }
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "Manifest fetched for Source..."; progress = 30 } 
             Send-Update


             #DEFINE KEYS
              Write-Host "📜 Fetching Manifest for Source Manifest Path: $sourceManifestPath"
             $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")



            # Read Source Manifest File
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Reading Manifest of Source..."; progress = 32 }
            Send-Update
            try{
            $sourceContent = Read-ManifestFile -filePath $sourceManifestPath
            }catch{
             Write-Host "❌ Error reading source manifest: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Read Source manifest"; progress = 100 }
             Send-Update
             continue
            }
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Manifest of Source Read successfully..."; progress = 35 }
            Send-Update


            # Extract Values from source Manifest
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Reading Manifest of Source..."; progress = 37 }
            Send-Update
            try{
            $sourceManifestvalues = Extract-ManifestValues -content $sourceContent -keys $keys}

            catch{
            Write-Host "❌ Error extracting values from source source manifest: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to extract values from Source manifest"; progress = 100 }
             Send-Update
             continue
            }
             $global:DeploymentStatus[$targetArtifactId] = @{ status = " Values of source Manifest extracted..."; progress = 40 }
             Send-Update
            $sourceManifest = $sourceManifestvalues
            $global:cachedManifests[$sourceArtifactKey] = $sourceManifest
            Write-Host "Path= $global:sourceExtractPath"
            
                      

          # ** Fetch & Cache Manifest Data for Target Artifact **
          
            Write-Host "📜 Fetching Manifest for Target Artifact: $targetArtifactId"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = " Target Manifest extraction started..."; progress = 42 }
            Send-Update
            try{
            $targetManifestPath = Extract-Manifest -ExtractedPath $global:targetExtractPath
            }catch{
            Write-Host "❌ Error extracting target manifest: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to extract target manifest"; progress = 100 }
             Send-Update
             continue
            }
            $global:DeploymentStatus[$targetArtifactId] = @{ status = " Target Manifest extraction completed..."; progress = 45 }
            Send-Update

            $keys = @("Bundle-SymbolicName", "Origin-Bundle-SymbolicName", "Origin-Bundle-Name", "Bundle-Name")
            # Read Source Manifest File
            $global:DeploymentStatus[$targetArtifactId] = @{ status = " Reading Target manifest..."; progress = 47 }
            Send-Update
            try{
            $targetContent = Read-ManifestFile -filePath $sourceManifestPath
            }catch{
            Write-Host "❌ Error reading target manifest: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to read target manifest"; progress = 100 }
             Send-Update
             continue

            }
             $global:DeploymentStatus[$targetArtifactId] = @{ status = " Target manifest read successfully..."; progress = 49 }
             Send-Update


            # Extract Values from Target Manifest
             $global:DeploymentStatus[$targetArtifactId] = @{ status = " Extracting target manifest values..."; progress = 52 }
             Send-Update
             try{
            $targetManifestvalues = Extract-ManifestValues -content $targetContent -keys $keys
            }catch{
            Write-Host "❌ Error extracting target manifest values: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to extract target manifest values"; progress = 100 }
             Send-Update
             continue
            }
             $global:DeploymentStatus[$targetArtifactId] = @{ status = " Extraction of target manifest values complete..."; progress = 57 }
             Send-Update

            $targetManifest = $targetManifestvalues 
            $global:cachedManifests[$targetArtifactKey] = $targetManifest






            # Call the Modify-ManifestFile function
                # ** Ensure Extracted Paths Exist **
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "Modifying Manifest..."; progress = 60 }
                Send-Update
                Write-Host "📝 Modifying Manifest for: $targetArtifactName"
                $SourceManifestPath = $global:sourceExtractPath+"\META-INF\MANIFEST.MF"
                $TargetManifestPath = $global:targetExtractPath+"\META-INF\MANIFEST.MF"
                try{
                $modificationResponse = Process-ManifestReplacement -SourceFile $SourceManifestPath -TargetFile $TargetManifestPath -outputFile $SourceManifestPath}
                catch{
                 Write-Host "❌ Error modifying target manifest values: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to modify target manifest values"; progress = 100 }
             Send-Update
             continue
                }
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "Manifest Modified..."; progress = 62 }
                Send-Update

                # Step 2: Create ZIP Archive
                $ShortArtifactId = "mod_" + ([System.Guid]::NewGuid().ToString().Substring(0, 8))
                $OutputZipPath = "$global:ZipPath\$ShortArtifactId.zip"
                 $global:DeploymentStatus[$targetArtifactId] = @{ status = "Creating Zip for Upload..."; progress = 64 }
                 Send-Update
                 try{
                Create-Zip -ExtractedPath $SourceExtractPath -ZipPath $OutputZipPath
                }catch{
                Write-Host "❌ Error compiling zip: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to compile zip"; progress = 100 }
             Send-Update
             continue
                }
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "Zip created successfully..."; progress = 69 }
                Send-Update
                $global:modifiedZipPath = $OutputZipPath
                
                 $modificationResponse=@{
    Status = "success"
    ModifiedZipPath = $OutputZipPath}

                
                Write-Host "Response : $modificationResponse"
                # ** Extract the 'status' field correctly **
                $modificationStatus = $modificationResponse["status"]  # ✅ Retrieve "status" key correctly
                $modifiedZipPath = $modificationResponse["modifiedZipPath"]  # ✅ Retrieve "modifiedZipPath" key



            if ($modificationStatus -ne "success") {
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Manifest Modification Failed"; progress = 100 }
                Send-Update
                continue
            }

            # ✅ Step 3: Upload to Target
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Uploading Artifact..."; progress = 75 }
            Send-Update
            Write-Host "📤 Uploading Modified Artifact for: $targetArtifactName"

            try{
    # Use global variables instead of expecting them from request
    $uploadresult = Upload-Artifact -ArtifactFile $global:modifiedZipPath `
                                    -ArtifactId $globaltargetArtifactId `                                     `
                                    -Token $global:targetAccessToken `
                                    -ArtifactName $global:targetArtifactName `
                                    -Version $globalSourceArtifactVersion
                                     
                }catch{
                
                Write-Host "❌ Error uploading zip: $_"
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to upload zip"; progress = 100 }
             Send-Update
             continue



                }                    

$uploadStatus=$uploadresult["Status"]

            if ($uploadStatus -ne "success") {
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Upload Failed"; progress = 100 }
                Send-Update
                continue
            }
             $global:DeploymentStatus[$targetArtifactId] = @{ status = "Uploaded Artifact in Target System..."; progress = 78 }
             Send-Update
            # ✅ Step 4: Deploy to Target
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "Deploying Artifact..."; progress = 80 }
            Send-Update
            Write-Host "🚀 Deploying: $targetArtifactName"
            Write-Host "📡 TenantType: $global:CPITenantTYpe"
            if ($global:CPITenantTYpe -eq "cloudFoundry"){
     Write-Host "📡 TenantType: $global:CPITenantTYpe"
    $deployResponse = Deploy-Artifact-CF -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken -Version $targetArtifactVersion
    }else{
    $deployResponse = Deploy-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken -Version $targetArtifactVersion
    }

    $deployStatus = $deployResponse["status"]



            if ($deployStatus -eq "success") {
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "✅ Deployment Successful"; progress = 100 }
                Send-Update
            } else {
                $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Deployment Failed"; progress = 100 }
                Send-Update
            }



            # ✅ Send Final Deployment Completion Message

if ($pair -eq $artifactPairs[-1]) {  # ✅ Only send after last artifact is processed
    Write-Host "✅ All Deployments Completed!"
    $global:DeploymentStatus["completed"] = @{ status = "Deployment Finished"; progress = 100 }
   # Send-Update
}



#Clear global variables before the next loop
# ✅ Reset Cached Data
    $global:cachedPackages = @{}
    $global:cachedArtifacts = @{}
    $global:cachedArtifactStatus = @{}
    $global:cachedManifests = @{}
    $global:cachedConfigurations = @{}
    
    # ✅ Reset Paths and Artifact Variables
    $global:targetZipFilePath = $null
    $global:sourceZipFilePath = $null
    $global:targetExtractPath = $null
    $global:sourceExtractPath = $null
    $global:modifiedZipPath = $null
    $global:modifiedArtifactId = $null
    $global:modifiedArtifactVersion = $null
    $global:targetArtifactName = $null
    $global:targetPackageID = $null
    $globaltargetArtifactId = $null
    $globalSourceArtifactVersion = $null

        }

        # ✅ Return Response to UI
        $jsonResponse = @{ status = "success"; message = "Deployment Process Started" } | ConvertTo-Json
    }
}


<#

if ($body.deployMultipleArtifacts -eq $true) {
    Write-Host "🚀 Received Multi-Deployment Request"
    
    # ✅ Store request data in a variable
    $artifactPairs = $body.artifactPairs

    if (-not $artifactPairs -or $artifactPairs.Count -eq 0) {
        Write-Host "❌ No artifact pairs found in request."
        $jsonResponse = @{ status = "error"; message = "No artifact pairs received." } | ConvertTo-Json
       
        return
    }

    # ✅ Start Deployment in a Background Job
    # ✅ Start Deployment in a Background Job
$scriptBlock = {
    param($artifactPairs)
    
    # ✅ Clear Deployment JSON Before Starting New Deployment
    $deploymentFilePath = "$PSScriptRoot\deployment.json"
    @{} | ConvertTo-Json -Depth 3 | Set-Content -Path $deploymentFilePath -Encoding UTF8

    # ✅ Load Global Variables
    $global:DeploymentStatus = @{}

    foreach ($pair in $artifactPairs) {
        # Extract Data
        $sourceArtifactId = $pair.sourceArtifactId
        $targetArtifactId = $pair.targetArtifactId
        $sourceArtifactName = $pair.sourceArtifactName
        $targetArtifactName = $pair.targetArtifactName

        Write-Host "🔄 Processing Pair: $sourceArtifactName → $targetArtifactName"

        # ✅ Step 1: Fetch & Backup Configurations
        $global:DeploymentStatus[$targetArtifactId] = @{ status = "Fetching Configurations..."; progress = 10 }
        Send-Update

        try {
            $sourceConfig = Fetch-ArtifactConfigurations -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Token $global:sourceAccessToken
            $targetConfig = Fetch-ArtifactConfigurations -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken
            Send-Update
        } catch {
            Write-Host "❌ Failed to Fetch Configurations"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch Configurations"; progress = 100 }
            Send-Update
            continue
        }

        # ✅ Step 2: Fetch Artifact ZIPs
        $global:DeploymentStatus[$targetArtifactId] = @{ status = "Exporting Artifacts..."; progress = 30 }
        Send-Update
        try {
            $sourceZipFilePath = Export-Artifact -BaseUrl $global:sourceBaseUrl -ArtifactId $sourceArtifactId -Token $global:sourceAccessToken
            $targetZipFilePath = Export-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken
            Send-Update
        } catch {
            Write-Host "❌ Failed to Fetch ZIPs"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Fetch ZIPs"; progress = 100 }
            Send-Update
            continue
        }

        # ✅ Step 3: Extract & Modify Manifest
        $global:DeploymentStatus[$targetArtifactId] = @{ status = "Modifying Manifest..."; progress = 50 }
        Send-Update
        try {
            $sourceManifestPath = Extract-Manifest -ExtractedPath $sourceZipFilePath
            $targetManifestPath = Extract-Manifest -ExtractedPath $targetZipFilePath
            Process-ManifestReplacement -SourceFile $sourceManifestPath -TargetFile $targetManifestPath -outputFile $sourceManifestPath
            Send-Update
        } catch {
            Write-Host "❌ Failed to Modify Manifest"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Modify Manifest"; progress = 100 }
            Send-Update
            continue
        }

        # ✅ Step 4: Upload Artifact
        $global:DeploymentStatus[$targetArtifactId] = @{ status = "Uploading Artifact..."; progress = 70 }
        Send-Update
        try {
            $modifiedZipPath = "$PSScriptRoot\mod_$targetArtifactId.zip"
            Create-Zip -ExtractedPath $sourceZipFilePath -ZipPath $modifiedZipPath
            Upload-Artifact -ArtifactFile $modifiedZipPath -ArtifactId $targetArtifactId -Token $global:targetAccessToken
            Send-Update
        } catch {
            Write-Host "❌ Failed to Upload Artifact"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Failed to Upload Artifact"; progress = 100 }
            Send-Update
            continue
        }

        # ✅ Step 5: Deploy Artifact
        $global:DeploymentStatus[$targetArtifactId] = @{ status = "Deploying Artifact..."; progress = 90 }
        Send-Update
        try {
            Deploy-Artifact -BaseUrl $global:targetBaseUrl -ArtifactId $targetArtifactId -Token $global:targetAccessToken
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "✅ Deployment Completed"; progress = 100 }
            Send-Update
        } catch {
            Write-Host "❌ Deployment Failed"
            $global:DeploymentStatus[$targetArtifactId] = @{ status = "❌ Deployment Failed"; progress = 100 }
            Send-Update
            continue
        }
    }

    # ✅ Mark the entire process as complete
    $global:DeploymentStatus["completed"] = @{ status = "Deployment Finished"; progress = 100 }
    Send-Update
}




    # ✅ Run the deployment in the background
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $artifactPairs

    # ✅ Immediately send a response to the UI
    $jsonResponse = @{ status = "success"; message = "Deployment Started in Background" } | ConvertTo-Json
    
}

#>




        # ** 5.6.1  Fetch Packages**                  
        elseif($body.fetchPackages -eq $true) {
          # ** Fetch Integration Packages (With Caching) **
          Write-Host "📡 Fetching Integration Packages from Source & Target Tenants..."

          # ** Caching for Source Packages **
          if (-not $global:cachedPackages.ContainsKey($global:sourceBaseUrl)) {
            Write-Host "📦 Fetching New Source Packages..."
            $sourcePackages = Fetch-IntegrationPackages -BaseUrl $global:sourceBaseUrl -ClientId $global:sourceClientId -ClientSecret $global:sourceClientSecret -TokenUrl $global:sourceTokenUrl
            $global:cachedPackages[$global:sourceBaseUrl] = $sourcePackages
            Write-Host "$sourcePackages"
          } else {
            Write-Host "📦 Using Cached Source Packages..."
            $sourcePackages = $global:cachedPackages[$global:sourceBaseUrl]
          }

          # ** Caching for Target Packages **
          if (-not $global:cachedPackages.ContainsKey($global:targetBaseUrl)) {
            Write-Host "📦 Fetching New Target Packages..."
            $targetPackages = Fetch-IntegrationPackages -BaseUrl $global:targetBaseUrl -ClientId $global:targetClientId -ClientSecret $global:targetClientSecret -TokenUrl $global:targetTokenUrl
            Write-Host "$targetPackages"
            $global:cachedPackages[$global:targetBaseUrl] = $targetPackages
          } else {
            Write-Host "📦 Using Cached Target Packages..."
            $targetPackages = $global:cachedPackages[$global:targetBaseUrl]
          }
          # ** Ensure Response is in JSON Format **
          $response.ContentType = "application/json"

          if (-not $sourcePackages) { $sourcePackages = @() }
          if (-not $targetPackages) { $targetPackages = @() }

          $jsonResponse = @{
            Status = "success"
            sourcePackages = $sourcePackages
            targetPackages = $targetPackages
          } | ConvertTo-Json -Depth 3

          Write-Host "✅ Successfully sent integration packages to frontend."

        }


        # ** 5.7 Send JSON Response to Frontend **

        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
        $response.ContentLength64 = $buffer.Length
        $response.OutputStream.Write($buffer,0,$buffer.Length)
        Write-Host "Response Out"
        $response.Close()

      }
      catch {
        Write-Host "❌ Exception in main loop: $_"
        $response.StatusCode = 500 # Internal Server Error
        $response.Close()
      }
    }
    catch { Write-Host "❌ Error in script: $_" }

