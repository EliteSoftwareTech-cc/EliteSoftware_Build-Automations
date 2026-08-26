# 🧠 GEMINI.md - EliteSoftware-EasySigner

## 🚨 Local Project Architectural Rules

This repository component handles **Authenticode File Signing**.

### 1. Toolchain Purpose
- Provide a unified `.exe` capable of securely extracting and executing `signtool.exe` using an embedded `EliteSoftware_Special.pfx` payload.
- Act as a seamless module inside the overarching `EliteBuildChain` ecosystem.

### 2. Compilation Rules
- All source scripts in `EliteSoftware-EasySigner` are written in **C++ native code**.
- They must be compiled using `g++` and `windres` via the local `build.ps1`.
- Outputs must route cleanly into `x86/` and `x64/` directories.

### 3. Agent Navigation
- See `main.cpp` for the core C++ signing logic and fallback procedures (Method A / Legacy Method).
- See `resources.rc` for how the binary payloads are integrated at compile-time.

### 4. Logging and Aesthetics
- Ensure the master GUI / CLI logs out in the classic EliteSoftware witty tone.
- All prompt outputs generated during development in this folder MUST be logged into `Prompt_Outputs/` as per the global rule.
