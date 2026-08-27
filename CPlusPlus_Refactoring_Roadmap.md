# 🛠️ EliteSoftware Master Refactoring Roadmap
*Phase 3: The C++ Native CLI Transformation*

This document outlines 15 targeted PowerShell legacy scripts from the EliteSoftware Script Archive that are queued for strict C++ Win32 CLI conversion. These natively compiled EXEs will be permanently added to the %ELITE_BUILD_X64% environment variables for instantaneous, multi-threaded use across all our projects.

---

### 1. EliteMetaStamper.exe (from MetaData Editor Tool.PS1)
- **Action:** Injects/Modifies the RT_VERSION metadata of an EXE (Product Name, Copyright).
- **Arguments:** --exe <path> --file-version <1.0.0.0> --product-name <string> --copyright <string>
- **Why C++:** Manipulating the PE resource table mathematically prevents file corruption compared to hacky script wrappers.

### 2. EliteShortcutForge.exe (from Create-Shortcuts.PS1)
- **Action:** Natively creates Windows .lnk shortcuts using COM interfaces IShellLink.
- **Arguments:** --target <exe> --out <path.lnk> --icon <path.ico> --args <string> --workdir <path>
- **Why C++:** Generates reliable desktop shortcuts without invoking WScript.Shell via Powershell which flags some AV engines.

### 3. EliteSymlinker.exe (from Link & Mover Utility.PS1)
- **Action:** High-speed creation of NTFS Hard Links, Symlinks, and Junctions.
- **Arguments:** --source <path> --link <path> --type <hard|sym|junction>
- **Why C++:** Centralizes our upcoming EliteIcons.dll across multiple directories instantly without wasting disk space.

### 4. EliteDuplicateSweeper.exe (from FileScanner_and_DuplicateFinder.PS1)
- **Action:** Cleans build directories by removing duplicates, .obj, and .pdb temp files.
- **Arguments:** --dir <path> --ext <.obj|.pdb> --auto-delete
- **Why C++:** A native recursive directory parser using std::filesystem is lightyears faster than Get-ChildItem.

### 5. EliteDocConverter.exe (from Doc-Docx to TXT Converter.ps1)
- **Action:** Headless flat-file conversion of .rtf or .docx into .md/.txt.
- **Arguments:** --in <file> --out <file>
- **Why C++:** Allows AI pipelines to ingest legacy documentation natively.

### 6. ElitePSWrapper.exe (from PS1_2_EXE.PS1)
- **Action:** Wraps PS2EXE compilation but forces our specific environmental architectures.
- **Arguments:** --ps1 <script> --exe <out> [--disable-sta] [--show-console]
- **Why C++:** Enforces -STA and -noConsole by default for GUI tools to prevent clipboard crashes. *Includes new override flags so we can debug non-STA scripts if needed.*

### 7. EliteRegSnapshot.exe (from RegistryBackup_Inator.PS1)
- **Action:** Instantly snapshots and exports specific registry hives (like HKCR\CLSID).
- **Arguments:** --key <HKLM\Software\X> --export <backup.reg> --restore <backup.reg>
- **Why C++:** Direct registry manipulation via Win32 API is faster and acts as an immediate fail-safe for COM registrations.

### 8. EliteAssetManager.exe (from AssetManager.ps1)
- **Action:** Validates and dynamically imports third-party dependencies (like SQLite or TagLibSharp for MP3Toolkit).
- **Arguments:** --manifest <assets.json> --out <include_dir>
- **Why C++:** Ensures C++ compilation doesn't fail due to missing .lib or .dll files prior to g++ execution.

### 9. EliteHostConfigurator.exe (from NetworkManager.PS1)
- **Action:** Automatically adds/removes local domain routing in the Windows hosts file.
- **Arguments:** --domain <main.elitesoftwaretech.cc> --ip <127.0.0.1>
- **Why C++:** A dedicated tool for instantly staging local web environments for projects like Agent-Thread HTML.

### 10. EliteLaunchAsTI.exe (from Launch-As_Trusted-Installer.PS1)
- **Action:** Elevates an execution process directly to the NT AUTHORITY\SYSTEM or TrustedInstaller tokens.
- **Arguments:** --target <exe> --args <string>
- **Why C++:** C++ token manipulation allows us to bypass script-block logging when legitimately copying files into system directories during builds.

### 11. EliteComLoader.exe (from Load_COM_Objects.PS1)
- **Action:** Smart architecture detection and registration of .dll COM components.
- **Arguments:** --dll <path>
- **Why C++:** Automatically chooses between System32 and SysWOW64 egsvr32.exe to prevent 32/64 bit mismatch errors.

### 12. EliteCertManager.exe (from SelfSigned_Certificate.PS1)
- **Action:** Installs .pfx or .cer files into the Root and TrustedPublisher stores.
- **Arguments:** --cert <path.cer> --store <Root|TrustedPublisher>
- **Why C++:** Calling CertAddEncodedCertificateToStore natively eliminates the need for manual MMC importing before signing with EliteEasySigner.exe.

### 13. EliteServiceForge.exe (from Service-Creator-GUI.ZACH.PS1)
- **Action:** Installs headless C++ executables as background Windows Services.
- **Arguments:** --name <ServiceName> --exe <path> --start <auto|demand>
- **Why C++:** Wrapping CreateServiceW directly is much cleaner than invoking sc.exe through batch logic.

### 14. EliteEnvManager.exe (from DevDeploy Envirnment Manager.PS1)
- **Action:** Dynamically injects or removes paths in the global System Environment Variables (%PATH%, %ELITE_BUILD_X64%).
- **Arguments:** --var <PATH> --append <path>
- **Why C++:** Modifying registry keys HKLM\System\CurrentControlSet\Control\Session Manager\Environment and broadcasting WM_SETTINGCHANGE natively.

### 15. EliteDummyDllGen.exe (from New-DummyDll.ps1)
- **Action:** Instantly compiles a stub .dll file with specified export functions for testing loader logic.
- **Arguments:** --out <dummy.dll> --export <Func1,Func2>
- **Why C++:** Automatically writes the C++ stub and invokes g++ -shared to produce a testing library on the fly.

---
*Generated for EliteSoftware Architecture Review - 2026*
