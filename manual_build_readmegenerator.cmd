@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
cd src\EliteSoftware-ReadmeGenerator
mkdir x64 2>nul
cl.exe /nologo /O2 /EHsc /std:c++17 /Fe:"x64\EliteReadmeGenerator.exe" main.cpp ole32.lib uuid.lib shell32.lib user32.lib advapi32.lib
copy /Y "x64\EliteReadmeGenerator.exe" "..\..\BuildOutputx64\EliteReadmeGenerator.exe"
