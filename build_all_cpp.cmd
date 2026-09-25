@echo off
setlocal EnableDelayedExpansion
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set RC="C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\rc.exe"

set exes=EliteADBManager EliteAssetManager EliteCertManager EliteClipSaver EliteComLoader EliteDocConverter EliteDotNetEnv EliteDummyDllGen EliteDuplicateSweeper EliteExecPolToggle EliteEXEKiller EliteFolderScanner EliteHostConfigurator EliteLaunchAsTI EliteMetaStamper EliteNetworkManager EliteOptiLink ElitePIDKiller EliteProfileManager ElitePSWrapper EliteRegSnapshot EliteRepoCloner EliteServiceForge EliteShortcutForge EliteSiteCompiler EliteSymlinker EliteSystemRestore EliteTaskAssassin EliteVSBuildTools EliteWin7Enabler

for %%i in (%exes%) do (
    set "name=%%i"
    set "srcName=!name:Elite=EliteSoftware-!"
    if "!name!"=="ElitePSWrapper" set "srcName=EliteSoftware-PSWrapper"
    
    echo Building !name!.exe from src\!srcName! ...
    if exist "src\!srcName!\app.rc" (
        %RC% /fo "src\!srcName!\app.res" "src\!srcName!\app.rc"
        cl.exe /nologo /O2 /EHsc /std:c++17 /Fe:"BuildOutputx64\!name!.exe" "src\!srcName!\main.cpp" "src\!srcName!\app.res" ole32.lib uuid.lib shell32.lib user32.lib advapi32.lib
    ) else (
        cl.exe /nologo /O2 /EHsc /std:c++17 /Fe:"BuildOutputx64\!name!.exe" "src\!srcName!\main.cpp" ole32.lib uuid.lib shell32.lib user32.lib advapi32.lib
    )
    del /q "src\!srcName!\*.obj" 2>nul
    del /q "main.obj" 2>nul
)
