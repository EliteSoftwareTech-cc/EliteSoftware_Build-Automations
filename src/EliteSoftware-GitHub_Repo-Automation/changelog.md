# Changelog

## v1.0.0.0 (2026-08-26)
### 🚀 New Features
- **Project Initialization:** Established standard EliteSoftware repository structure for `EliteSoftware-GitHub_Repo-Automation`.
- **Native C++ Architecture:** Engineered `main.cpp` providing robust native execution via standard system calls, eliminating PS2EXE overhead.
- **CLI Development:** Supports `init`, `commit`, and `release` subcommands parsed natively via `argv`.
- **Privacy by Default:** Enforced default `--private` flags on remote repository creation via `gh`.
- **Compiler Configuration:** Configured `build.ps1` to leverage `g++` (MinGW) to package logic into native Windows executables (`x86`/`x64`).
