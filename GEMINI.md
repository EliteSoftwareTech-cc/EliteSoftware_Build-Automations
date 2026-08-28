# 🧠 GEMINI.md - EliteBuildChain 

## 🚨 Local Project Architectural Rules

This repository (`EliteSoftware_Build-Automations`) holds the **master build tools** that will be compiled and distributed to all other EliteSoftware projects.

### 1. Toolchain Purpose
- Never write hardcoded build parameters in PowerShell scripts within this repo.
- The overarching goal of this repo is to produce generic, config-driven CLI tools (`EliteBuildChain.exe`) that can ingest `.config` files and orchestrate builds dynamically.
- The ultimate output of this repo must be highly portable standalone `.exe` binaries (either written in C++ or PS2EXE).

### 2. Compilation Rules
- All tools generated here must output to the `x86/` and `x64/` directories at the project root.
- All code logic must remain generic. E.g., when signing, do not hardcode the certificate path in the code. It must be read from the parsed `.config` file. The only exception is falling back to standard OS-level SDK directories (`C:\Program Files (x86)\Windows Kits\...`) for `signtool.exe` or `MSBuild.exe`.

### 3. Agent Navigation
- Reference `Migration_Mapping.md` to see what legacy scripts we are actively studying and replacing.
- Reference `EliteBuildChain_Architecture.md` for the overarching vision of this project.
- Reference `EliteBuildChain_ConfigSchema.md` for the unified `.config` structure we expect other projects to use.

### 4. Logging and Aesthetics
- Ensure the master GUI / CLI logs out in the classic EliteSoftware witty tone.
- If we build a WinForms UI for the build chain later, it MUST adhere strictly to the `user_global` UI guidelines (Classic 3D inset, Title Banner, Frutiger Aero).
- All prompt outputs generated during development in this folder MUST be logged into `Documentation/Prompt_Outputs/` as per the updated local rule.

### 5. The C++ CLI Design Premise (Core Framework Rule)
All new components and standalone CLI tools built for this framework MUST adhere to the following strict guidelines:
- **Native C++ Codebase:** Tools must be written in C++ (avoiding `PS2EXE` wrappers where possible). DLL dependencies are permitted if absolutely necessary.
- **Project Awareness (Smart Defaults):** Tools must automatically infer context (e.g., pulling the repository name from the current working directory) to minimize required arguments.
- **Argument-Driven Overrides:** Every project-specific command, string, or action that would normally be hardcoded must become an argument so the tool is 100% reusable across any project.
- **Dedicated Component Documentation:** Every individual component must have its own `.md` file located at its root outlining its specific CLI features and parameters.
- **Universal Help System:** Every tool and subcommand must implement robust help flag parsing responding to `/help`, `//help`, `-help`, `--help`, `-?`, and `--?`.

### ⚙️ Environment Variables, Logging & Global Access

### 📚 Documentation Bifurcation (Critical Cross-References)
This project maintains a strict separation between human-facing and machine-facing documentation:
- **`architecture_decisions.md`**: Engineering philosophy, design history, and rationale. For human developers.
- **`agent_protocols.md`**: Strictly structured, zero-humor, machine-readable execution schemas and parameter specs. For AI agents.
- **`Execution_Order_and_Workflows.md`**: Directed Acyclic Graphs (DAGs), pipeline ordering, and dual execution model documentation.
- **`EliteSoftware_MCP_Architecture.md`**: The Domain-Multiplexed Architecture vision and roadmap.

### 🔒 Execution Environment (DEFINITIVE STANDARD)
**The global PATH injection via `EliteSoftware-EnvManager_GUI.exe` is the STANDARD operating mode.**

All compiled tools reside in a single canonical binary vault:
- **64-bit:** `Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\BuildOutputx64\`
- **32-bit:** `Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\BuildOutputx86\`

These paths are permanently injected into the System `%PATH%` via the Environment Manager GUI. Tools are callable headlessly from any terminal, any directory, without initialization scripts.

> **⚠️ DEPRECATED:** The earlier session-isolated `EliteEnv.cmd` approach is deprecated. It is preserved ONLY as a portable-mode fallback for air-gapped systems. It is NOT the standard execution context. Agents must NEVER source `EliteEnv.cmd` unless explicitly instructed by a human operator.

#### System Environment Variables
| Variable | Purpose |
|---|---|
| `ELITE_BUILD_X64` | Semicolon-delimited list of absolute paths to each 64-bit compiled EXE |
| `ELITE_BUILD_X86` | Semicolon-delimited list of absolute paths to each 32-bit compiled EXE |
| `ELITE_COMPILER_PATHS` | Semicolon-delimited map of third-party build tools (`gcc.exe`, `MSBuild.exe`, `ISCC.exe`, `signtool.exe`) |
| `ELITE_IS_CHILD` | Set by parent orchestrators to prevent double-logging cascades in child processes |

### EliteLogger.h (Native Win32 Pipe IPC)
All C++ CLI tools natively include `src\EliteLogger.h`. This intercepts all `stdout` and `stderr` from external processes using Win32 Anonymous Pipes and streams output directly to a centralized `EliteBuild.log` file.

### 🤖 LLM Autonomous Execution (`--ai-mode`)
**MANDATORY for all headless agent invocations.** This flag:
- Bypasses the interactive EULA confirmation prompt
- Suppresses all `Press any key to continue...` pauses
- Forces strict exit code returns instead of interactive error dialogs
- Updates the terminal title to `(Ai Mode)` while the process runs

Agents must ALWAYS pass `--ai-mode` when executing any EliteSoftware C++ CLI tool.

## 🧰 Integrated Master Tools & Utilities (Agent Reference Guide)

This section serves as a comprehensive reference for AI agents interacting with the EliteSoftware Master Tools suite. These tools are natively integrated into the EliteSoftware_Build-Automations framework and must be utilized to maintain system purity.

### ⚙️ Master Tool Environment Variables & Execution Rules
The master tools have been aggregated and compiled directly into the root BuildOutputx64 and BuildOutputx86 folders.

- **ELITE_BUILD_X64 & ELITE_BUILD_X86**: 
  - These are **System and User Environment Variables** that contain a **semicolon-delimited list of absolute paths** to each individual executable (e.g., Z:\...\BuildOutputx64\FileSplitter.exe;Z:\...\BuildOutputx64\icon_maker.exe).
  - You can parse these variables in PowerShell using $env:ELITE_BUILD_X64 -split ';' to programmatically locate a specific binary.
  - Additionally, both variables have been injected into the system %PATH%. This means you can invoke these tools *headlessly by name* from any directory (e.g., executing icon_maker.exe directly).

- **The --ai-mode Flag**:
  - Most native C++ CLI tools in this suite (like EliteEasySigner.exe, EliteBuild.exe) require the --ai-mode argument when executed by an LLM agent. This flag bypasses mandatory EULA confirmation prompts and prevents terminal deadlocks.

### 1. File Splitter For AI Upload
- **Intent**: Safely splitting massive text, log, or source code files into chunked .txt files without breaking CR/LF boundaries. Crucial for overcoming LLM context window limits.
- **Location / File Structure**: Source is in src\FileSplitter_GUI. Executable is FileSplitter.exe (x64/x86).
- **Usage for Agents**: Currently a GUI-centric tool. If required to execute programmatically, verify if it accepts CLI arguments, otherwise invoke via UI automation or stick to standard powershell chunking for background tasks.
- **Arguments**: N/A (GUI Tool).

### 2. Icon Image Management CLI Tool
- **Intent**: Pragmatically convert images (PNG, JPG, BMP, etc.) into high-quality multi-resolution .ico icon containers, OR perform batch extraction of all embedded RT_BITMAP/RT_ICON payloads from PE binaries (.exe, .dll).
- **Location / File Structure**: Source is in src\IconManager_CLI. Executable is icon_maker.exe.
- **Usage for Agents**: Native C++ Win32 execution. Highly recommended for all icon generation tasks. 
- **Arguments**: icon_maker.exe <input_file(s)> [output_file] [options]
  - <input_file>: Path to image or PE binary. If it's a PE binary and output_file is omitted, it extracts ALL icons into a subfolder.
  - --remove-halo: Strips magenta/pink background colors (classic transparency key).
  - --remove-bg: Smart background flood-fill removal.

### 3. Ico To Png Converter
- **Intent**: Lightweight utility to extract every resolution frame embedded within an .ico file and explode them into separate .png files inside a Converted_PNGs subdirectory.
- **Location / File Structure**: Source is in src\IcoToPngConverter_CLI. Executable is IcoToPngConverter.exe.
- **Usage for Agents**: Execute to break down multi-res icons into verifiable PNGs. 
- **Arguments**: IcoToPngConverter.exe <file.ico>

### 4. PsExec64 Launcher
- **Intent**: A WinForms wrapper for PsExec64.exe designed to solve UIPI (User Interface Privilege Isolation) issues. It runs unelevated to preserve drag-and-drop mechanics but executes payloads with NT AUTHORITY\SYSTEM or other elevated tokens.
- **Location / File Structure**: Source is in src\PsExec64Launcher_GUI. Executables are PsExec64-Launcher_x64.exe and PsExec64-Launcher_x86.exe.
- **Usage for Agents**: Useful for configuring system-level execution shortcuts.

### 5. Resource Alchemy Hacker
- **Intent**: A native C++ Win32 PE resource editor and extractor. Replaces classic tools to offer high-performance modification of RT_ICON, RT_STRING, RT_DIALOG, and RT_VERSION blocks inside Windows binaries.
- **Location / File Structure**: Source is split across src\ResourceAlchemyHacker_GUI, src\ResourceAlchemyHacker_CLI, and src\ResourceAlchemyHacker_ShellExt. The backend executables are ResourceAlchemyHacker_CLI.exe and ResourceAlchemyHacker_ShellExt.dll.
- **Usage for Agents**: Use the CLI backend (ResourceAlchemyHacker_CLI.exe) to programmatically inject or extract .ico resources or manifest strings from compiled .exe or .dll files without breaking their structural integrity.

### 6. CLSID / GUID Generator
- **Intent**: Lightweight utility to generate unique CLSIDs, store them in a local clsid_database.txt, and cross-reference with the Windows Registry (HKCR\CLSID) to ensure they aren't already in use.
- **Location / File Structure**: Source is in src\EliteSoftware-CLSIDGenerator. Executable is EliteCLSIDGenerator.exe.
- **Usage for Agents**: Provide --name <program> to generate and log a GUID.

### 7. Smart Drop Handler (DLL/PE Register)
- **Intent**: Automatically detects whether a dropped PE/DLL file is 32-bit or 64-bit and routes it to the correct 
egsvr32.exe (SysWOW64 for 32-bit, System32 for 64-bit).
- **Location / File Structure**: Source is in src\EliteSoftware-SmartRegsvr. Executable is EliteSmartRegsvr.exe.
- **Usage for Agents**: Pass --file <path> to automatically register the DLL.

### 8. Inno Setup Creator
- **Intent**: Hosts 3 default installation templates (Basic EXE, DLL Service, Full Suite) and acts as a wrapper for ISCC.exe to quickly generate and compile Inno Setup installers.
- **Location / File Structure**: Source is in src\EliteSoftware-InnoCreator. Executable is EliteInnoCreator.exe.
- **Usage for Agents**: Use --generate --template <1|2|3> --out <path.iss> to generate, or --compile <path.iss> [args] to compile.

### 9. EliteBuild (The Orchestrator)
- **Intent**: Orchestrator that natively reads the %ELITE_BUILD_X64% variable array, iterates through .config files within the Build_Configurations directory, locates the backend tools, and executes them based on the configuration logic. Entirely eliminates the need for any nested uild.ps1 scripts in project repositories.
- **Location / File Structure**: Source is in src\EliteSoftware-EntryPoint. Executable is EliteBuild.exe.
- **Usage for Agents**: Drop a copy of EliteBuild.exe (or use a symlink) in the repo root. Ensure your .config files are inside the Build_Configurations folder. Run EliteBuild.exe --ai-mode to selectively invoke the native C++ build chain based on those configs.

**Note on Interactive Mode**: All C++ CLI tools in this suite now feature an interactive console fallback mode. If executed directly (e.g., via double-click) without arguments, they will pause and prompt the user for the missing inputs. To suppress this behavior and run headlessly, agents MUST pass the --ai-mode argument.

## Safe File Deletion Protocol
- **Rule:** ALL file deletions performed by agents MUST utilize the Windows Recycle Bin (or equivalent safe-trash mechanism) instead of permanent deletion, UNLESS the file is too large to fit in the recycle bin.

### 10. RC/RES Manager
- **Intent**: Automates .rc (Resource Script) generation and acts as a direct wrapper for windres.exe to compile them into .res objects.
- **Location / File Structure**: Source is in src\EliteSoftware-RCManager. Executable is EliteRCManager.exe.
- **Usage for Agents**: Provide --rc <out.rc> --res <out.res> --icon <icon.ico> to generate and compile.

### 11. Smart Icon Replacer & PE Rebuilder
- **Intent**: Direct replacement of the Main Application Icon (RT_GROUP_ICON) inside a compiled executable, immediately followed by a PE Checksum Recalculation (Rebase) using imagehlp.dll. This ensures the .exe remains structurally valid and ready for Authenticode signing.
- **Location / File Structure**: Source is in src\EliteSoftware-IconReplacer. Executable is EliteIconReplacer.exe.
- **Usage for Agents**: Pass --exe <target.exe> --icon <source.ico> to inject the new icon and repair the checksum.

## 🛡️ File Access Protocol (The Symlink Rule)
- **Rule:** When AI agents need to utilize or interact with files, scripts, or assets located in other directories or projects, you MUST use EliteSymlinker.exe to create a symbolic link or hard link instead of moving (Copy-Item / Move-Item) the files. 
- **Why:** This guarantees you are always referencing the absolute latest master version of the file across the system and entirely eliminates the risk of accidentally moving or deleting the original source files.

## 📜 State Ledger Protocol (Documentation Integrity)
- **Rule:** Autonomous agents are strictly PROHIBITED from utilizing destructive file writes on documentation files (`.md`, `.txt`, architectural logs). Always APPEND, never overwrite.
- **Rule:** Every structural change or manual override of tool settings must be appended to the master ledger with a strict **What / How / Why** schema, ensuring the next spawned agent reads the chronological history before executing.
- **Rule:** If an agent must modify an existing architectural decision, it must append a dated entry explaining the change, preserving the original text above for audit trail purposes.

## 🤖 Agent-Specific Documentation
For strictly machine-readable execution schemas, JSON parameter definitions, exit code taxonomy, and workflow DAG mappings, agents must reference:
- **`agent_protocols.md`** — The zero-humor, zero-narrative operational manual for autonomous AI execution.
- **`architecture_decisions.md`** — The engineering philosophy and design rationale (human-readable context).
