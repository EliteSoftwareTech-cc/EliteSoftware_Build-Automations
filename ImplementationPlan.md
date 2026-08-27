# 🔮 Upcoming Features & Implementation Plan

This document serves as the roadmap for future enhancements and planned architectural upgrades to the EliteSoftware Master Toolchain.

## 1. Global Shared Icon Library (DLL)
- **Goal:** Rather than baking redundant .ico files directly into every single C++ .exe executable, we will build a monolithic shared EliteIcons.dll containing all standard graphical assets.
- **Execution:**
  - Update all CLI tools (EliteCLSIDGenerator, icon_maker, etc.) to intercept application launch.
  - Check if EliteIcons.dll is present in the %ELITE_BUILD_X64% directory.
  - Dynamically load the correct window and taskbar icons from the DLL using LoadImage() and LoadLibrary().
  - **Fallback Logic:** If the DLL is missing, the executables will fallback to using their embedded (placeholder) icons to ensure they don't crash.
- **Status:** *Planned*

## 2. Advanced Environment Synchronization
- **Goal:** Allow the EliteBuild.exe Entry Point to not only check for outdated tools locally (as introduced in v1), but automatically copy the newer tools from the %ELITE_BUILD_X64% directory over itself or the local directory.
- **Status:** *Planned*

## 3. Web-Interface Integration (Agent-Thread HTML)
- **Goal:** Finalize the web-socket backend for Start-AgentThreadServer.exe to allow real-time browser viewing of agent pipelines, workflow history, and artifact generation.
- **Status:** *In Progress*

