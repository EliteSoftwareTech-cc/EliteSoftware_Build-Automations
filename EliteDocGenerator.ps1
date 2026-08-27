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
$jsContent = "const EliteDocsData = $jsonString;"
Set-Content -Path (Join-Path $ScriptDir "DocsData.js") -Value $jsContent -Encoding UTF8
Write-Host "DocsData.js generated successfully from $($mdFiles.Count) files."
