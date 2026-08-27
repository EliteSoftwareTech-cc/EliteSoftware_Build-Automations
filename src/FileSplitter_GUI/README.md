# File Splitter For AI Upload (v1.2.0.0)

**EliteSoftwareTech Co.**  
*Native C++ Win32 High-Density Desktop File Splitting Utility*  
*Target Framework: Native Win32 API / C++17 | Minimum OS Target: Windows Vista / Windows 7+*

---

## 📌 Project Overview
**File Splitter For AI Upload** is a native Win32 desktop application written in modern C++17 designed to split large text files into smaller `.txt` chunks based on configurable character or line limits. The utility is built specifically to prepare large text datasets, prompts, logs, and source code files for uploading into artificial intelligence models with constrained context windows or file upload boundaries.

### Key Capabilities:
- **Character & Line Count Limits**: Split files cleanly by maximum character count or exact line boundaries (preserving CR/LF line endings).
- **Single & Batch Processing**: Process individual text files or entire sets of files in batch mode simultaneously.
- **Automatic Output Subfolders**: Creates output subdirectories named `<OriginalFileName>_parts/` containing sequentially named chunks (`<OriginalFileName>_part_001.txt`).
- **64 KB Streaming Memory Buffer**: Extremely lightweight RAM footprint suitable for multi-gigabyte text files.
- **Asynchronous Non-Blocking Processing**: Background `std::thread` worker prevents UI freezing during massive file splits.
- **Append-Only System Logging**: Maintains operational history in `%SystemDrive%\EliteSoftware\Logs\FileSplitter.log` with a direct Notepad log viewer link in the GUI.
- **Live Agent HTML Dashboard**: Includes `Agent-Thread_HTML/index.html` for real-time visualization of agent communications and historical handoff logs.

---

## 🏛️ Architecture & Visual Guidelines Compliance

The application strictly adheres to the **EliteSoftwareTech Co. GUI Development Guidelines (v1.2.0.0)**:

1. **Title Banner**: A 56px top banner containing the application title and the application icon.
2. **3D Inset Active Area**: The central main active workspace is inset using a classic 3D client edge (`WS_EX_CLIENTEDGE`) shadow separating it from the outer frame.
3. **Darker Chin Panel**: The bottom button strip is visually anchored behind controls using a distinct darker shade (`RGB(224, 224, 224)`).
4. **Typography**: Uses `Segoe UI` (Semibold for headers/banners and Regular for standard controls).
5. **Elite Button Nomenclature**: Standard conventions only (**"Okay"**, **"Cancel"**, **"Apply"**, **"Exit"**, **"Done"**). **"OK" is strictly forbidden.**
6. **Multi-Line Witty Tooltips**: Every interactive UI element is equipped with hover tooltips (`TOOLTIPS_CLASS`) explaining functionality and item states with a sarcastic undertone.
7. **Dynamic Icon Sideloading**: Dynamically checks for `<ExeName>.ico` alongside the executable. If present, it overrides the compiled resource icon for the Title Bar, Taskbar, and Banner.
8. **UIPI-Compliant Drag and Drop**: Non-elevated `WM_DROPFILES` integration allowing direct file drag-and-drop from Windows Explorer.
9. **Native Dialog Suite**: Includes standard Win32 Menubar, Toolbar, Statusbar with size grip, Help dialog ('?' icon), Settings dialog, and About dialog (info 'i' icon with collapsible `More Details >>` expander).

---

## 🔨 Build Instructions

### Prerequisites
- **Compiler**: MinGW-w64 GCC (g++) supporting C++17
- **Resource Compiler**: GNU `windres`
- **Shell**: PowerShell 5.1+ (or PowerShell Core 7+)
- **Optional**: Python 3.10+ (for executing automated E2E test suites)

### 1. Primary Build Pipeline (`Build.ps1`)
Run the master PowerShell build script from the project root:

```powershell
powershell -ExecutionPolicy Bypass -File .\Build.ps1
```

The master build script orchestrates 5 consecutive build scripts:
1. `Scripts/01_PrepareEnvironment.ps1`: Validates `g++` and `windres`, creates output directories (`BuildOutput/` and `BuildOutputx86/`), and cleans stale object files.
2. `Scripts/02_CompileResources.ps1`: Compiles `res/FileSplitter.rc` into resource object files for both 64-bit and 32-bit targets.
3. `Scripts/03_CompileEngineAndTests.ps1`: Compiles C++ unit tests (`test_engine.exe`), executes unit tests, and runs Python E2E harness (`tests/test_splitter.py`).
4. `Scripts/04_CompileBinaries.ps1`: Compiles 64-bit (`BuildOutput/FileSplitter.exe`) and 32-bit (`BuildOutputx86/FileSplitter.exe`) executables targeting Windows Vista+ minimum OS (`-D_WIN32_WINNT=0x0600 -DWINVER=0x0600 -municode -mwindows -O2 -s`).
5. `Scripts/05_PackageOutput.ps1`: Sideloads `FileSplitter.ico`, packages documentation and `Agent-Thread_HTML`, and verifies final release artifacts.

### 2. Alternative Build via Makefile
You can also use MinGW `make`:

```cmd
make gui     :: Build 64-bit GUI executable (FileSplitter.exe)
make test    :: Build and execute C++ engine unit tests (test_engine.exe)
make all     :: Build GUI and run tests
make clean   :: Remove temporary build artifacts
```

---

## 📂 Project Layout

```
File_Splitter_ForAI-Upload/
├── Build.ps1                  # Master build & verification pipeline orchestrator
├── Makefile                   # MinGW Makefile for g++ / windres
├── README.md                  # Project documentation & build guide
├── ORIGINAL_REQUEST.md        # Verbatim original user requirements
├── PROJECT.md                 # Architecture, feature inventory, & milestone specifications
├── .gitignore                 # Git ignore rules for binaries, objects, and logs
├── Agent-Thread_HTML/         # Interactive live agent thread & history HTML dashboard
│   ├── index.html             # Web dashboard UI
│   ├── thread_data.json       # Live agent threads JSON data
│   ├── history_data.json      # Historical communication & handoff JSON data
│   └── gemini.md              # Dashboard specification & data schemas
├── Scripts/                   # PowerShell build chain scripts
│   ├── 01_PrepareEnvironment.ps1
│   ├── 02_CompileResources.ps1
│   ├── 03_CompileEngineAndTests.ps1
│   ├── 04_CompileBinaries.ps1
│   └── 05_PackageOutput.ps1
├── include/                   # C++ Header Files
│   ├── TextSplitterEngine.h   # Core engine logic header
│   ├── AppWindow.h            # Main Win32 window class
│   ├── Dialogs.h              # About, Help, Settings dialog headers
│   ├── Logger.h               # System logging header
│   └── Resource.h             # Resource IDs and menu commands
├── src/                       # C++ Source Files
│   ├── main.cpp               # WinMain entry point & STA initialization
│   ├── TextSplitterEngine.cpp # Core stream splitter implementation
│   ├── AppWindow.cpp          # Win32 GUI controls, banner, 3D inset, chin
│   ├── Dialogs.cpp           # Custom dialog procedures
│   ├── Logger.cpp            # Append-only log manager
│   └── test_main.cpp          # C++ engine unit test suite
├── res/                       # Resource Files
│   ├── FileSplitter.rc        # Win32 resource script
│   ├── FileSplitter.manifest  # ComCtl32 v6 Visual Styles manifest
│   └── FileSplitter.ico       # Dynamic application icon
└── tests/                     # Test Suite Files
    ├── test_splitter.py       # Automated Python E2E verification harness
    └── test_main.cpp          # Unit test entry point wrapper
```

---

## 🧪 Testing & Quality Assurance

### 1. C++ Engine Unit Tests
Runs 12 unit tests validating stream splitting, single/batch modes, edge cases (empty files, zero limits, exact boundary splits), and CR/LF preservation.

```cmd
./test_engine.exe
```

### 2. Python E2E Acceptance Test Harness
Verifies Tier 1 acceptance criteria (splitting a 10,000-character test file into 3,000-character chunks producing 4 files with exact binary identity upon reassembly) alongside line count splits and boundary checks.

```cmd
python tests/test_splitter.py
```

---

## 📝 Logging & Diagnostics

Logs are written to:
`%SystemDrive%\EliteSoftware\Logs\FileSplitter.log`

To view logs directly from the GUI, navigate to `Help -> View Log File` in the top menu bar or click the status link in the Settings dialog.

---

## 📄 License & Attribution
**Author**: EliteSoftwareTech Co. (Zachary Whiteman, Susan Gemm, TheShadyRainbow4)  
**Company**: EliteSoftware / EliteSoftwareTech Co.  
**Version**: 1.2.0.0
