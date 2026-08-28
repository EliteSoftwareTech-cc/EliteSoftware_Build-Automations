$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$mdFiles = Get-ChildItem -Path $ScriptDir -Filter "*.md"
$jsonHash = @{}

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    if ($content) {
        $jsonHash[$file.Name] = $content
    }
}

$jsonString = $jsonHash | ConvertTo-Json -Depth 10 -Compress
$outputPath = Join-Path $ScriptDir "media\Web-HTML\DocsData.js"
Set-Content -Path $outputPath -Value $jsContent -Encoding UTF8
Write-Host "DocsData.js generated successfully at $outputPath from $($mdFiles.Count) files."
