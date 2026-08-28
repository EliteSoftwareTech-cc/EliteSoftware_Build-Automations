# Changelog

## v1.0.3.0 - 2026-08-28 (Machine-Readable Dual Execution & Unified Error Engine)
### 🤖 Machine Readability & AI Mode
- **Dual Execution Model:** Upgraded all 48 C++ CLI tools and `EliteLogger.h` with dual-mode execution:
  - **User Mode:** Live stdout/stderr console streaming with interactive EULA validation, formatted error messages, and disk logging.
  - **AI Mode (`--ai-mode`):** Completely silent on `stdout` (zero console noise/token waste), full execution traces logged strictly to `%SystemDrive%\EliteSoftware\Logs\<ToolName>.log`, and structured JSON diagnostic payloads emitted to `stderr` on failure.
- **Unified Exit Code Taxonomy:** Codified standard exit codes across all tools (`0` = Success, `10` = Config Missing, `11` = Invalid Args, `12` = File Not Found, `20` = Locked, `30` = Elevation Required, `40` = Dependency Missing, `50` = Env Missing, `60` = Compilation Failed, `70` = Signing Failed, `80` = Network Failed, `90` = Git Failed, `99` = EULA Rejected).
- **Universal C++ Engine:** Standardized all 48 tool entry points to link against `EliteLogger.h` via `EliteInit()`, `EliteLog()`, and `EliteError()`.
- **Workflow & Execution Choreography:** Created `Execution_Order_and_Workflows.md` detailing 5 Directed Acyclic Graphs (DAGs) for full-lifecycle build, code-sign, release, icon generation, repository scaffolding, and system configuration pipelines.
- **Documentation Alignment:** Updated `agent_protocols.md` and `GEMINI.md` to incorporate the complete error taxonomy, dual-mode specifications, and workflow cross-references.

## v1.0.2.0 - 2026-08-28 (Master Pipeline & Logging Paradigm)
### System Purity & Execution Architecture
- **Purged:** Root uild.ps1 script is completely gone. Relying 100% on the native C++ EliteBuild.exe orchestrator and nested system %PATH% variables.
- **Added:** ELITE_COMPILER_PATHS system variable introduced to seamlessly track all required build binaries (gcc.exe, windres.exe, MSBuild.exe, ISCC.exe, signtool.exe) and appended to System/User PATH.
- **Added:** Native Win32 IPC Pipe logging via src/EliteLogger.h. All external compiler and tool output is intercepted in real-time and written to EliteBuild.log in the project root, solving file-lock silent failures and nested execution blindness.
- **Added:** ELITE_IS_CHILD environment variable to prevent duplicate logging cascades from EliteBuild.exe orchestrator.
- **Refactored:** Modified all core master tools (EntryPoint, Compiler, Packager, EasySigner, ProjectBackup) to link against EliteLogger.h and use the native IPC standard.
- **Infrastructure:** Symlinks in BuildOutputx64 now accurately point directly to src/ subdirectories to ensure real-time access to the latest .exe modifications.

- **Documentation:** Created 55 internal GEMINI.md guardrail files across the src/ tree to explicitly guide autonomous agents away from executing master source components and toward the %ELITE_COMPILER_PATHS% System variable. - 2026-08-27 (Architectural Phase Shift)
### System Purity & Execution Architecture
- **Purged:** Recursively deleted uild.ps1 files from all 47 src/ subdirectories. 
- **Added:** Created a root Build_Configurations/ directory serving as the primary configuration host for all master tools.
- **Added:** Generated 47 individual .config JSON files encapsulating all g++ and windres logic for every backend tool.
- **Refactored:** Modified EliteBuild.exe (The Entry Point) to natively parse the Build_Configurations/ directory and execute tools in a pure C++ environment.
- **Refactored:** Root uild.ps1 is now purely a fallback bootstrapper. It only compiles EliteBuild.exe if it doesn't exist, then immediately hands over all control to the C++ orchestrator.
- **Documentation:** Updated 
eadme.md with a detailed step-by-step Quick Start guide explaining the zero-script .config architecture.
- **Infrastructure:** Updated primary Git remote URL to EliteSoftwareTech-cc organization branch.

## v1.0.0.0 (2026-08-26)
### 🚀 New Features
- **EliteBuildChain Framework Inception:** Created the foundational structure for replacing scattered `build.ps1` and `build.bat` files across all EliteSoftware projects.
- **Architecture Defined:** Outlined the compilation, signing, packaging, and publishing stages into `EliteBuildChain_Architecture.md`.
- **Config Schema Implemented:** Created `EliteBuildChain_ConfigSchema.md` to establish the standard layout for `EliteBuild.config` (JSON) configuration files.
- **Source Module Stubs:** Engineered the initial `EliteBuildChain.ps1` pipeline handler that dynamically loads `EliteBuild.config` and executes the configured stages.
- **Output Standardization:** Pre-allocated `x86`, `x64`, and `Prompt_Outputs` root directories per EliteSoftware structural guidelines.









