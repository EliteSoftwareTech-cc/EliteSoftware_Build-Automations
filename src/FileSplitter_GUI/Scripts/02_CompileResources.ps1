# ==============================================================================
# Scripts/02_CompileResources.ps1
# Win32 Resource Script Compilation (64-bit and 32-bit targets)
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# ==============================================================================

$ErrorActionPreference = 'Stop'

Write-Host " [02/05] Compiling Win32 Resource Scripts..." -ForegroundColor Cyan

$scriptPath = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptPath\.."

Set-Location $projectRoot

$rcFile = "$projectRoot\res\FileSplitter.rc"
if (-not (Test-Path $rcFile)) {
    Write-Host " [ERROR] Resource script missing: $rcFile" -ForegroundColor Red
    exit 1
}

$buildOutput = "$projectRoot\BuildOutput"
$buildOutputx86 = "$projectRoot\BuildOutputx86"

# 1. Compile 64-bit Resource Object
Write-Host "  -> Compiling 64-bit resources (BuildOutput/FileSplitter.res.o)..." -ForegroundColor Gray
$res64Obj = "$buildOutput\FileSplitter.res.o"
& windres $rcFile -O coff -o $res64Obj
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $res64Obj)) {
    Write-Host " [ERROR] Failed to compile 64-bit resources." -ForegroundColor Red
    exit 1
}
Write-Host "     Created: $res64Obj ($( (Get-Item $res64Obj).Length ) bytes)" -ForegroundColor Green

# 2. Compile 32-bit Resource Object
Write-Host "  -> Compiling 32-bit resources (BuildOutputx86/FileSplitter.res.o)..." -ForegroundColor Gray
$res32Obj = "$buildOutputx86\FileSplitter.res.o"
& windres $rcFile -O coff -F pe-i386 -o $res32Obj
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $res32Obj)) {
    Write-Host " [ERROR] Failed to compile 32-bit resources." -ForegroundColor Red
    exit 1
}
Write-Host "     Created COFF i386: $res32Obj ($( (Get-Item $res32Obj).Length ) bytes)" -ForegroundColor Green

# 3. Also generate RES binary for MSVC compatibility if needed
$res32Res = "$buildOutputx86\FileSplitter.res"
& windres $rcFile -O res -o $res32Res 2>$null
if (-not (Test-Path $res32Res)) {
    $rcCmd = Get-Command rc.exe -ErrorAction SilentlyContinue
    if ($rcCmd) {
        & rc.exe /nologo /fo $res32Res $rcFile
    }
}
if (Test-Path $res32Res) {
    Write-Host "     Created RES binary: $res32Res ($( (Get-Item $res32Res).Length ) bytes)" -ForegroundColor Green
}

Write-Host " [SUCCESS] Step 02: Resource compilation complete.`n" -ForegroundColor Green
