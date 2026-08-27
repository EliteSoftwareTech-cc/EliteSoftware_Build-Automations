# 📚 EliteSoftware Master Tool Catalogue

Welcome to the definitive catalogue of the **EliteSoftware Master Build Automations Suite**. 
This page serves as a comprehensive index of all Elite*.exe and legacy C++ tools available within our highly optimized, native Win32 framework.

Each tool here was forged with the EliteSoftware standard: zero bloat, high performance, and absolute system purity. 
All CLI tools natively support the --ai-mode argument for headless automation.

---

### 🌐 System Environment & Integrations

**EliteEnvManager.exe**
- **Purpose:** Natively handles Windows Environment Variables (%PATH%, custom variables). 
- **Features:** Appends, sets, or removes entries and immediately broadcasts a WM_SETTINGCHANGE message. No more rebooting to apply environment variable updates!

**EliteHostConfigurator.exe**
- **Purpose:** Headless manager for %WINDIR%\System32\drivers\etc\hosts.
- **Features:** Injects mappings (--domain localhost --ip 127.0.0.1) or instantly strips them.

**EliteNetworkManager.exe**
- **Purpose:** Next-generation wrapper for IP/DNS handling.
- **Features:** Fast-flushes DNS, assigns static routing, and manipulates adapters without the slow overhead of traditional 
etsh invocation.

**EliteExecPolToggle.exe**
- **Purpose:** Powershell Execution Policy bypasser.
- **Features:** Instantly flips HKLM (or HKCU if non-elevated) registry keys to Bypass to unlock workstation automation layers.

**EliteWin7Enabler.exe**
- **Purpose:** A legacy lifeline.
- **Features:** Unlocks Extended Security Updates (ESU) logic on Windows 7 machines by patching registry and policy flags.

---

### 🔧 Build Chain Orchestration

**EliteBuild.exe (The Entry Point)**
- **Purpose:** The master orchestrator.
- **Features:** Reads EliteBuild.config files, searches system arrays (%ELITE_BUILD_X64%), and seamlessly streams execution to other backend components below.

**EliteCompiler.exe / ElitePackager.exe**
- **Purpose:** Heavy-duty backend wrappers.
- **Features:** Bridges .ps1 to executable formats or handles CI/CD GitHub release logic dynamically via configuration files instead of hardcoded paths.

**EliteVersionBumper.exe**
- **Purpose:** Continuous Integration version tracker.
- **Features:** Scans changelog.md and ersion.h, parses Semantic Versioning (1.0.0.0), and automatically increments Major, Minor, Feature, or Bugfix arguments.

**EliteReadmeGenerator.exe**
- **Purpose:** Document scaffolding engine.
- **Features:** Hosts 5 hardcoded Markdown templates tailored for various architectures (e.g. Master Hybrid, Client/Server).

**EliteSiteCompiler.exe**
- **Purpose:** Serverless documentation engine.
- **Features:** Sweeps all .md files in a repo, mathematically escapes characters, and generates a compressed DocsData.js object. Used to power this exact HTML documentation hub!

---

### 🛠️ Utilities & Transformers

**EliteDevServer.exe**
- **Purpose:** Instant Localhost Web Server.
- **Features:** Zero-dependency HttpListener. Dual binds HTTP/HTTPS, autogenerates SSL certificates if elevated, and bypasses CORS. Drag-and-drop an HTML file to launch instantly!

**EliteTaskAssassin.exe**
- **Purpose:** Precision process terminator.
- **Features:** Takes a semicolon-delimited list of target EXEs (pp1.exe;app2.exe), takes a native snapshot via 	lhelp32.h, and executes TerminateProcess to free locked files before compilation.

**EliteDuplicateSweeper.exe**
- **Purpose:** Multi-extension recursive filesystem cleaner.
- **Features:** Hunts down .obj, .res, and orphaned temporary files post-compilation and permanently annihilates them.

**EliteDocConverter.exe**
- **Purpose:** Text extraction engine.
- **Features:** Binary character stripper extracting printable ASCII from messy .rtf or .doc files safely.

**EliteSymlinker.exe**
- **Purpose:** The "Symlink Rule" Enforcer.
- **Features:** Creates Symbolic or Hard links to system assets. Ensures AIs and builders always use the master file without ever risking moving or deleting the original.

**EliteShortcutForge.exe**
- **Purpose:** Native COM IShellLink creator.
- **Features:** Instantly generates .lnk files programmatically, resolving icon paths and arguments cleanly.

**ElitePSWrapper.exe**
- **Purpose:** Secure PS2EXE deployment.
- **Features:** Wraps Invoke-PS2EXE securely via a hidden Bypass process to compile .ps1 scripts into .exe.

---

### 🧩 Resource & PE Hacking

**EliteMetaStamper.exe**
- **Purpose:** Version metadata architect.
- **Features:** Formats ersion.rc files natively using arguments (--version, --company, --product) perfectly styled for windres compilation.

**EliteIconReplacer.exe**
- **Purpose:** Main executable icon substitution.
- **Features:** Programmatically replaces RT_GROUP_ICON inside compiled EXEs and natively calculates the new PE Checksum using imagehlp.dll.

**icon_maker.exe**
- **Purpose:** Image-to-Icon container generator.
- **Features:** Extracts all embedded RT_BITMAP/RT_ICON payloads from PE binaries or cleanly converts images with --remove-halo support.

**IcoToPngConverter.exe**
- **Purpose:** Resolution exploder.
- **Features:** Extracts every single resolution frame embedded within an .ico file into separate .png files.

**ResourceAlchemyHacker_CLI.exe**
- **Purpose:** Advanced Win32 Resource modifier.
- **Features:** Injects, edits, or extracts strings, dialogs, icons, and manifests directly into compiled .exe or .dll components natively.

---

### 🛡️ Core OS & COM Automation

**EliteComLoader.exe**
- **Purpose:** COM Registration.
- **Features:** Alternative to egsvr32. Dynamically maps DllRegisterServer inside DLLs and OCXs via Win32.

**EliteSmartRegsvr.exe**
- **Purpose:** Drag-and-drop COM handler.
- **Features:** Automatically detects architecture of the dropped PE file and routes to the correct egsvr32.exe (SysWOW64 vs System32).

**EliteServiceForge.exe**
- **Purpose:** Service architecture engine.
- **Features:** Wraps CreateServiceA to instantly spin up or terminate Windows Background Services without the SC command overhead.

**EliteDummyDllGen.exe**
- **Purpose:** Testing Stub Compiler.
- **Features:** Auto-generates C++ stubs with given exports and instantly shells out to g++ -shared to compile valid .dll payloads.

**EliteLaunchAsTI.exe**
- **Purpose:** Ring-0 Lifeline.
- **Features:** Designed for escalating system processes to TrustedInstaller. (Currently deployed as standard execution fallback module).

**EliteCertManager.exe**
- **Purpose:** Automated Trust builder.
- **Features:** Parses X.509 .cer blobs via wincrypt.h and intrinsically maps them to the Trusted Root Certification Authorities store.

**EliteCLSIDGenerator.exe**
- **Purpose:** COM Identifiers.
- **Features:** Generates unique CLSIDs, logs them, and maps against Windows Registry (HKCR) to verify non-collision.

**EliteInnoCreator.exe**
- **Purpose:** Installer architect.
- **Features:** Hosts 3 primary templates and cleanly wraps ISCC.exe to generate robust Inno Setup installers from arguments.
