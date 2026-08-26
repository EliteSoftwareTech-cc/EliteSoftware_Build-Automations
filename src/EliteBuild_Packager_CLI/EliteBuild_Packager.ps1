<#
.SYNOPSIS
EliteBuild_Packager

.DESCRIPTION
A CLI tool to handle Zipping, PDF Documentation Generation, and InnoSetup installers.
Uses arguments, falling back to EliteBuild_Packager.config if present.

.PARAMETER ConfigFile
Optional config file.
.PARAMETER GenerateDocs
Boolean to run markdown to PDF conversion.
.PARAMETER InnoSetupScripts
Array of .iss script paths.
.PARAMETER ZipTargets
Hashtable or mapping of ArchiveName -> Array of files to include.
#>
param (
    [string]$ConfigFile = "EliteBuild_Packager.config",
    [switch]$GenerateDocs,
    [string[]]$InnoSetupScripts,
    [hashtable]$ZipTargets
)

$ErrorActionPreference = 'Stop'
Write-Host "[ EliteBuild_Packager ]" -ForegroundColor Cyan

$config = @{}
if (Test-Path $ConfigFile) {
    try {
        $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        Write-Host "Loaded config: $ConfigFile" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to parse config."
    }
}

$doDocs = $GenerateDocs.IsPresent -or $config.GenerateDocs
if (-not $InnoSetupScripts -and $config.InnoSetupScripts) { $InnoSetupScripts = $config.InnoSetupScripts }

if ($doDocs) {
    Write-Host "Generating Documentation PDF..." -ForegroundColor Green
    $mdFiles = Get-ChildItem -Filter "*.md" | Select-Object -ExpandProperty FullName
    if ($mdFiles) {
        $mdContent = ""
        foreach ($f in $mdFiles) { $mdContent += (Get-Content $f -Raw) + "`n<hr>`n" }
        $mdContent | Out-File temp_docs.md
        $html = (ConvertFrom-Markdown -Path temp_docs.md).Html
        $fullHtml = "<html><head><style>body{font-family:Segoe UI, sans-serif; margin: 2em; line-height: 1.6;} h1, h2, h3{color:#003366;} hr{margin-top:2em;margin-bottom:2em;}</style></head><body>$html</body></html>"
        $fullHtml | Out-File temp_docs.html
        
        $supermium = "C:\Program Files\supermium\chrome.exe"
        if (Test-Path $supermium) {
            & $supermium --headless --print-to-pdf="$PWD\Project_Documentation.pdf" "$PWD\temp_docs.html"
            Start-Sleep -Seconds 3
        } else {
            Write-Warning "Supermium not found. Cannot generate PDF."
        }
        Remove-Item temp_docs.md, temp_docs.html -ErrorAction SilentlyContinue
    }
}

if ($InnoSetupScripts) {
    $iscc = "S:\Projects\Inno Setup 6\iscc.exe"
    if (-not (Test-Path $iscc)) { $iscc = "C:\Program Files (x86)\Inno Setup 6\iscc.exe" }
    
    foreach ($iss in $InnoSetupScripts) {
        if (Test-Path $iss) {
            Write-Host "Compiling Installer: $iss" -ForegroundColor Green
            & $iscc $iss
            if ($LASTEXITCODE -ne 0) { throw "Failed to compile $iss" }
        } else {
            Write-Warning "ISS script not found: $iss"
        }
    }
}

# ZipTargets from config usually comes as a PSCustomObject, convert logic
if ($config.ZipTargets) {
    foreach ($prop in $config.ZipTargets.psobject.properties) {
        $zipName = $prop.Name
        $files = $prop.Value
        Write-Host "Creating Archive: $zipName" -ForegroundColor Green
        
        $tempDir = "temp_zip_staging_$([guid]::NewGuid().ToString().Substring(0,8))"
        New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
        
        foreach ($f in $files) {
            if (Test-Path $f) { Copy-Item $f -Destination $tempDir -Recurse }
            else { Write-Warning "File to zip not found: $f" }
        }
        
        if (Test-Path $zipName) { Remove-Item $zipName -Force }
        Compress-Archive -Path "$tempDir\*" -DestinationPath $zipName
        Remove-Item -Recurse -Force $tempDir
    }
}

Write-Host "Packaging complete." -ForegroundColor Green
