param(
    [Parameter(Position=0)]
    [string]$Target = "$PWD"
)

# Fix path
if (Test-Path $Target -PathType Leaf) {
    $ServeDir = Split-Path $Target
    $DefaultDoc = Split-Path $Target -Leaf
} else {
    $ServeDir = $Target
    $DefaultDoc = "index.html"
}

Write-Host "EliteSoftware Development Server starting up..." -ForegroundColor Cyan

# Find available ports (increment by 2)
$HttpPort = 8080
$HttpsPort = 8443

function Test-Port {
    param($Port)
    $tcp = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
    try {
        $tcp.Start()
        $tcp.Stop()
        return $true
    } catch {
        return $false
    }
}

while (!(Test-Port $HttpPort)) { $HttpPort += 2 }
while (!(Test-Port $HttpsPort)) { $HttpsPort += 2 }

Write-Host "Bound HTTP to port $HttpPort" -ForegroundColor Green

$listener = New-Object System.Net.HttpListener
$httpPrefix = "http://localhost:$HttpPort/"
$listener.Prefixes.Add($httpPrefix)

# Attempt HTTPS (Needs elevation for netsh binding, so we wrap it in try/catch or skip if not elevated)
$Elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($Elevated) {
    Write-Host "Elevated context detected. Binding HTTPS to $HttpsPort..." -ForegroundColor Green
    
    # Generate temporary self-signed cert
    $cert = New-SelfSignedCertificate -DnsName "localhost" -CertStoreLocation "cert:\LocalMachine\My" -FriendlyName "EliteDevServer_Temp"
    $thumb = $cert.Thumbprint
    $guid = [guid]::NewGuid().ToString()

    # Bind cert to port
    $null = Invoke-Expression "netsh http add sslcert ipport=0.0.0.0:$HttpsPort certhash=$thumb appid={$guid}"

    $httpsPrefix = "https://localhost:$HttpsPort/"
    $listener.Prefixes.Add($httpsPrefix)
} else {
    Write-Host "Not elevated. HTTPS binding skipped." -ForegroundColor Yellow
}

try {
    $listener.Start()
} catch {
    Write-Host "Failed to start listener: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit
}

$launchUrl = "http://localhost:$HttpPort/$DefaultDoc"
Set-Clipboard -Value $launchUrl
Write-Host "URL Copied to Clipboard: $launchUrl" -ForegroundColor Cyan
Start-Process $launchUrl

Write-Host "Serving $ServeDir..."
Write-Host "Press Ctrl+C to stop."

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $reqPath = $request.Url.LocalPath.TrimStart('/')
        if ($reqPath -eq "") { $reqPath = $DefaultDoc }
        
        $filePath = Join-Path $ServeDir $reqPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $mime = switch ($ext) {
                ".html" { "text/html" }
                ".css"  { "text/css" }
                ".js"   { "application/javascript" }
                ".png"  { "image/png" }
                ".jpg"  { "image/jpeg" }
                ".jpeg" { "image/jpeg" }
                ".gif"  { "image/gif" }
                ".json" { "application/json" }
                ".svg"  { "image/svg+xml" }
                ".ico"  { "image/x-icon" }
                default { "application/octet-stream" }
            }
            
            $response.ContentType = $mime
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            
            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
            Write-Host "200 GET /$reqPath" -ForegroundColor Green
        } else {
            $response.StatusCode = 404
            Write-Host "404 GET /$reqPath" -ForegroundColor Red
        }
        $response.OutputStream.Close()
    }
} finally {
    $listener.Stop()
    if ($Elevated -and $thumb) {
        Write-Host "Cleaning up HTTPS bindings and temp certs..."
        $null = Invoke-Expression "netsh http delete sslcert ipport=0.0.0.0:$HttpsPort"
        Get-ChildItem "Cert:\LocalMachine\My\$thumb" | Remove-Item
    }
}
