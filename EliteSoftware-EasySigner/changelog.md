# Changelog

## v1.0.0.0 (2026-08-26)
### 🚀 New Features
- **Project Initialization:** Established standard EliteSoftware repository structure for `EliteSoftware-EasySigner`.
- **Native C++ Architecture:** Engineered `main.cpp` to execute signing logic natively via `signtool.exe`, eliminating the massive PS1 WinForms overhead.
- **Resource Embedding:** Utilized `resources.rc` and `windres` to permanently embed `EliteSoftware_Special.pfx` and `signtool.exe` directly inside the executable.
- **Fail-Safe Signing Logic:** Added automated fallback from Method A (SHA256) to Legacy Method (SHA1). Added strict zero-exit-code logic to ensure build pipelines don't halt if signing fails entirely.
- **Compiler Configuration:** Configured `build.ps1` to leverage `g++` and `windres` (MinGW) to package the logic into native Windows executables (`x86`/`x64`).
