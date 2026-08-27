# ==============================================================================
# Scripts/05_PackageOutput.ps1
# Packaging, Dynamic Icon Sideloading, Documentation Copy, HTML Dashboard & Release Verification
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# ==============================================================================

$ErrorActionPreference = 'Stop'

Write-Host " [05/05] Packaging Release Artifacts & Verifying Output..." -ForegroundColor Cyan

$scriptPath = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptPath\.."

Set-Location $projectRoot

$buildOutput = "$projectRoot\BuildOutput"
$buildOutputx86 = "$projectRoot\BuildOutputx86"
$icoSource = "$projectRoot\res\FileSplitter.ico"

# 1. Verify Executables Exist
$exe64 = "$buildOutput\FileSplitter.exe"
$exe32 = "$buildOutputx86\FileSplitter.exe"

if (-not (Test-Path $exe64)) {
    Write-Host " [ERROR] 64-bit binary missing: $exe64" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $exe32)) {
    Write-Host " [ERROR] 32-bit binary missing: $exe32" -ForegroundColor Red
    exit 1
}

# Helper function to read PE Machine header
function Get-PeMachineHeader {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath) -or (Get-Item $FilePath).Extension -ne ".exe") { return $null }
    $fs = [System.IO.File]::OpenRead((Resolve-Path $FilePath))
    try {
        $br = New-Object System.IO.BinaryReader($fs)
        $fs.Position = 0x3C
        $peOffset = $br.ReadInt32()
        $fs.Position = $peOffset + 4
        $machine = $br.ReadUInt16()
        if ($machine -eq 0x014c) { return "PE 0x014C (x86 32-bit)" }
        if ($machine -eq 0x8664) { return "PE 0x8664 (x64 64-bit)" }
        return ("PE 0x{0:X4}" -f $machine)
    } catch {
        return $null
    } finally {
        $fs.Close()
    }
}

# Verify PE headers before packaging
$pe64 = Get-PeMachineHeader $exe64
$pe32 = Get-PeMachineHeader $exe32

if ($pe64 -notlike "*0x8664*") {
    Write-Host " [ERROR] Packaging failed: BuildOutput\FileSplitter.exe is not a valid 64-bit PE binary ($pe64)." -ForegroundColor Red
    exit 1
}

if ($pe32 -notlike "*0x014C*") {
    Write-Host " [ERROR] Packaging failed: BuildOutputx86\FileSplitter.exe is not a valid 32-bit PE binary ($pe32)." -ForegroundColor Red
    exit 1
}

# 2. Dynamic Icon Sideloading Copy
Write-Host "  -> Copying dynamic icon (FileSplitter.ico) alongside executables..." -ForegroundColor Gray
if (Test-Path $icoSource) {
    Copy-Item $icoSource "$buildOutput\FileSplitter.ico" -Force
    Copy-Item $icoSource "$buildOutputx86\FileSplitter.ico" -Force
    Copy-Item $icoSource "$projectRoot\FileSplitter.ico" -Force -ErrorAction SilentlyContinue
    Write-Host "     Sideloaded FileSplitter.ico to BuildOutput and BuildOutputx86." -ForegroundColor Green
} else {
    Write-Host " [WARNING] Icon file res/FileSplitter.ico not found." -ForegroundColor Yellow
}

# 3. Copy Documentation Files & HTML Agent Dashboard
Write-Host "  -> Packaging documentation & Agent HTML Dashboard..." -ForegroundColor Gray
$docFiles = @("README.md", "PROJECT.md", "ORIGINAL_REQUEST.md")
foreach ($doc in $docFiles) {
    $docPath = "$projectRoot\$doc"
    if (Test-Path $docPath) {
        Copy-Item $docPath "$buildOutput\$doc" -Force
        Copy-Item $docPath "$buildOutputx86\$doc" -Force
    }
}

$agentHtmlDir = "$projectRoot\Agent-Thread_HTML"
if (Test-Path $agentHtmlDir) {
    Copy-Item $agentHtmlDir "$buildOutput\Agent-Thread_HTML" -Recurse -Force
    Copy-Item $agentHtmlDir "$buildOutputx86\Agent-Thread_HTML" -Recurse -Force
    Write-Host "     Packaged Agent-Thread_HTML dashboard to release folders." -ForegroundColor Green
}

Write-Host "     Packaged documentation to output directories." -ForegroundColor Green

# 4. Summary of Release Deliverables
Write-Host "`n  ================ RELEASE ARTIFACTS SUMMARY ================" -ForegroundColor Cyan

$artifacts = @(
    (Get-Item $exe64),
    (Get-Item "$buildOutput\FileSplitter.ico"),
    (Get-Item $exe32),
    (Get-Item "$buildOutputx86\FileSplitter.ico")
)

foreach ($art in $artifacts) {
    $relPath = $art.FullName.Replace($projectRoot.Path, "").TrimStart("\")
    $sizeKB = [math]::Round($art.Length / 1KB, 2)
    $peHeader = Get-PeMachineHeader $art.FullName
    $peStr = if ($peHeader) { "  [$peHeader]" } else { "" }
    Write-Host ("  {0,-35} : {1,8} KB{2}  [{3}]" -f $relPath, $sizeKB, $peStr, $art.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")) -ForegroundColor Green
}

Write-Host "  ===========================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] Step 05: Output packaged and verified successfully.`n" -ForegroundColor Green
