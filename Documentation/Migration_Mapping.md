<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware Migration Mapping & Reference Paths

**Information-First Engineering. Absolute System Purity.**

This document details the exact legacy scripts across the EliteSoftware ecosystem that are scheduled for replacement by the `EliteBuildChain.exe` tool, alongside their respective reference paths and logic. 

## 🗃️ Legacy Component References

The new toolchain extracts logic directly from these legacy monolithic scripts.

### 1. `ResourceAlchemyHacker`
* **Reference Path:** `C:\Users\Administrator\Desktop\ResourceAlchemyHacker\build.ps1`
* **Reference Path:** `C:\Users\Administrator\Desktop\ResourceAlchemyHacker\Scripts\publish_release.ps1`
* **Extracted Logic for Templates:**
  - Standard MSBuild execution with `$LASTEXITCODE` checking.
  - Multi-architecture parallel building (`x86`, `x64`).
  - Signtool invocation targeting `Elite-EasySigner\EliteSoftware_Special.pfx`.
  - InnoSetup 6 dynamic variable replacement via string injection (`Installer\setup.iss`).
  - GitHub Release creation (`gh release create`) utilizing ZIPs and `changelog.md` extraction.

### 2. `Elite-TaskBar`
* **Reference Path:** `C:\Users\Administrator\Desktop\Elite-TaskBar\build.ps1`
* **Reference Path:** `C:\Users\Administrator\Desktop\Elite-TaskBar\Scripts\build_x64.ps1`
* **Extracted Logic for Templates:**
  - File locking (`elite_taskbar_build_v2.lock`) to prevent concurrent agent corruption.
  - Pre-build process termination via WMI and `Stop-Process` (`EliteTaskbar`, `EliteSettings`).
  - MSVC `VsDevCmd.bat` environment bootstrapping.
  - Icon synchronization mechanisms (`MAIN_PROGRAM.ico` syncing).
  - Multi-repository submodule auto-committing.

### 3. `Local_APK_Store`
* **Reference Path:** `C:\Users\Administrator\Desktop\Local_APK_Store\publish_release.ps1`
* **Reference Path:** `C:\Users\Administrator\Desktop\Local_APK_Store\Manager_App\build.bat`
* **Extracted Logic for Templates:**
  - Simple `.bat` MSBuild executions that should be natively integrated into the `Compiler` module.
  - Android APK client-side packaging nuances (to be abstracted into `Packager`).

### 4. `File_Splitter_ForAI-Upload`
* **Reference Path:** `C:\Users\Administrator\Desktop\File_Splitter_ForAI-Upload\Build.ps1`
* **Extracted Logic for Templates:**
  - Single executable compilation pipelines.

### 5. Various Run_Program Applets
* **Reference Paths:** 
  - `C:\Users\Administrator\Desktop\Run_Program\AddHardware\build.bat`
  - `C:\Users\Administrator\Desktop\Run_Program\DirectXDiag\build.bat`
  - `C:\Users\Administrator\Desktop\Run_Program\SystemProperties\build.bat`
* **Extracted Logic for Templates:**
  - These 15+ micro-components currently rely on duplicated `build.bat` files.
  - **Migration Plan:** A single `EliteBuild.config` placed in each subfolder will allow the unified `EliteBuildChain.exe` to recursively scan and compile all applets effortlessly.

### 6. `HostsURL_Redirector`
* **Reference Path:** `Z:\HostsURL_Redirector\cpp\build.bat`
* **Extracted Logic for Templates:**
  - Reliance on MinGW tools (`g++` and `windres`) rather than MSBuild.
  - Native C++ dynamic link library (.dll) and executable (.exe) compilation with specific linker flags (`-mwindows`, `-lcomctl32`, etc.).
  - **Migration Plan:** The new `EliteBuild_Compiler` tool has been extended to parse a `GccTargets` JSON array from the config, natively invoking `g++` and `windres` without needing custom batch scripts.

### 7. Additional Mentioned Repositories
* **Reference Paths:**
  - `C:\Users\Administrator\Desktop\Agent-Thread_HTML_Template`
  - `Z:\EliteSoftware-Projects\Agent-Thread_HTML_Template`
  - `C:\Users\Administrator\Desktop\ClipboardImage-Management`
  - `C:\Users\Administrator\Desktop\IconExplorer_ShellExtension`
  - `C:\Users\Administrator\Desktop\Kill-Explorer Project`
  - `C:\Users\Administrator\Desktop\PsExec64-Launcher`
* **Extracted Logic for Templates:**
  - Standardization of project structures.
  - Ensuring the toolchain correctly accounts for unique build behaviors (like Shell Extensions, Launchers, and HTML template generation) via custom config hooks.

---

## 🚀 Application to the Elite Ecosystem

To apply this to **any** of the aforementioned tools, simply delete their existing `build.ps1` or `build.bat` scripts and replace them with:
1. `EliteBuild.config` (refer to the `EliteBuildChain_ConfigSchema.md`)
2. Execute the appropriate tool (`EliteBuild_Compiler.exe`, `EliteBuild_Signer.exe`, `EliteBuild_Packager.exe`, `EliteBuild_Publisher.exe`) from the root as needed, or chain them together via a simple pipeline script.

By adopting this multi-exe modular architecture, agentic AI will simply modify the JSON/INI config instead of fighting with 300+ line PowerShell scripts when adding new build outputs, and the root directories remain clean.
