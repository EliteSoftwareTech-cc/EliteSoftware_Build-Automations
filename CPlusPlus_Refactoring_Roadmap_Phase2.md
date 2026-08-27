# 🗺️ C++ Refactoring Roadmap: Phase 2

After extensively scanning the Z:\EliteSoftware-Projects\EliteSoftware-ScriptTools-Archive\PowerShell-Script_Archive and diving into the archives at S:\Projects, I've identified the next wave of critical EliteSoftware tools for native C++ compilation. 

This phase focuses on environment deployment, shell integrations, and high-performance user utilities.

## The Core Expansion List

1. **EliteADBManager.exe (formerly Elite-ADB-FastBoot.PS1)**
   - **Purpose:** A lightweight wrapper for db and astboot that natively handles Android bridge commands without requiring a full Android Studio install.
   - **C++ Advantage:** Lightning-fast execution and native USB device polling via Win32.

2. **EliteNetworkManager.exe (formerly EliteSoftware-NetworkManager.PS1)**
   - **Purpose:** Manages routing, static IP assignment, and DNS flushed across all adapters.
   - **C++ Advantage:** Wraps iphlpapi.lib directly to bypass standard 
etsh delays and strict execution policies.

3. **EliteClipSaver.exe (formerly Background-Screenshot-Saver.PS1 & ClipboardImageMover.PS1)**
   - **Purpose:** A background daemon that hooks the clipboard (SetClipboardViewer) and instantly dumps screenshots/images to a timestamped file in a designated folder.
   - **C++ Advantage:** Microscopic RAM footprint for a background daemon compared to a persistent PowerShell runspace.

4. **EliteProfileManager.exe (formerly EliteSoftware PowerShell Profile Manager.PS1)**
   - **Purpose:** Bootstraps new workstations by injecting EliteSoftware aliases, modules, and prompt customizations into $PROFILE.
   - **C++ Advantage:** Can deploy instantly across multiple users and modify system-wide profiles without needing elevation if writing to HKCU.

5. **EliteRepoCloner.exe (formerly Clone-MissingRepos.ps1)**
   - **Purpose:** Iterates through a master configuration file and ensures all standard EliteSoftware GitHub repositories are cloned and up-to-date in Z:\EliteSoftware-Projects.
   - **C++ Advantage:** Can spawn multi-threaded git processes via CreateProcess to clone 10+ repos simultaneously, drastically cutting setup time.

6. **EliteWin7Enabler.exe (formerly ESU-Win7-ENABLER.PS1)**
   - **Purpose:** Unlocks Extended Security Updates logic and bypasses telemetry restrictions on legacy workstations.
   - **C++ Advantage:** Directly patches registry keys (RegSetValueEx) and forces policy updates at the kernel level.

7. **EliteExecPolToggle.exe (formerly ExecPolToggle.exe / BedrockArchitect.ps1)**
   - **Purpose:** Instantly bypasses ExecutionPolicy for specific processes or globally unlocks PowerShell script execution for development.
   - **C++ Advantage:** Operates seamlessly out of %PATH% for quick environment prep.

## Special Addition: EliteDevServer.exe
- **Purpose:** A blazing-fast local HTTP/HTTPS server for testing static sites and bypassing local CORS restrictions.
- **Features:** 
  - Dynamic Port Allocation (increments by 2).
  - Self-Signed SSL integration.
  - Drag-and-drop support: drag an .html file onto the .exe to instantly serve that directory, copy the localhost URL, and open it in the default browser.
- **Status:** **[COMPLETED]** - Already compiled using our newly built ElitePSWrapper.exe!
