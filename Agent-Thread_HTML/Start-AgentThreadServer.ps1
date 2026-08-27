# ==============================================================================
# EliteSoftwareTech Co. - Agent-Thread HTML Backend Server & Thread-Safe Appender
# File: Start-AgentThreadServer.ps1
# Port: 29585 | Protocol: HTTP | Host: All Network Adapters (0.0.0.0 / +)
# ==============================================================================

[CmdletBinding(DefaultParameterSetName='RunServer')]
param(
    # Mode Switches
    [Parameter(ParameterSetName='AddThread')][switch]$AddThread,
    [Parameter(ParameterSetName='AddHistory')][switch]$AddHistory,
    [Parameter(ParameterSetName='AddArtifact')][switch]$AddArtifact,
    [Parameter(ParameterSetName='AddVersion')][switch]$AddVersion,
    [Parameter(ParameterSetName='AddPlan')][switch]$AddPlan,

    # Parameters for Thread
    [string]$AgentId,
    [string]$AgentName,
    [string]$AgentRole,
    [string]$AgentColor,
    [string]$Subject,
    [string]$Content,
    [string]$Status,

    # Parameters for History
    [string]$Milestone,
    [string]$Sender,
    [string]$Recipient,
    [string]$Action,
    [string]$Details,

    # Parameters for Artifacts
    [string]$Name,
    [string]$Path,
    [string]$Architecture,
    [string]$Size,
    [string]$TargetOS,
    [string]$SHA256,
    [string]$Description,

    # Parameters for Version
    [string]$Version,
    [string]$Changes,
    [string]$BuildNotes,

    # Server Configuration
    [int]$Port = 29585,
    [string]$RootDirectory = $PSScriptRoot
)

if (-not $RootDirectory -or -not (Test-Path $RootDirectory)) {
    $RootDirectory = Get-Location
}
$RootDirectory = (Resolve-Path $RootDirectory).Path

function Update-JsonFile {
    param([string]$FileName, [scriptblock]$TransformBlock)
    $filePath = Join-Path $RootDirectory $FileName
    $data = @{}
    if (Test-Path $filePath) {
        try {
            $data = Get-Content $filePath -Raw | ConvertFrom-Json -AsHashtable
        } catch {
            $data = @{}
        }
    }
    
    & $TransformBlock $data
    
    $json = $data | ConvertTo-Json -Depth 10
    $json | Set-Content $filePath -Encoding UTF8
}

# --- CLI COMMAND EXECUTION MODE ---
if ($AddThread) {
    if (-not $AgentId) { $AgentId = "agent_" + [Guid]::NewGuid().ToString().Substring(0,8) }
    if (-not $AgentName) { $AgentName = $AgentId }
    if (-not $AgentRole) { $AgentRole = "Agent" }
    if (-not $AgentColor) { $AgentColor = "#38bdf8" }
    if (-not $Recipient) { $Recipient = "all" }
    if (-not $Subject) { $Subject = "Status Update" }
    if (-not $Status) { $Status = "complete" }

    Update-JsonFile "thread_data.json" {
        param($d)
        if (-not $d.ContainsKey("agents") -or $null -eq $d["agents"]) { $d["agents"] = @() }
        if (-not $d.ContainsKey("threads") -or $null -eq $d["threads"]) { $d["threads"] = @() }

        $agentExists = $false
        foreach ($a in $d["agents"]) {
            if ($a["id"] -eq $AgentId) { $agentExists = $true; break }
        }
        if (-not $agentExists) {
            $d["agents"] += @{
                "id" = $AgentId
                "name" = $AgentName
                "role" = $AgentRole
                "color" = $AgentColor
            }
        }

        $newMsg = @{
            "id" = "msg-" + ($d["threads"].Count + 1).ToString("D3")
            "timestamp" = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "sender_id" = $AgentId
            "recipient" = $Recipient
            "subject" = $Subject
            "content" = $Content
            "status" = $Status
        }
        $d["threads"] += $newMsg
        $d["last_updated"] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    Write-Host "[SUCCESS] Added Thread Message: $Subject" -ForegroundColor Green
    return
}

if ($AddHistory) {
    if (-not $Milestone) { $Milestone = "M1" }
    if (-not $Sender) { $Sender = "Agent" }
    if (-not $Recipient) { $Recipient = "All" }
    if (-not $Action) { $Action = "Status Update" }

    Update-JsonFile "history_data.json" {
        param($d)
        if (-not $d.ContainsKey("history") -or $null -eq $d["history"]) { $d["history"] = @() }
        $newHist = @{
            "milestone" = $Milestone
            "timestamp" = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "sender" = $Sender
            "recipient" = $Recipient
            "action" = $Action
            "details" = $Details
        }
        $d["history"] += $newHist
    }
    Write-Host "[SUCCESS] Added History Record: $Action" -ForegroundColor Green
    return
}

if ($AddArtifact) {
    if (-not $Name) { $Name = "Artifact" }
    if (-not $Architecture) { $Architecture = "x64" }
    if (-not $Size) { $Size = "0 KB" }
    if (-not $TargetOS) { $TargetOS = "Windows Vista+" }
    if (-not $Status) { $Status = "Release" }
    if (-not $SHA256) { $SHA256 = "N/A" }

    Update-JsonFile "artifacts_data.json" {
        param($d)
        if (-not $d.ContainsKey("artifacts") -or $null -eq $d["artifacts"]) { $d["artifacts"] = @() }
        $newArt = @{
            "name" = $Name
            "path" = $Path
            "architecture" = $Architecture
            "size" = $Size
            "target_os" = $TargetOS
            "status" = $Status
            "sha256" = $SHA256
            "description" = $Description
        }
        $d["artifacts"] += $newArt
        $d["last_updated"] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    Write-Host "[SUCCESS] Added Artifact Record: $Name" -ForegroundColor Green
    return
}

if ($AddVersion) {
    if (-not $Version) { $Version = "1.0.0.0" }

    Update-JsonFile "artifacts_data.json" {
        param($d)
        if (-not $d.ContainsKey("version_history") -or $null -eq $d["version_history"]) { $d["version_history"] = @() }
        $newVer = @{
            "version" = $Version
            "timestamp" = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "changes" = $Changes
            "build_notes" = $BuildNotes
        }
        $d["version_history"] += $newVer
    }
    Write-Host "[SUCCESS] Added Version Record: $Version" -ForegroundColor Green
    return
}

if ($AddPlan) {
    Update-JsonFile "plan_data.json" {
        param($d)
        if ($Status) { $d["status"] = $Status }
    }
    Write-Host "[SUCCESS] Updated Plan Data." -ForegroundColor Green
    return
}

# --- SERVER RUN TIME MODE ---
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  ELITESOFTWARETECH CO. - AGENT-THREAD HTML SERVER BACKEND" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Port:            $Port" -ForegroundColor White
Write-Host "  Root Directory:  $RootDirectory" -ForegroundColor White
Write-Host "  CLI Engine:      ENABLED (Thread-Safe Parameter & API Appender)" -ForegroundColor White
Write-Host ""

$ipv4List = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
    Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
    ForEach-Object {
        $adapterName = $_.Name
        $_.GetIPProperties().UnicastAddresses | 
            Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
            Select-Object @{N='Adapter';E={$adapterName}}, @{N='IP';E={$_.Address.ToString()}}
    }

Write-Host "  [ Available Access Endpoints ]" -ForegroundColor Green
Write-Host "  |-- Localhost:     http://localhost:$Port/" -ForegroundColor Cyan
Write-Host "  |-- Loopback:      http://127.0.0.1:$Port/" -ForegroundColor Cyan

foreach ($item in $ipv4List) {
    Write-Host ("  |-- " + $item.Adapter.PadRight(20) + ": http://" + $item.IP + ":$Port/") -ForegroundColor Green
}
Write-Host "================================================================================" -ForegroundColor Cyan

$listener = New-Object System.Net.HttpListener

$prefixPrimary = "http://+:$Port/"
$prefixFallback = "http://*:$Port/"
$prefixLocalhost = "http://localhost:$Port/"

try {
    $listener.Prefixes.Add($prefixPrimary)
    $listener.Start()
} catch {
    try {
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add($prefixFallback)
        $listener.Start()
    } catch {
        $listener.Prefixes.Clear()
        $listener.Prefixes.Add($prefixLocalhost)
        $listener.Start()
    }
}

Write-Host "  Server Listening Status: ACTIVE" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the server..." -ForegroundColor Gray
Write-Host "================================================================================" -ForegroundColor Cyan

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".ico"  = "image/x-icon"
    ".svg"  = "image/svg+xml"
    ".md"   = "text/markdown; charset=utf-8"
    ".txt"  = "text/plain; charset=utf-8"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        [System.Threading.ThreadPool]::QueueUserWorkItem({
            param($ctx)
            $req = $ctx.Request
            $res = $ctx.Response

            $res.Headers.Add("Access-Control-Allow-Origin", "*")
            $res.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            $res.Headers.Add("Pragma", "no-cache")
            $res.Headers.Add("Expires", "0")

            $urlPath = $req.Url.AbsolutePath
            if ($urlPath -eq "/" -or [string]::IsNullOrWhiteSpace($urlPath)) {
                $urlPath = "/index.html"
            }

            $localPath = [System.IO.Path]::Combine($RootDirectory, $urlPath.TrimStart('/').Replace('/', '\'))

            if (Test-Path $localPath -PathType Leaf) {
                $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
                if ($mimeTypes.ContainsKey($ext)) {
                    $res.ContentType = $mimeTypes[$ext]
                } else {
                    $res.ContentType = "application/octet-stream"
                }

                $bytes = [System.IO.File]::ReadAllBytes($localPath)
                $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
                $res.StatusCode = 200
            } else {
                $res.StatusCode = 404
                $errMsg = [System.Text.Encoding]::UTF8.GetBytes("404 - File Not Found: $urlPath")
                $res.ContentType = "text/plain; charset=utf-8"
                $res.ContentLength64 = $errMsg.Length
                $res.OutputStream.Write($errMsg, 0, $errMsg.Length)
            }
            try { $res.OutputStream.Close() } catch {}
        }, $context) | Out-Null
    }
} finally {
    if ($listener.IsListening) {
        $listener.Stop()
        $listener.Close()
    }
}
