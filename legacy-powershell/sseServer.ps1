# 🌍 Global Path for Deployment Status File
$deploymentStatusFile = "$PSScriptRoot\deploymentStatus.json"

# Start HTTP Listener for SSE
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:9091/")
$listener.Start()
Write-Host "📡 SSE Server Running on http://localhost:9091/"

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    if ($request.Url.AbsolutePath -eq "/deploymentStatusStream") {
        Write-Host "📡 SSE Connection Established"

        # Set SSE Headers
        $response.StatusCode = 200
        $response.ContentType = "text/event-stream"
        $response.Headers.Add("Cache-Control", "no-cache")
        $response.Headers.Add("Connection", "keep-alive")

        try {
            while ($true) {
                if (Test-Path $deploymentStatusFile) {
                    # Read the latest deployment status
                    $jsonData = Get-Content $deploymentStatusFile -Raw
                    if ($jsonData) {
                        $eventData = "data: $jsonData`n`n"
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($eventData)
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                        $response.OutputStream.Flush()
                        Write-Host "📡 Live Update Sent: $jsonData"
                    }
                }
                Start-Sleep -Seconds 2
            }
        } catch {
            Write-Host "❌ SSE Stream Error: $_"
        } finally {
            $response.OutputStream.Close()
            Write-Host "🚪 SSE Stream Closed."
        }
    }
}
