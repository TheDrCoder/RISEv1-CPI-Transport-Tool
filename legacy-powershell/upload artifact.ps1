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

$global:targetBaseUrl="https://swmx-test-lucfr9vh.it-cpi005.cfapps.eu20.hana.ondemand.com"
$globalSourceArtifactVersion="1.0.11"
$global:targetArtifactName="SWMX - Postprocess Business Partner Relationship to SAP Business Suite"
$global:targetAccessToken="eyJhbGciOiJSUzI1NiIsImprdSI6Imh0dHBzOi8vc3dteC10ZXN0LWx1Y2ZyOXZoLmF1dGhlbnRpY2F0aW9uLmV1MjAuaGFuYS5vbmRlbWFuZC5jb20vdG9rZW5fa2V5cyIsImtpZCI6ImRlZmF1bHQtand0LWtleS0tNjI2NjgyMTA2IiwidHlwIjoiSldUIiwiamlkIjogImZ2cnBkUmpmbDhSSVJPZk9EUjZOSGpvZ3ZGM1hlYTJrNGhJSHQ1aEZJMlE9In0.eyJqdGkiOiIzZGE0MjhmNjE5NzU0OWZjODM2Y2M4YTNmZTJkYjgxYyIsImV4dF9hdHRyIjp7ImVuaGFuY2VyIjoiWFNVQUEiLCJzdWJhY2NvdW50aWQiOiIyNzNlZWFjYi0xNmU0LTRlYzAtODgyYi1hODE0OTM1NjFjYTciLCJ6ZG4iOiJzd214LXRlc3QtbHVjZnI5dmgiLCJzZXJ2aWNlaW5zdGFuY2VpZCI6ImIzY2NmNmQwLWZkYTctNDI2OC04MTVmLWY2Yjk0ZDc1MTIxMCJ9LCJzdWIiOiJzYi1iM2NjZjZkMC1mZGE3LTQyNjgtODE1Zi1mNmI5NGQ3NTEyMTAhYjcwMTN8aXQhYjI1OSIsImF1dGhvcml0aWVzIjpbIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsUnVudGltZVBhcmFtZXRlci5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJTZW5zaXRpdmVEYXRhLlJlYWQiLCJpdCFiMjU5LldlYlRvb2xpbmdTZXR0aW5nc1Byb2R1Y3RQcm9maWxlcy5zYXZldGVuYW50Y29uZmlndXJhdGlvbiIsIml0IWIyNTkuVGVuYW50UGFydG5lckRpcmVjdG9yeS5yZWFkIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmV0cnkiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbENvbXBvbmVudC5SZXN0YXJ0IiwiaXQhYjI1OS5Xb3Jrc3BhY2VEZXNpZ25HdWlkZWxpbmVzLkNvbmZpZ3VyZSIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95Y29udGVudCIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuUmVhZCIsIml0IWIyNTkuRXh0ZXJuYWxMb2dnaW5nLkFjdGl2YXRlIiwiaXQhYjI1OS5Db21wYW55UHJvZmlsZS5SZWFkIiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5Xcml0ZSIsIml0IWIyNTkuV29ya3NwYWNlQXJ0aWZhY3RMb2Nrcy5EZWxldGUiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5Db25maWciLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9nLlN0YXR1c0NoYW5nZSIsIml0IWIyNTkuUm9sZXMuV3JpdGUiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5yZWFkUGF5bG9hZCIsIml0IWIyNTkuSW50ZWdyYXRpb25PcGVyYXRpb25TZXJ2ZXIucmVhZCIsIml0IWIyNTkuTm9kZU1hbmFnZXIucmVhZCIsIml0IWIyNTkuSW50ZWdyYXRpb25PcGVyYXRpb25TZXJ2ZXIubW9kaWZ5b3BlcmF0aW9uc2pvYnMiLCJ1YWEucmVzb3VyY2UiLCJpdCFiMjU5LkVTQkRhdGFTdG9yZS5BY3RpdmF0ZSIsIml0IWIyNTkuRVNCTWVzc2FnZVN0b3JhZ2UuRGVsZXRlIiwiaXQhYjI1OS5NZXNzYWdlVXNhZ2VEYXNoYm9hcmQuUmVhZCIsIml0IWIyNTkuRXh0ZXJuYWxMb2dnaW5nQWN0aXZhdGlvbi5SZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclByb2ZpbGUuUmVhZCIsIml0IWIyNTkuTm9kZU1hbmFnZXIucmVhZHNlY3VyaXR5Y29udGVudCIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95Y3JlZGVudGlhbHMiLCJpdCFiMjU5LldlYlRvb2xpbmdDYXRhbG9nLkNyZWF0ZSIsIml0IWIyNTkuV2ViVG9vbGluZ0NhdGFsb2cuT3ZlcnZpZXdSZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5EZXRhaWxzUmVhZCIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJQcm9maWxlLldyaXRlIiwiaXQhYjI1OS5UZW5hbnRQYXJ0bmVyRGlyZWN0b3J5LndyaXRlIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLlB1Ymxpc2giLCJpdCFiMjU5LkRhdGFBcmNoaXZpbmcuUmVhZCIsIml0IWIyNTkuRGF0YUFyY2hpdmluZy5BY3RpdmF0ZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsQ29tcG9uZW50LlJlYWQiLCJpdCFiMjU5LkdlbmVyYXRpb25BbmRCdWlsZC5nZW5lcmF0aW9uYW5kYnVpbGRjb250ZW50IiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5SZWFkIiwiaXQhYjI1OS5lc2JtZXNzYWdlc3RvcmFnZS5yZWFkIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJTZW5zaXRpdmVEYXRhLldyaXRlIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmVhZCIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50LlB1Ymxpc2giLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyLlJlc3RhcnRDb21wb25lbnQiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MuRGVsZXRlIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLlJlYWQiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MuUmVhZCIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsUnVudGltZVBhcmFtZXRlci5SZWFkIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5SZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkY3JlZGVudGlhbHMiLCJpdCFiMjU5LldlYlRvb2xpbmcuRFNPREludGVncmF0aW9uIiwiaXQhYjI1OS5QSVByb3Zpc2lvbmluZy53cml0ZSIsIml0IWIyNTkuQ29kZWxpc3QuUmVhZCIsIml0IWIyNTkuV29ya3NwYWNlQXJ0aWZhY3RMb2Nrcy5SZWFkIiwiaXQhYjI1OS5Sb2xlcy5SZWFkIiwiaXQhYjI1OS5Db25maWd1cmF0aW9uU2VydmljZS5SdW50aW1lQnVzaW5lc3NQYXJhbWV0ZXJXcml0ZSIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLmRlbGV0ZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsT3BlcmF0aW9uQ29ja3BpdC5SZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5Eb3dubG9hZCIsIml0IWIyNTkuQ29tcGFueVByb2ZpbGUuV3JpdGUiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50LldyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lckFncmVlbWVudC5SZWFkIiwiaXQhYjI1OS5EZWZhdWx0IiwiaXQhYjI1OS5XZWJUb29saW5nLkludGVncmF0aW9uRmxvd0NvbmZpZ3VyZSIsIml0IWIyNTkuR292ZXJuYW5jZS5Hb3Zlcm5hbmNlQ29tbWVudHNXcml0ZSIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95c2VjdXJpdHljb250ZW50IiwiaXQhYjI1OS5Hb3Zlcm5hbmNlLkdvdmVybmFuY2VDb21tZW50c1JlYWQiXSwic2NvcGUiOlsiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5SZWFkIiwiaXQhYjI1OS5BY2Nlc3NQb2xpY2llcy5Xcml0ZSIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuUmVhZCIsIml0IWIyNTkuQWdyZWVtZW50VGVtcGxhdGUuV3JpdGUiLCJpdCFiMjU5LkNvZGVsaXN0LlJlYWQiLCJpdCFiMjU5LkNvbXBhbnlQcm9maWxlLlJlYWQiLCJpdCFiMjU5LkNvbXBhbnlQcm9maWxlLldyaXRlIiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5SZWFkIiwiaXQhYjI1OS5Db21wYW55U2Vuc2l0aXZlRGF0YS5Xcml0ZSIsIml0IWIyNTkuQ29uZmlndXJhdGlvblNlcnZpY2UuUnVudGltZUJ1c2luZXNzUGFyYW1ldGVyV3JpdGUiLCJpdCFiMjU5LkRhdGFBcmNoaXZpbmcuQWN0aXZhdGUiLCJpdCFiMjU5LkRhdGFBcmNoaXZpbmcuUmVhZCIsIml0IWIyNTkuRGVmYXVsdCIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLkFjdGl2YXRlIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUuQ29uZmlnIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUuZGVsZXRlIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmVhZCIsIml0IWIyNTkuRVNCRGF0YVN0b3JlLnJlYWRQYXlsb2FkIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUucmV0cnkiLCJpdCFiMjU5LkVTQk1lc3NhZ2VTdG9yYWdlLkRlbGV0ZSIsIml0IWIyNTkuRXh0ZXJuYWxMb2dnaW5nLkFjdGl2YXRlIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmdBY3RpdmF0aW9uLlJlYWQiLCJpdCFiMjU5LkdlbmVyYXRpb25BbmRCdWlsZC5nZW5lcmF0aW9uYW5kYnVpbGRjb250ZW50IiwiaXQhYjI1OS5Hb3Zlcm5hbmNlLkdvdmVybmFuY2VDb21tZW50c1JlYWQiLCJpdCFiMjU5LkdvdmVybmFuY2UuR292ZXJuYW5jZUNvbW1lbnRzV3JpdGUiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbENvbXBvbmVudC5SZWFkIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxDb21wb25lbnQuUmVzdGFydCIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsT3BlcmF0aW9uQ29ja3BpdC5SZWFkIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxSdW50aW1lUGFyYW1ldGVyLlJlYWQiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbFJ1bnRpbWVQYXJhbWV0ZXIuV3JpdGUiLCJpdCFiMjU5LkludGVncmF0aW9uT3BlcmF0aW9uU2VydmVyLm1vZGlmeW9wZXJhdGlvbnNqb2JzIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbk9wZXJhdGlvblNlcnZlci5yZWFkIiwiaXQhYjI1OS5NZXNzYWdlUHJvY2Vzc2luZ0xvY2tzLkRlbGV0ZSIsIml0IWIyNTkuTWVzc2FnZVByb2Nlc3NpbmdMb2Nrcy5SZWFkIiwiaXQhYjI1OS5NZXNzYWdlUHJvY2Vzc2luZ0xvZy5TdGF0dXNDaGFuZ2UiLCJpdCFiMjU5Lk1lc3NhZ2VVc2FnZURhc2hib2FyZC5SZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5SZXN0YXJ0Q29tcG9uZW50IiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5kZXBsb3ljb250ZW50IiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5kZXBsb3ljcmVkZW50aWFscyIsIml0IWIyNTkuTm9kZU1hbmFnZXIuZGVwbG95c2VjdXJpdHljb250ZW50IiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkIiwiaXQhYjI1OS5Ob2RlTWFuYWdlci5yZWFkY3JlZGVudGlhbHMiLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyLnJlYWRzZWN1cml0eWNvbnRlbnQiLCJpdCFiMjU5LlBJUHJvdmlzaW9uaW5nLndyaXRlIiwiaXQhYjI1OS5Sb2xlcy5SZWFkIiwiaXQhYjI1OS5Sb2xlcy5Xcml0ZSIsIml0IWIyNTkuVGVuYW50UGFydG5lckRpcmVjdG9yeS5yZWFkIiwiaXQhYjI1OS5UZW5hbnRQYXJ0bmVyRGlyZWN0b3J5LndyaXRlIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lckFncmVlbWVudC5QdWJsaXNoIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lckFncmVlbWVudC5SZWFkIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lckFncmVlbWVudC5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJQcm9maWxlLlJlYWQiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyUHJvZmlsZS5Xcml0ZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJTZW5zaXRpdmVEYXRhLlJlYWQiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyU2Vuc2l0aXZlRGF0YS5Xcml0ZSIsIml0IWIyNTkuV2ViVG9vbGluZy5EU09ESW50ZWdyYXRpb24iLCJpdCFiMjU5LldlYlRvb2xpbmcuSW50ZWdyYXRpb25GbG93Q29uZmlndXJlIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5DcmVhdGUiLCJpdCFiMjU5LldlYlRvb2xpbmdDYXRhbG9nLkRldGFpbHNSZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZy5Eb3dubG9hZCIsIml0IWIyNTkuV2ViVG9vbGluZ0NhdGFsb2cuT3ZlcnZpZXdSZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nU2V0dGluZ3NQcm9kdWN0UHJvZmlsZXMuc2F2ZXRlbmFudGNvbmZpZ3VyYXRpb24iLCJpdCFiMjU5LldlYlRvb2xpbmdXb3Jrc3BhY2UuUHVibGlzaCIsIml0IWIyNTkuV2ViVG9vbGluZ1dvcmtzcGFjZS5SZWFkIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlLldyaXRlIiwiaXQhYjI1OS5Xb3Jrc3BhY2VBcnRpZmFjdExvY2tzLkRlbGV0ZSIsIml0IWIyNTkuV29ya3NwYWNlQXJ0aWZhY3RMb2Nrcy5SZWFkIiwiaXQhYjI1OS5Xb3Jrc3BhY2VEZXNpZ25HdWlkZWxpbmVzLkNvbmZpZ3VyZSIsIml0IWIyNTkuZXNibWVzc2FnZXN0b3JhZ2UucmVhZCIsInVhYS5yZXNvdXJjZSJdLCJjbGllbnRfaWQiOiJzYi1iM2NjZjZkMC1mZGE3LTQyNjgtODE1Zi1mNmI5NGQ3NTEyMTAhYjcwMTN8aXQhYjI1OSIsImNpZCI6InNiLWIzY2NmNmQwLWZkYTctNDI2OC04MTVmLWY2Yjk0ZDc1MTIxMCFiNzAxM3xpdCFiMjU5IiwiYXpwIjoic2ItYjNjY2Y2ZDAtZmRhNy00MjY4LTgxNWYtZjZiOTRkNzUxMjEwIWI3MDEzfGl0IWIyNTkiLCJncmFudF90eXBlIjoiY2xpZW50X2NyZWRlbnRpYWxzIiwicmV2X3NpZyI6Ijk1MWY2OTNlIiwiaWF0IjoxNzQwMjUzMDYzLCJleHAiOjE3NDAyNTY2NjMsImlzcyI6Imh0dHBzOi8vc3dteC10ZXN0LWx1Y2ZyOXZoLmF1dGhlbnRpY2F0aW9uLmV1MjAuaGFuYS5vbmRlbWFuZC5jb20vb2F1dGgvdG9rZW4iLCJ6aWQiOiIyNzNlZWFjYi0xNmU0LTRlYzAtODgyYi1hODE0OTM1NjFjYTciLCJhdWQiOlsiaXQhYjI1OS5XZWJUb29saW5nIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbk9wZXJhdGlvblNlcnZlciIsIml0IWIyNTkuR292ZXJuYW5jZSIsIml0IWIyNTkuVHJhZGluZ1BhcnRuZXJQcm9maWxlIiwiaXQhYjI1OS5Xb3Jrc3BhY2VEZXNpZ25HdWlkZWxpbmVzIiwiaXQhYjI1OS5FU0JNZXNzYWdlU3RvcmFnZSIsIml0IWIyNTkuQ29uZmlndXJhdGlvblNlcnZpY2UiLCJpdCFiMjU5IiwiaXQhYjI1OS5QSVByb3Zpc2lvbmluZyIsInVhYSIsIml0IWIyNTkuQ29kZWxpc3QiLCJpdCFiMjU5LlRyYWRpbmdQYXJ0bmVyQWdyZWVtZW50IiwiaXQhYjI1OS5NZXNzYWdlUHJvY2Vzc2luZ0xvZyIsIml0IWIyNTkuTWVzc2FnZVVzYWdlRGFzaGJvYXJkIiwiaXQhYjI1OS5lc2JtZXNzYWdlc3RvcmFnZSIsIml0IWIyNTkuSW50ZWdyYXRpb25DZWxsQ29tcG9uZW50IiwiaXQhYjI1OS5EYXRhQXJjaGl2aW5nIiwiaXQhYjI1OS5FU0JEYXRhU3RvcmUiLCJpdCFiMjU5LkNvbXBhbnlTZW5zaXRpdmVEYXRhIiwiaXQhYjI1OS5XZWJUb29saW5nQ2F0YWxvZyIsIml0IWIyNTkuV2ViVG9vbGluZ1NldHRpbmdzUHJvZHVjdFByb2ZpbGVzIiwiaXQhYjI1OS5XZWJUb29saW5nV29ya3NwYWNlIiwiaXQhYjI1OS5FeHRlcm5hbExvZ2dpbmciLCJpdCFiMjU5LlRlbmFudFBhcnRuZXJEaXJlY3RvcnkiLCJpdCFiMjU5LlJvbGVzIiwiaXQhYjI1OS5JbnRlZ3JhdGlvbkNlbGxSdW50aW1lUGFyYW1ldGVyIiwiaXQhYjI1OS5UcmFkaW5nUGFydG5lclNlbnNpdGl2ZURhdGEiLCJpdCFiMjU5LldvcmtzcGFjZUFydGlmYWN0TG9ja3MiLCJpdCFiMjU5LkV4dGVybmFsTG9nZ2luZ0FjdGl2YXRpb24iLCJpdCFiMjU5Lk5vZGVNYW5hZ2VyIiwic2ItYjNjY2Y2ZDAtZmRhNy00MjY4LTgxNWYtZjZiOTRkNzUxMjEwIWI3MDEzfGl0IWIyNTkiLCJpdCFiMjU5LkdlbmVyYXRpb25BbmRCdWlsZCIsIml0IWIyNTkuQ29tcGFueVByb2ZpbGUiLCJpdCFiMjU5LkludGVncmF0aW9uQ2VsbE9wZXJhdGlvbkNvY2twaXQiLCJpdCFiMjU5Lk1lc3NhZ2VQcm9jZXNzaW5nTG9ja3MiLCJpdCFiMjU5LkFjY2Vzc1BvbGljaWVzIiwiaXQhYjI1OS5BZ3JlZW1lbnRUZW1wbGF0ZSJdfQ.XlH1fg5egF5_6687hmYU1SDkdfRMd45iWj6mkvrwrGBxeleViwX12JWYtsarJztUbVQwStf19cfnpgzB3dFEo3tfwBdKLoyk_d4BAp_w8J2FuewC5zqZyL2aFIemYJQ3GPiW1TFi_-bvpzE5IzkYLpviVavM2WjWwBzGGz-3FIWV61TFZKdJe1QzZ-MPtoW9xnKWKq36OUo1h4WJkHwPRkx4TWty6tV93ilQXbuZBVCm5P22yqYS4taU1vte59RzJQpluKQN5V6fDl_JwziWfpjdMvZ_OE3EpbsH19SKx7cJFxX4twEbpTAmpVrUFFJ2ioTkScNlLir7St412ilidg"
$global:modifiedZipPath="C:\Users\NineeshuGupta\Downloads\CPi Transport Tool\CPITransportTool_Data\ZIPs\mod_73e462b0.zip"
$globaltargetArtifactId="SWMX_-_Postprocess_Business_Partner_Relationship_to_SAP_Business_Suite"
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

Write-Host "📡 Deploying Artifact to Target Tenant: $body.targetArtifactId"

    # ** Call Deploy-Artifact Function **
    $deployResponse = Deploy-Artifact-CF -BaseUrl $global:targetBaseUrl -ArtifactId $globaltargetArtifactId -Token $global:targetAccessToken -Version $globalSourceArtifactVersion

    # ** Send Response to Frontend **
    $jsonResponse = $deployResponse | ConvertTo-Json -Depth 3
    Write-Host "✅ Deployment Status Sent to Frontend."

