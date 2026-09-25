@echo off
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul
powershell.exe -ExecutionPolicy Bypass -File build_seq_logic.ps1
