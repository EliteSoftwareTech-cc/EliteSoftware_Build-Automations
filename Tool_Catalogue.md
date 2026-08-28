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

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--append`
  - `--remove`
  - `--set`
  - `--var`
- **Example Command:**
  `"EliteEnvManager.exe" --ai-mode --append --remove --set --var`

**EliteHostConfigurator.exe**
- **Purpose:** Headless manager for %WINDIR%\System32\drivers\etc\hosts.
- **Features:** Injects mappings (--domain localhost --ip 127.0.0.1) or instantly strips them.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--domain`
  - `--ip`
  - `--remove`
- **Example Command:**
  `"EliteHostConfigurator.exe" --ai-mode --domain --ip --remove`

**EliteNetworkManager.exe**
- **Purpose:** Next-generation wrapper for IP/DNS handling.
- **Features:** Fast-flushes DNS, assigns static routing, and manipulates adapters without the slow overhead of traditional 

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--flush-dns`
- **Example Command:**
  `"EliteNetworkManager.exe" --ai-mode --flush-dns`
etsh invocation.

**EliteExecPolToggle.exe**
- **Purpose:** Powershell Execution Policy bypasser.
- **Features:** Instantly flips HKLM (or HKCU if non-elevated) registry keys to Bypass to unlock workstation automation layers.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--level`
- **Example Command:**
  `"EliteExecPolToggle.exe" --ai-mode --level`

**EliteWin7Enabler.exe**
- **Purpose:** A legacy lifeline.
- **Features:** Unlocks Extended Security Updates (ESU) logic on Windows 7 machines by patching registry and policy flags.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
- **Example Command:**
  `"EliteWin7Enabler.exe" --ai-mode`

---

### 🔧 Build Chain Orchestration

**EliteBuild.exe (The Entry Point)**
- **Purpose:** The master orchestrator.
- **Features:** Reads EliteBuild.config files, searches system arrays (%ELITE_BUILD_X64%), and seamlessly streams execution to other backend components below.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--config <path>` (Example: `--config .\MyConfig.config`)
  - `--tool`
- **Example Command:**
  `"EliteBuild.exe" --ai-mode --config .\MyConfig.config --tool`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres -F pe-x86-64 $RcFile -o $ResOut64",
        "windres -F pe-i386 $RcFile -o $ResOut32",
        "g++ -m64 -O3 -std=c++17 -o BuildOutputx64\\ $SourceFile $ResOut64",
        "g++ -m32 -O3 -std=c++17 -o BuildOutputx86\\ $SourceFile $ResOut32"
    ],
    "KillProcesses": [
        "EliteSoftware-EntryPoint.exe"
    ]
}

```
</details>

**EliteCompiler.exe / ElitePackager.exe**
- **Purpose:** Heavy-duty backend wrappers.
- **Features:** Bridges .ps1 to executable formats or handles CI/CD GitHub release logic dynamically via configuration files instead of hardcoded paths.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--config <path>` (Example: `--config .\MyConfig.config`)
- **Example Command:**
  `"EliteCompiler.exe" --ai-mode --config .\MyConfig.config`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres -F pe-x86-64 $RcFile -o $ResOut64",
        "windres -F pe-i386 $RcFile -o $ResOut32",
        "g++ -m64 -O3 -std=c++17 -o BuildOutputx64\\ $SourceFile $ResOut64",
        "g++ -m32 -O3 -std=c++17 -o BuildOutputx86\\ $SourceFile $ResOut32"
    ],
    "KillProcesses": [
        "EliteSoftware-Compiler.exe"
    ]
}

```
</details>

**EliteVersionBumper.exe**
- **Purpose:** Continuous Integration version tracker.
- **Features:** Scans changelog.md and ersion.h, parses Semantic Versioning (1.0.0.0), and automatically increments Major, Minor, Feature, or Bugfix arguments.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
- **Example Command:**
  `"EliteVersionBumper.exe" --ai-mode`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres -F pe-x86-64 $RcFile -o $ResOut64",
        "windres -F pe-i386 $RcFile -o $ResOut32",
        "g++ -m64 -O3 -std=c++17 -o BuildOutputx64\\ $SourceFile $ResOut64",
        "g++ -m32 -O3 -std=c++17 -o BuildOutputx86\\ $SourceFile $ResOut32"
    ],
    "KillProcesses": [
        "EliteSoftware-VersionBumper.exe"
    ]
}

```
</details>

**EliteReadmeGenerator.exe**
- **Purpose:** Document scaffolding engine.
- **Features:** Hosts 5 hardcoded Markdown templates tailored for various architectures (e.g. Master Hybrid, Client/Server).

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `-help`
- **Example Command:**
  `"EliteReadmeGenerator.exe" --ai-mode`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres -F pe-x86-64 $RcFile -o $ResOut64",
        "windres -F pe-i386 $RcFile -o $ResOut32",
        "g++ -m64 -O3 -std=c++17 -o BuildOutputx64\\ $SourceFile $ResOut64",
        "g++ -m32 -O3 -std=c++17 -o BuildOutputx86\\ $SourceFile $ResOut32"
    ],
    "KillProcesses": [
        "EliteSoftware-ReadmeGenerator.exe"
    ]
}

```
</details>

**EliteSiteCompiler.exe**
- **Purpose:** Serverless documentation engine.
- **Features:** Sweeps all .md files in a repo, mathematically escapes characters, and generates a compressed DocsData.js object. Used to power this exact HTML documentation hub!

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--dir <path>` (Example: `--dir "C:\MyData"`)
  - `--out <path>` (Example: `--out "C:\MyData"`)
- **Example Command:**
  `"EliteSiteCompiler.exe" --ai-mode --dir "C:\MyData" --out "C:\MyData"`

---

### 🛠️ Utilities & Transformers

**EliteDevServer.exe**
- **Purpose:** Instant Localhost Web Server.
- **Features:** Zero-dependency HttpListener. Dual binds HTTP/HTTPS, autogenerates SSL certificates if elevated, and bypasses CORS. Drag-and-drop an HTML file to launch instantly!

- **Arguments:**
  - `-Target`
- **Example Command:**
  `"EliteDevServer.exe" -Target`

**EliteTaskAssassin.exe**
- **Purpose:** Precision process terminator.
- **Features:** Takes a semicolon-delimited list of target EXEs (pp1.exe;app2.exe), takes a native snapshot via 	lhelp32.h, and executes TerminateProcess to free locked files before compilation.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--targets`
- **Example Command:**
  `"EliteTaskAssassin.exe" --ai-mode --targets`

**EliteDuplicateSweeper.exe**
- **Purpose:** Multi-extension recursive filesystem cleaner.
- **Features:** Hunts down .obj, .res, and orphaned temporary files post-compilation and permanently annihilates them.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--auto-delete`
  - `--dir <path>` (Example: `--dir "C:\MyData"`)
  - `--ext`
- **Example Command:**
  `"EliteDuplicateSweeper.exe" --ai-mode --auto-delete --dir "C:\MyData" --ext`

**EliteDocConverter.exe**
- **Purpose:** Text extraction engine.
- **Features:** Binary character stripper extracting printable ASCII from messy .rtf or .doc files safely.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--in`
  - `--out <path>` (Example: `--out "C:\MyData"`)
- **Example Command:**
  `"EliteDocConverter.exe" --ai-mode --in --out "C:\MyData"`

**EliteSymlinker.exe**
- **Purpose:** The "Symlink Rule" Enforcer.
- **Features:** Creates Symbolic or Hard links to system assets. Ensures AIs and builders always use the master file without ever risking moving or deleting the original.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--link`
  - `--source`
  - `--type`
- **Example Command:**
  `"EliteSymlinker.exe" --ai-mode --link --source --type`

**EliteShortcutForge.exe**
- **Purpose:** Native COM IShellLink creator.
- **Features:** Instantly generates .lnk files programmatically, resolving icon paths and arguments cleanly.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--args`
  - `--icon`
  - `--out <path>` (Example: `--out "C:\MyData"`)
  - `--target`
  - `--workdir`
- **Example Command:**
  `"EliteShortcutForge.exe" --ai-mode --args --icon --out "C:\MyData" --target --workdir`

**ElitePSWrapper.exe**
- **Purpose:** Secure PS2EXE deployment.
- **Features:** Wraps Invoke-PS2EXE securely via a hidden Bypass process to compile .ps1 scripts into .exe.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--disable-sta`
  - `--exe <path>` (Example: `--exe "C:\MyData"`)
  - `--icon`
  - `--ps1`
  - `--show-console`
- **Example Command:**
  `"ElitePSWrapper.exe" --ai-mode --disable-sta --exe "C:\MyData" --icon --ps1 --show-console`

---

### 🧩 Resource & PE Hacking

**EliteMetaStamper.exe**
- **Purpose:** Version metadata architect.
- **Features:** Formats ersion.rc files natively using arguments (--version, --company, --product) perfectly styled for windres compilation.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--company`
  - `--out <path>` (Example: `--out "C:\MyData"`)
  - `--product`
  - `--version`
- **Example Command:**
  `"EliteMetaStamper.exe" --ai-mode --company --out "C:\MyData" --product --version`

**EliteIconReplacer.exe**
- **Purpose:** Main executable icon substitution.
- **Features:** Programmatically replaces RT_GROUP_ICON inside compiled EXEs and natively calculates the new PE Checksum using imagehlp.dll.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--exe <path>` (Example: `--exe "C:\MyData"`)
  - `--icon`
- **Example Command:**
  `"EliteIconReplacer.exe" --ai-mode --exe "C:\MyData" --icon`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres src\\EliteSoftware-IconReplacer\\app.rc -O coff -o src\\EliteSoftware-IconReplacer\\app.res",
        "g++ -m64 -O3 -o BuildOutputx64\\ src\\EliteSoftware-IconReplacer\\main.cpp src\\EliteSoftware-IconReplacer\\app.res -limagehlp",
        "g++ -m32 -O3 -o BuildOutputx86\\ src\\EliteSoftware-IconReplacer\\main.cpp src\\EliteSoftware-IconReplacer\\app.res -limagehlp"
    ],
    "KillProcesses": [
        "EliteSoftware-IconReplacer.exe"
    ]
}

```
</details>

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
- **Features:** Alternative to 

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--dll`
  - `--unregister`
- **Example Command:**
  `"EliteComLoader.exe" --ai-mode --dll --unregister`
egsvr32. Dynamically maps DllRegisterServer inside DLLs and OCXs via Win32.

**EliteSmartRegsvr.exe**
- **Purpose:** Drag-and-drop COM handler.
- **Features:** Automatically detects architecture of the dropped PE file and routes to the correct 

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--file <path>` (Example: `--file "C:\MyData"`)
- **Example Command:**
  `"EliteSmartRegsvr.exe" --ai-mode --file "C:\MyData"`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres src\\EliteSoftware-SmartRegsvr\\app.rc -O coff -o src\\EliteSoftware-SmartRegsvr\\app.res",
        "g++ -m64 -O3 -o BuildOutputx64\\ src\\EliteSoftware-SmartRegsvr\\main.cpp",
        "g++ -m32 -O3 -o BuildOutputx86\\ src\\EliteSoftware-SmartRegsvr\\main.cpp"
    ],
    "KillProcesses": [
        "EliteSoftware-SmartRegsvr.exe"
    ]
}

```
</details>
egsvr32.exe (SysWOW64 vs System32).

**EliteServiceForge.exe**
- **Purpose:** Service architecture engine.
- **Features:** Wraps CreateServiceA to instantly spin up or terminate Windows Background Services without the SC command overhead.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--bin`
  - `--display`
  - `--name`
  - `--remove`
- **Example Command:**
  `"EliteServiceForge.exe" --ai-mode --bin --display --name --remove`

**EliteDummyDllGen.exe**
- **Purpose:** Testing Stub Compiler.
- **Features:** Auto-generates C++ stubs with given exports and instantly shells out to g++ -shared to compile valid .dll payloads.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--exports`
  - `--name`
- **Example Command:**
  `"EliteDummyDllGen.exe" --ai-mode --exports --name`

**EliteLaunchAsTI.exe**
- **Purpose:** Ring-0 Lifeline.
- **Features:** Designed for escalating system processes to TrustedInstaller. (Currently deployed as standard execution fallback module).

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--cmd`
- **Example Command:**
  `"EliteLaunchAsTI.exe" --ai-mode --cmd`

**EliteCertManager.exe**
- **Purpose:** Automated Trust builder.
- **Features:** Parses X.509 .cer blobs via wincrypt.h and intrinsically maps them to the Trusted Root Certification Authorities store.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--cert`
  - `--uninstall`
- **Example Command:**
  `"EliteCertManager.exe" --ai-mode --cert --uninstall`

**EliteCLSIDGenerator.exe**
- **Purpose:** COM Identifiers.
- **Features:** Generates unique CLSIDs, logs them, and maps against Windows Registry (HKCR) to verify non-collision.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--filter`
  - `--list`
  - `--name`
- **Example Command:**
  `"EliteCLSIDGenerator.exe" --ai-mode --filter --list --name`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres src\\EliteSoftware-CLSIDGenerator\\app.rc -O coff -o src\\EliteSoftware-CLSIDGenerator\\app.res",
        "g++ -m64 -O3 -o BuildOutputx64\\ src\\EliteSoftware-CLSIDGenerator\\main.cpp -lole32 -ladvapi32",
        "g++ -m32 -O3 -o BuildOutputx86\\ src\\EliteSoftware-CLSIDGenerator\\main.cpp -lole32 -ladvapi32"
    ],
    "KillProcesses": [
        "EliteSoftware-CLSIDGenerator.exe"
    ]
}

```
</details>

**EliteInnoCreator.exe**
- **Purpose:** Installer architect.
- **Features:** Hosts 3 primary templates and cleanly wraps ISCC.exe to generate robust Inno Setup installers from arguments.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--compile`
  - `--generate`
  - `--out <path>` (Example: `--out "C:\MyData"`)
  - `--template`
- **Example Command:**
  `"EliteInnoCreator.exe" --ai-mode --compile --generate --out "C:\MyData" --template`

<details>
<summary>Example .config Structure</summary>

```json
﻿{
    "GccTargets": [
        "windres src\\EliteSoftware-InnoCreator\\app.rc -O coff -o src\\EliteSoftware-InnoCreator\\app.res",
        "g++ -m64 -O3 -o BuildOutputx64\\ src\\EliteSoftware-InnoCreator\\main.cpp",
        "g++ -m32 -O3 -o BuildOutputx86\\ src\\EliteSoftware-InnoCreator\\main.cpp"
    ],
    "KillProcesses": [
        "EliteSoftware-InnoCreator.exe"
    ]
}

```
</details>

---

### 🚀 Phase 3: System Resilience & Bootstrapping

**EliteSystemRestore.exe**
- **Purpose:** Natively creates Windows System Restore points.
- **Features:** Directly hooks srclient.dll and SRSetRestorePointW for lightning-fast, silent system state snapshots before destructive automated builds.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--desc`
- **Example Command:**
  `"EliteSystemRestore.exe" --ai-mode --desc`

**EliteFolderScanner.exe**
- **Purpose:** Advanced native directory scanning and metrics.
- **Features:** Utilizes native Win32 FindFirstFile/FindNextFile for blazing fast recursive directory traversal and space calculations.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--dir <path>` (Example: `--dir "C:\MyData"`)
- **Example Command:**
  `"EliteFolderScanner.exe" --ai-mode --dir "C:\MyData"`

**EliteDotNetEnv.exe**
- **Purpose:** Analyzes and provisions the .NET Framework ecosystem.
- **Features:** Natively queries HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP to dynamically map installed frameworks.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
- **Example Command:**
  `"EliteDotNetEnv.exe" --ai-mode`

**EliteVSBuildTools.exe**
- **Purpose:** Headless bootstrapper for MSVC build tools.
- **Features:** Standardizes the C++ compilation environment identically across all EliteSoftware machines.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
- **Example Command:**
  `"EliteVSBuildTools.exe" --ai-mode`

**EliteOptiLink.exe**
- **Purpose:** Local IPC / LAN Messaging.
- **Features:** Replaces slow PowerShell IPC with blazing fast Named Pipe daemon for instant agent-to-agent communication.

- **Arguments:**
  - `--ai-mode` (Bypasses interactive EULA prompts)
  - `--server`
  - `--target`
- **Example Command:**
  `"EliteOptiLink.exe" --ai-mode --server --target`

---

### 🗡️ Phase 4: Active Interceptors

**ElitePIDKiller.exe (PID-KILLER)**
- **Purpose:** Targeted process termination by ID.
- **Features:** Takes a Process ID (PID) as an argument or asks for one interactively, then natively executes OpenProcess with PROCESS_TERMINATE and kills it instantly.

**EliteEXEKiller.exe (EXE-KILLER)**
- **Purpose:** Targeted process termination by Name.
- **Features:** Takes a filename (e.g., 
otepad.exe), loops through CreateToolhelp32Snapshot to find all matching instances, and terminates them instantly.

