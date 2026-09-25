$ErrorActionPreference = 'Stop'
$rc = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\rc.exe"
$msbuild = "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\amd64\MSBuild.exe"

$dirs = Get-ChildItem "src" -Directory
foreach ($dir in $dirs) {
    $exes = Get-ChildItem $dir.FullName -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue
    $dlls = Get-ChildItem $dir.FullName -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue
    
    if ($exes.Count -eq 0 -and $dlls.Count -eq 0) {
        Write-Host ""
        Write-Host "=========================================="
        Write-Host "Building ..."
        Write-Host "=========================================="
        
        Set-Location $dir.FullName
        
        $vcxproj = Get-ChildItem "*.vcxproj" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($vcxproj) {
            Write-Host "Found MSBuild project: "
            & $msbuild $vcxproj.Name /p:Configuration=Release /p:Platform=x64 /p:LanguageStandard=stdcpp17 /p:ForceImportBeforeCppTargets="$(Resolve-Path ..\NoWarn.props -ErrorAction SilentlyContinue)"
            if ($LASTEXITCODE -ne 0) { Write-Host "Failed!" -ForegroundColor Red }
            else { Write-Host "Success!" -ForegroundColor Green }
        }
        elseif (Test-Path "main.cpp") {
            Write-Host "Found main.cpp. Building with cl.exe..."
            if (-not (Test-Path "x64")) { New-Item -ItemType Directory -Path "x64" | Out-Null }
            
            $exeName = $dir.Name.Replace("EliteSoftware-", "Elite") + ".exe"
            if ($dir.Name -eq "EliteSoftware-EntryPoint") { $exeName = "EliteBuild.exe" }
            if ($dir.Name -eq "EliteSoftware-IconReplacer") { $exeName = "EliteIconReplacer.exe" }
            if ($dir.Name -eq "EliteSoftware-PSWrapper") { $exeName = "ElitePSWrapper.exe" }
            if ($dir.Name -eq "EliteSoftware-Compiler") { $exeName = "EliteBuild_Compiler.exe" }
            if ($dir.Name -eq "EliteSoftware-Packager") { $exeName = "EliteBuild_Packager.exe" }
            if ($dir.Name -eq "EliteSoftware-VersionBumper") { $exeName = "EliteBuild_VersionBumper.exe" }
            if ($dir.Name -eq "EliteSoftware-BuildLocator") { $exeName = "EliteBuildLocator.exe" }
            if ($dir.Name -eq "EliteSoftware-GitHub_Repo-Automation") { $exeName = "EliteGitHubAutomator.exe" }
            
            $args = @("/nologo", "/O2", "/EHsc", "/std:c++17", "/Fe:x64\$exeName", "main.cpp", "ole32.lib", "uuid.lib", "shell32.lib", "user32.lib", "advapi32.lib")
            
            if (Test-Path "icon.ico") {
                if (Test-Path "app.rc") {
                    Write-Host "Compiling resources..."
                    & $rc /fo "app.res" "app.rc"
                    $args += "app.res"
                }
            }
            elseif (Test-Path "resource.rc") {
                Write-Host "Compiling resources..."
                & $rc /fo "resource.res" "resource.rc"
                $args += "resource.res"
            }
            
            & cl.exe $args
            
            if ($LASTEXITCODE -ne 0) { Write-Host "Failed!" -ForegroundColor Red }
            else { 
                Write-Host "Success! Created x64\$exeName" -ForegroundColor Green
                Copy-Item "x64\$exeName" "..\..\BuildOutputx64\$exeName" -Force
            }
            
            Remove-Item "*.obj" -ErrorAction SilentlyContinue
        }
        else {
            # Might be a subdirectory like GitHub Automator CLI
            if ($dir.Name -eq "EliteSoftware-GitHub_Repo-Automation") {
                Write-Host "Special case: GitHub Automator"
                Set-Location "EliteSoftware-GitHub_Repo-Automation_CLI"
                if (-not (Test-Path "x64")) { New-Item -ItemType Directory -Path "x64" | Out-Null }
                $args = @("/nologo", "/O2", "/EHsc", "/std:c++17", "/Fe:x64\EliteGitHubAutomator.exe", "main.cpp", "ole32.lib", "uuid.lib", "shell32.lib", "user32.lib", "advapi32.lib")
                if (Test-Path "..\resource.rc") {
                    & $rc /fo "resource.res" "..\resource.rc"
                    $args += "resource.res"
                }
                & cl.exe $args
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Success! Created x64\EliteGitHubAutomator.exe" -ForegroundColor Green
                    Copy-Item "x64\EliteGitHubAutomator.exe" "..\..\..\BuildOutputx64\EliteGitHubAutomator.exe" -Force
                }
                Remove-Item "*.obj" -ErrorAction SilentlyContinue
            } else {
                Write-Host "Skipping  - Not a standard C++ or MSBuild project."
            }
        }
        
        Set-Location "C:\Users\Administrator\Desktop\Projects\EliteSoftware_Build-Automations"
    }
}
