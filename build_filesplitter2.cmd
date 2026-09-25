@echo off
setlocal EnableDelayedExpansion
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
set RC="C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64\rc.exe"

echo Building FileSplitter.exe from src\FileSplitter_GUI ...
%RC% /fo "src\FileSplitter_GUI\app.res" "src\FileSplitter_GUI\res\FileSplitter.rc"
cl.exe /nologo /O2 /EHsc /std:c++17 /DUNICODE /D_UNICODE /I"src\FileSplitter_GUI\include" /Fe:"BuildOutputx64\FileSplitter.exe" "src\FileSplitter_GUI\src\AppWindow.cpp" "src\FileSplitter_GUI\src\Dialogs.cpp" "src\FileSplitter_GUI\src\Logger.cpp" "src\FileSplitter_GUI\src\main.cpp" "src\FileSplitter_GUI\src\TextSplitterEngine.cpp" "src\FileSplitter_GUI\app.res" comctl32.lib comdlg32.lib gdi32.lib user32.lib uxtheme.lib shell32.lib shlwapi.lib psapi.lib ole32.lib oleaut32.lib advapi32.lib
