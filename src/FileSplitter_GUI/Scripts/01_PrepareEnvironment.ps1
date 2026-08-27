# ==============================================================================
# Scripts/01_PrepareEnvironment.ps1
# Environment Preparation & Toolchain Validation
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# ==============================================================================

$ErrorActionPreference = 'Stop'

Write-Host " [01/05] Preparing Build Environment & Validating Toolchain..." -ForegroundColor Cyan

$scriptPath = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptPath\.."

Set-Location $projectRoot

# Helper function to locate MSVC vcvarsall.bat
function Find-VcvarsallBat {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $vsInstall = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if ($vsInstall -and (Test-Path "$vsInstall\VC\Auxiliary\Build\vcvarsall.bat")) {
            return "$vsInstall\VC\Auxiliary\Build\vcvarsall.bat"
        }
    }

    $commonPaths = @(
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvarsall.bat",
        "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvarsall.bat",
        "$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat",
        "$env:ProgramFiles\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat"
    )

    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    $found = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio", "$env:ProgramFiles\Microsoft Visual Studio" -Recurse -Include vcvarsall.bat -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) {
        return $found.FullName
    }

    return $null
}

# 1. Validate g++ (64-bit)
Write-Host "  -> Validating 64-bit C++ Compiler (g++)..." -ForegroundColor Gray
$gccVersionOutput = & g++ --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] g++ compiler not found in PATH or failed to execute." -ForegroundColor Red
    exit 1
}
$gccFirstLine = ($gccVersionOutput -split "`n")[0]
Write-Host "     Found: $gccFirstLine" -ForegroundColor Green

# 2. Validate windres
Write-Host "  -> Validating Win32 Resource Compiler (windres)..." -ForegroundColor Gray
$windresVersionOutput = & windres --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host " [ERROR] windres resource compiler not found in PATH or failed to execute." -ForegroundColor Red
    exit 1
}
$windresFirstLine = ($windresVersionOutput -split "`n")[0]
Write-Host "     Found: $windresFirstLine" -ForegroundColor Green

# 3. Check target architectures (64-bit and 32-bit support)
Write-Host "  -> Verifying target architecture support..." -ForegroundColor Gray
Write-Host "     x64 Target : Supported (Native x86_64 MinGW toolchain)" -ForegroundColor Green

$x86Supported = $false
$x86CompilerInfo = ""

$i686Gcc = Get-Command i686-w64-mingw32-g++ -ErrorAction SilentlyContinue
if ($i686Gcc) {
    $x86Supported = $true
    $x86CompilerInfo = "i686-w64-mingw32-g++"
} else {
    $oldEap = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    $m32Test = & g++ -m32 --version 2>&1
    $ErrorActionPreference = $oldEap
    if ($LASTEXITCODE -eq 0) {
        $x86Supported = $true
        $x86CompilerInfo = "g++ -m32"
    } else {
        $vcvars = Find-VcvarsallBat
        if ($vcvars) {
            $x86Supported = $true
            $x86CompilerInfo = "MSVC cl.exe (x86) via $vcvars"
        }
    }
}

if ($x86Supported) {
    Write-Host "     x86 Target : Supported ($x86CompilerInfo)" -ForegroundColor Green
} else {
    Write-Host " [ERROR] x86 Target : FAILED (No working 32-bit compiler toolchain detected)" -ForegroundColor Red
    exit 1
}

# 4. Ensure Output Directories Exist
$buildOutput = "$projectRoot\BuildOutput"
$buildOutputx86 = "$projectRoot\BuildOutputx86"

Write-Host "  -> Creating output directories..." -ForegroundColor Gray
if (-not (Test-Path $buildOutput)) {
    New-Item -ItemType Directory -Path $buildOutput | Out-Null
    Write-Host "     Created: $buildOutput" -ForegroundColor Green
} else {
    Write-Host "     Exists: $buildOutput" -ForegroundColor Gray
}

if (-not (Test-Path $buildOutputx86)) {
    New-Item -ItemType Directory -Path $buildOutputx86 | Out-Null
    Write-Host "     Created: $buildOutputx86" -ForegroundColor Green
} else {
    Write-Host "     Exists: $buildOutputx86" -ForegroundColor Gray
}

# 5. Clean Old Temporary Objects and Artifacts
Write-Host "  -> Cleaning temporary object files..." -ForegroundColor Gray
$cleanFiles = Get-ChildItem -Path $projectRoot, "$projectRoot\res", $buildOutput, $buildOutputx86 -Include *.o, *.obj, *.res, *.res.o -Recurse -ErrorAction SilentlyContinue
foreach ($file in $cleanFiles) {
    Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
}
Write-Host "     Clean complete." -ForegroundColor Green

Write-Host " [SUCCESS] Step 01: Environment prepared successfully.`n" -ForegroundColor Green
