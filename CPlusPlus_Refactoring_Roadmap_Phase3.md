# 🗺️ C++ Refactoring Roadmap: Phase 3

We have completely exhausted Phase 1 and Phase 2. Moving deeper into the archives (S:\Projects and the PowerShell-Script_Archive), I have identified the next set of mission-critical scripts that require the native C++ EliteSoftware treatment.

This phase focuses on system resilience, advanced telemetry, and rapid environment bootstrapping.

## The Core Expansion List

1. **EliteSystemRestore.exe (formerly CustomSystemRestore.PS1)**
   - **Purpose:** Natively creates Windows System Restore points.
   - **C++ Advantage:** Directly hooks srclient.dll and SRSetRestorePointW for lightning-fast, silent system state snapshots before destructive automated builds.

2. **EliteFolderScanner.exe (formerly EliteSoftware Folder & Duplicate Scanner.PS1)**
   - **Purpose:** Advanced native directory scanning and metrics.
   - **C++ Advantage:** Utilizes native Win32 FindFirstFile/FindNextFile for blazing fast recursive directory traversal and space calculations, far surpassing PowerShell Get-ChildItem overhead.

3. **EliteDotNetEnv.exe (formerly DotNet Environment Manager.PS1)**
   - **Purpose:** Analyzes and provisions the .NET Framework ecosystem.
   - **C++ Advantage:** Natively queries HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP to dynamically map installed frameworks and execute targeted headless installers.

4. **EliteVSBuildTools.exe (formerly Install-VisualStudio-BuildTools.PS1)**
   - **Purpose:** Headless bootstrapper for MSVC build tools.
   - **C++ Advantage:** Standardizes the C++ compilation environment identically across all EliteSoftware machines without relying on sluggish PS gallery modules.

5. **EliteOptiLink.exe (formerly OptiLink Instant Messenger.PS1)**
   - **Purpose:** Local IPC / LAN Messaging.
   - **C++ Advantage:** Upgrades the slow PowerShell script into a blazing fast winsock2 and Named Pipe daemon for instant agent-to-agent or terminal-to-terminal communication on the LAN.
