# Changelog

## v1.0.1.0 - 2026-08-27 (Architectural Phase Shift)
### System Purity & Execution Architecture
- **Purged:** Recursively deleted uild.ps1 files from all 47 src/ subdirectories. 
- **Added:** Created a root Build_Configurations/ directory serving as the primary configuration host for all master tools.
- **Added:** Generated 47 individual .config JSON files encapsulating all g++ and windres logic for every backend tool.
- **Refactored:** Modified EliteBuild.exe (The Entry Point) to natively parse the Build_Configurations/ directory and execute tools in a pure C++ environment.
- **Refactored:** Root uild.ps1 is now purely a fallback bootstrapper. It only compiles EliteBuild.exe if it doesn't exist, then immediately hands over all control to the C++ orchestrator.
- **Documentation:** Updated eadme.md with a detailed step-by-step Quick Start guide explaining the zero-script .config architecture.
- **Infrastructure:** Updated primary Git remote URL to EliteSoftwareTech-cc organization branch.

## v1.0.0.0 (2026-08-26)
### 🚀 New Features
- **EliteBuildChain Framework Inception:** Created the foundational structure for replacing scattered `build.ps1` and `build.bat` files across all EliteSoftware projects.
- **Architecture Defined:** Outlined the compilation, signing, packaging, and publishing stages into `EliteBuildChain_Architecture.md`.
- **Config Schema Implemented:** Created `EliteBuildChain_ConfigSchema.md` to establish the standard layout for `EliteBuild.config` (JSON) configuration files.
- **Source Module Stubs:** Engineered the initial `EliteBuildChain.ps1` pipeline handler that dynamically loads `EliteBuild.config` and executes the configured stages.
- **Output Standardization:** Pre-allocated `x86`, `x64`, and `Prompt_Outputs` root directories per EliteSoftware structural guidelines.

