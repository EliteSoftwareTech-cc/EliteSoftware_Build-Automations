@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
cd src\EliteSoftware-IconReplacer
mkdir x64 2>nul
"C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\rc.exe" /fo app.res app.rc
cl.exe /nologo /O2 /EHsc /std:c++17 /Fe:"x64\EliteIconReplacer.exe" main.cpp app.res ole32.lib uuid.lib shell32.lib user32.lib advapi32.lib imagehlp.lib
copy /Y "x64\EliteIconReplacer.exe" "..\..\BuildOutputx64\EliteIconReplacer.exe"
