<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware Universal Build Toolchain (EliteBuildChain)

**Information-First Engineering. Absolute System Purity.**

This document outlines the architecture for migrating from decentralized, hardcoded PowerShell scripts (e.g., `build.ps1`, `publish_release.ps1`) to a unified, high-performance CLI toolchain driven by configuration files.

## 🔍 Investigation Findings
By analyzing existing projects, we identified the following common build steps scattered across multiple scripts:

1. **Pre-Build Setup:** Process killing, file locking, and version bumping (e.g., `C:\Users\Administrator\Desktop\Elite-TaskBar\build.ps1`).
2. **Compilation:** Invoking MSBuild for x86 and x64 architectures across multiple sub-components and submodules.
3. **Signing:** Code signing using `signtool.exe` with the EliteSoftware PFX certificate (`C:\Users\Administrator\Desktop\ResourceAlchemyHacker\build.ps1`).
4. **Packaging & Documentation:** Generating PDFs via Supermium, creating Inno Setup installers, and zipping final binaries (`C:\Users\Administrator\Desktop\ResourceAlchemyHacker\Scripts\publish_release.ps1`).
5. **Git & Release Publishing:** Auto-committing submodules, pushing to the master branch, parsing `changelog.md` for release notes, and creating GitHub releases via `gh`.

## 🛠️ The New Framework Architecture

Instead of duplicating logic, we will build a modular suite of CLI tools (or one unified `EliteBuild.exe` with subcommands) compiled to native executables (C++ or PS2EXE). 

### Core Features
- **Config-Driven:** Each tool automatically looks for `<ToolName>.config` (or a master `EliteBuild.config`) in its directory.
- **Argument Override:** Arguments can be passed via CLI, but if missing, the `.config` provides defaults, eliminating interactive prompts.
- **Standardized Output:** All tools output to the root `x86` and `x64` directories.

### Component Toolchain Concept

#### 1. `EliteBuild_Compiler.exe`
- **Function:** Handles file locking, kills active processes, reads `.sln` paths from config, and invokes MSBuild for both x86 and x64.
- **Config Fields:** `SlnPaths`, `KillProcesses`, `PreBuildScripts`

#### 2. `EliteBuild_Signer.exe`
- **Function:** Automatically locates Windows SDK `signtool.exe`, reads the certificate path and password from config, and signs designated output directories.
- **Config Fields:** `PfxPath`, `PfxPassword`, `SignTargets`

#### 3. `EliteBuild_Packager.exe`
- **Function:** Compiles Markdown to HTML and PDFs using Supermium, builds InnoSetup scripts (`.iss`), and creates architecture-specific `.zip` archives.
- **Config Fields:** `DocsSource`, `InnoSetupScript`, `ZipTargets`

#### 4. `EliteBuild_Publisher.exe`
- **Function:** Parses the latest version from `version.h` or `changelog.md`, constructs release notes, auto-commits any local changes, pushes to the remote, and publishes a `gh release`.
- **Config Fields:** `GitAutoCommit`, `ReleaseTitleTemplate`, `ArtifactsToUpload`

## 📁 Project Structure (For This Toolchain)

```text
Z:\EliteSoftware-Projects\EliteSoftware_Build-Automations\
|-- x86/                         # Compiled 32-bit toolchain outputs
|-- x64/                         # Compiled 64-bit toolchain outputs
|-- Prompt_Outputs/              # Mandatory LLM conversation logging
|-- src/
    |-- EliteBuild_Compiler_CLI/ # Source for Compiler CLI tool
    |-- EliteBuild_Signer_CLI/   # Source for Signer CLI tool
    |-- EliteBuild_Packager_CLI/ # Source for Packager CLI tool
    |-- EliteBuild_Publisher_CLI/# Source for Publisher CLI tool
|-- readme.md                    
|-- changelog.md                 
```

## 🚀 Next Steps
We will begin by scaffolding the source directories for each CLI component and writing the foundational logic (either in C++ or robust PowerShell that we will compile to EXE using PS2EXE) that reads from the `.config` files.
