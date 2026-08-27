@echo off
setlocal

set CXX=g++
set CXXFLAGS=-O2 -m64
set LDFLAGS=-lgdiplus -lole32 -lkernel32 -luser32

echo Compiling icon_maker...
%CXX% %CXXFLAGS% main.cpp -o icon_maker.exe %LDFLAGS%

if %errorlevel% neq 0 (
    echo Compilation failed.
    exit /b %errorlevel%
)

echo Compilation succeeded! Output: icon_maker.exe
endlocal
