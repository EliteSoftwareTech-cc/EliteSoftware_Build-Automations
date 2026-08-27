# ==============================================================================
# Scripts/04_CompileBinaries.ps1
# Win32 GUI Binary Compilation (64-bit and 32-bit targets for Windows Vista+)
# EliteSoftwareTech Co. - File Splitter For AI Upload v1.2.0.0
# ==============================================================================

$ErrorActionPreference = 'Stop'

Write-Host " [04/05] Compiling Win32 GUI Executables (Windows Vista+ minimum OS)..." -ForegroundColor Cyan

$scriptPath = $PSScriptRoot
$projectRoot = Resolve-Path "$scriptPath\.."

Set-Location $projectRoot

# Helper function to read PE Machine header
function Get-PeMachineHeader {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return 0 }
    $fs = [System.IO.File]::OpenRead((Resolve-Path $FilePath))
    try {
        $br = New-Object System.IO.BinaryReader($fs)
        $fs.Position = 0x3C
        $peOffset = $br.ReadInt32()
        $fs.Position = $peOffset + 4
        return $br.ReadUInt16()
    } finally {
        $fs.Close()
    }
}

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

$buildOutput = "$projectRoot\BuildOutput"
$buildOutputx86 = "$projectRoot\BuildOutputx86"

$srcFiles = @(
    "$projectRoot\src\main.cpp",
    "$projectRoot\src\AppWindow.cpp",
    "$projectRoot\src\Dialogs.cpp",
    "$projectRoot\src\Logger.cpp",
    "$projectRoot\src\TextSplitterEngine.cpp"
)

$ldFlags = @(
    "-lcomctl32", "-lcomdlg32", "-lgdi32", "-luser32",
    "-luxtheme", "-lshell32", "-lshlwapi", "-lpsapi",
    "-lole32", "-loleaut32"
)

# 1. Compile 64-bit Binary (BuildOutput/FileSplitter.exe)
Write-Host "  -> Compiling 64-bit Win32 GUI Executable (BuildOutput/FileSplitter.exe)..." -ForegroundColor Gray
$res64Obj = "$buildOutput\FileSplitter.res.o"
$exe64 = "$buildOutput\FileSplitter.exe"

$args64 = @(
    "-std=c++17", "-O2", "-s",
    "-D_WIN32_WINNT=0x0600", "-DWINVER=0x0600",
    "-DUNICODE", "-D_UNICODE",
    "-municode", "-mwindows",
    "-Iinclude"
) + $srcFiles + @($res64Obj) + $ldFlags + @("-o", $exe64)

& g++ $args64
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exe64)) {
    Write-Host " [ERROR] Failed to compile 64-bit binary: $exe64" -ForegroundColor Red
    exit 1
}

# Verify PE header for 64-bit executable (0x8664)
$mach64 = Get-PeMachineHeader $exe64
if ($mach64 -ne 0x8664) {
    Write-Host (" [ERROR] 64-bit binary PE machine header is 0x{0:X4} (expected 0x8664 / x64)" -f $mach64) -ForegroundColor Red
    exit 1
}
Write-Host ("     Successfully built 64-bit binary: {0} ({1} bytes, PE 0x{2:X4} x64)" -f $exe64, (Get-Item $exe64).Length, $mach64) -ForegroundColor Green

# Copy 64-bit binary to project root for convenient execution
Copy-Item $exe64 "$projectRoot\FileSplitter.exe" -Force

# 2. Compile 32-bit Binary (BuildOutputx86/FileSplitter.exe)
Write-Host "  -> Compiling 32-bit Win32 GUI Executable (BuildOutputx86/FileSplitter.exe)..." -ForegroundColor Gray
$res32Obj = "$buildOutputx86\FileSplitter.res.o"
$res32Res = "$buildOutputx86\FileSplitter.res"
$exe32 = "$buildOutputx86\FileSplitter.exe"

$built32 = $false
$toolchainUsed32 = ""

# Option A: Check for i686-w64-mingw32-g++
$i686Gcc = Get-Command i686-w64-mingw32-g++ -ErrorAction SilentlyContinue
if ($i686Gcc) {
    try {
        $oldEap = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $args32 = @(
            "-std=c++17", "-O2", "-s",
            "-D_WIN32_WINNT=0x0600", "-DWINVER=0x0600",
            "-DUNICODE", "-D_UNICODE",
            "-municode", "-mwindows",
            "-Iinclude"
        ) + $srcFiles + @($res32Obj) + $ldFlags + @("-o", $exe32)

        & i686-w64-mingw32-g++ $args32 2>$null
        if ((Test-Path $exe32) -and ($LASTEXITCODE -eq 0)) {
            $built32 = $true
            $toolchainUsed32 = "i686-w64-mingw32-g++"
        }
        $ErrorActionPreference = $oldEap
    } catch {
        $ErrorActionPreference = 'Stop'
    }
}

# Option B: Check for g++ -m32
if (-not $built32) {
    try {
        $oldEap = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $args32m = @(
            "-m32", "-std=c++17", "-O2", "-s",
            "-D_WIN32_WINNT=0x0600", "-DWINVER=0x0600",
            "-DUNICODE", "-D_UNICODE",
            "-municode", "-mwindows",
            "-Iinclude"
        ) + $srcFiles + @($res32Obj) + $ldFlags + @("-o", $exe32)

        & g++ $args32m 2>$null
        if ((Test-Path $exe32) -and ($LASTEXITCODE -eq 0)) {
            $built32 = $true
            $toolchainUsed32 = "g++ -m32"
        }
        $ErrorActionPreference = $oldEap
    } catch {
        $ErrorActionPreference = 'Stop'
    }
}

# Option C: Use MSVC cl.exe for x86 via vcvarsall.bat
if (-not $built32) {
    $vcvarsPath = Find-VcvarsallBat
    if ($vcvarsPath) {
        Write-Host "     Compiling via MSVC x86 compiler (vcvarsall.bat x86)..." -ForegroundColor Gray
        $resFileToUse = if (Test-Path $res32Res) { $res32Res } else { $res32Obj }
        $srcArgs = ($srcFiles | ForEach-Object { "`"$_`"" }) -join " "
        $msvcLibs = "comctl32.lib comdlg32.lib gdi32.lib user32.lib uxtheme.lib shell32.lib shlwapi.lib psapi.lib ole32.lib oleaut32.lib"
        
        $cmdLine = "/c `"call `"$vcvarsPath`" x86 && cl /nologo /O2 /W3 /EHsc /std:c++17 /D_WIN32_WINNT=0x0600 /DWINVER=0x0600 /DUNICODE /D_UNICODE /Iinclude $srcArgs `"$resFileToUse`" /Fe:`"$exe32`" /link /SUBSYSTEM:WINDOWS $msvcLibs`""
        
        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList $cmdLine -Wait -NoNewWindow -PassThru
        if ($proc.ExitCode -eq 0 -and (Test-Path $exe32)) {
            $built32 = $true
            $toolchainUsed32 = "MSVC cl.exe (x86)"
        }
    }
}

if (-not $built32 -or -not (Test-Path $exe32)) {
    Write-Host " [ERROR] No working 32-bit C++ compiler available to build 32-bit executable $exe32." -ForegroundColor Red
    exit 1
}

# 3. STRICT PE Machine Header Verification for 32-bit Binary (0x014C / i386)
$mach32 = Get-PeMachineHeader $exe32
if ($mach32 -ne 0x014c) {
    Write-Host (" [ERROR] BuildOutputx86/FileSplitter.exe machine header is 0x{0:X4} (expected 0x014C / i386). Silent 64-bit fallback rejected!" -f $mach32) -ForegroundColor Red
    exit 1
}

Write-Host ("     Successfully built 32-bit binary: {0} ({1} bytes, PE 0x{2:X4} i386 via {3})" -f $exe32, (Get-Item $exe32).Length, $mach32, $toolchainUsed32) -ForegroundColor Green

Write-Host " [SUCCESS] Step 04: Binary compilation completed successfully with verified 64-bit & 32-bit PE headers.`n" -ForegroundColor Green
