@echo off
setlocal EnableDelayedExpansion
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
cl.exe /nologo /O2 /EHsc /std:c++17 /Fe:"BuildOutputx64\EliteMetaStamper.exe" "src\EliteSoftware-MetaStamper\main.cpp" ole32.lib uuid.lib shell32.lib user32.lib advapi32.lib
