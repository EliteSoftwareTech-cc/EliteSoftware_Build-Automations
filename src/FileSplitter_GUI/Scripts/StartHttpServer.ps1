# StartHttpServer.ps1
param ([int]$Port = 8888)
$ProjectRoot = "C:\Users\Administrator\Desktop\File_Splitter_ForAI-Upload"
$HtmlDir = Join-Path $ProjectRoot "Agent-Thread_HTML"

Write-Host "Starting Agent Live Thread HTTP Server on port $Port" -ForegroundColor Green
Set-Location $HtmlDir
python -m http.server $Port --bind 0.0.0.0
