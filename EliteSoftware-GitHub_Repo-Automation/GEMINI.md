# 🧠 GEMINI.md - EliteSoftware-GitHub_Repo-Automation

## 🚨 Local Project Architectural Rules

This repository component handles **Git and GitHub orchestration**.

### 1. Toolchain Purpose
- Provide a unified `.exe` capable of generating repositories, auto-committing, and drafting rich multi-architecture GitHub releases.
- Act as a standalone bridge until the master `EliteBuild_Publisher_CLI` is fully adopted across the ecosystem.

### 2. Compilation Rules
- All source scripts in `EliteSoftware-GitHub_Repo-Automation_CLI` are written in **C++ native code**.
- They must be compiled using `g++` via the local `build.ps1`.
- Outputs must route cleanly into `x86/` and `x64/` directories.

### 3. Agent Navigation
- See `EliteSoftware-GitHub_Repo-Automation_CLI/main.cpp` for the core C++ logic handling `git` and `gh` execution.

### 4. Logging and Aesthetics
- Ensure the master GUI / CLI logs out in the classic EliteSoftware witty tone.
- All prompt outputs generated during development in this folder MUST be logged into `Prompt_Outputs/` as per the global rule.
