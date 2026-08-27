param ([int]$IntervalSeconds = 3)
$ErrorActionPreference = "SilentlyContinue"
$ProjectRoot = "C:\Users\Administrator\Desktop\File_Splitter_ForAI-Upload"
$HtmlDir = Join-Path $ProjectRoot "Agent-Thread_HTML"

$f1 = Join-Path $HtmlDir "thread_data.json"
$f2 = Join-Path $HtmlDir "history_data.json"
$f3 = Join-Path $HtmlDir "artifacts_data.json"
$f4 = Join-Path $HtmlDir "plan_data.json"

Write-Host "EliteSoftwareWatcher Started" -ForegroundColor Green

while ($true) {
    $nowStr = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    if (Test-Path $f1) {
        $t = Get-Content -Raw $f1 | ConvertFrom-Json
        if ($t) { $t.last_updated = $nowStr; $t | ConvertTo-Json -Depth 10 | Set-Content $f1 -Encoding UTF8 }
    }
    if (Test-Path $f3) {
        $a = Get-Content -Raw $f3 | ConvertFrom-Json
        if ($a) { $a.last_updated = $nowStr; $a | ConvertTo-Json -Depth 10 | Set-Content $f3 -Encoding UTF8 }
    }
    Start-Sleep -Seconds $IntervalSeconds
}
