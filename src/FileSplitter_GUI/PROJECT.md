# Project: C++ Win32 File Splitter GUI ("File Splitter For AI Upload")

## Architecture
The application is structured into four core layers:
1. **Core Splitting Engine (`TextSplitterEngine`)**: Native C++ stream-based splitter handling single and batch text files by character or line count limit. Memory buffer footprint: 64 KB. Supports UTF-8 codepoint boundaries, CR/LF preservation, subfolder generation (`<OriginalName>_parts`), cancellation tokens, and thread-safe progress callbacks.
2. **Win32 GUI & EliteSoftware Aesthetic Layer**: Native C++ Win32 API window with standard Win32 visual styles, 56px top Title Banner with logo icon, central 3D Inset Active Area (`WS_EX_CLIENTEDGE`), 48px bottom Chin panel (`RGB(224, 224, 224)`), Segoe UI Semibold/Regular fonts, tooltip control (`TOOLTIPS_CLASS`) for all controls with witty sarcastic tone, standard button nomenclature ("Okay", "Cancel", "Apply", "Exit", "Done", NO "OK"), dynamic `.ico` loading, non-elevated `WM_DROPFILES` drag & drop.
3. **Dialogs & Navigation Layer**: Menubar, About dialog (with info 'i' icon and dynamic `More Details >>` dropdown expander), Help dialog ('?' icon), Settings dialog (persisting settings), Statusbar with size grip, and Toolbar.
4. **Asynchronous Processing & Logging Layer**: Background `std::thread` worker with custom `WM_USER` message handlers (`WM_SPLIT_PROGRESS`, `WM_SPLIT_COMPLETE`, `WM_SPLIT_ERROR`), and system logger (`%SystemDrive%\EliteSoftware\Logs\FileSplitter.log`) with interactive Notepad log viewer link.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Core Splitting Logic (by Chars/Lines) | Split files by character or line limit into `.txt` chunks | M1 | R1 |
| 2 | Batch & Single File Processing | Support splitting single files or multiple files in batch mode | M1 | R1 |
| 3 | Automatic Subfolder Output | Save chunks in dedicated subfolder named after original file | M1 | R1 |
| 4 | Programmatic Verification Test | Python/C++ test splitting 10,000 char file into 3,000 char chunks (4 files, exact identity) | M2 | Acceptance Criteria |
| 5 | E2E Test Suite Tiers 1-4 | Requirement-driven test suite covering all features, boundaries, and combinations | M2 | Acceptance Criteria |
| 6 | Title Banner UI Component | 56px top banner with application title and application icon | M3 | R3 & Guidelines |
| 7 | 3D Inset Active Area | Central main active area inset with 3D-like client edge (`WS_EX_CLIENTEDGE`) | M3 | R3 & Guidelines |
| 8 | Darker Chin Panel | Bottom panel behind buttons with darker gray shade (`RGB(224, 224, 224)`) | M3 | R3 & Guidelines |
| 9 | Elite Button Nomenclature | Buttons strictly labeled "Okay", "Cancel", "Apply", "Exit", "Done" (NEVER "OK") | M3 | R3 & Guidelines |
| 10 | Typography (Segoe UI) | Segoe UI Semibold header & Segoe UI Regular fallback body fonts | M3 | R3 & Guidelines |
| 11 | Hover Tooltips | Tooltips on ALL interactive controls with accurate + sarcastic/witty tone | M3 | R3 & Guidelines |
| 12 | Menubar & Toolbar | Standard Win32 menu bar and toolbar for file actions and settings | M3 | R3 & Guidelines |
| 13 | About Dialog with Info Icon & Expander | Native info 'i' icon, app details, and `More Details >>` collapsible section | M3 | R3 & Guidelines |
| 14 | Help Dialog with Question Icon | Native '?' icon with comprehensive user guidance | M3 | R3 & Guidelines |
| 15 | Settings Dialog & Button | Dedicated settings window and UI launch button | M3 | R3 & Guidelines |
| 16 | Statusbar with Size Grip | Bottom status bar displaying file progress and size grip handle | M3 | R3 & Guidelines |
| 17 | Dynamic Icon Targeting | Read `<ExeName>.ico` alongside EXE or from compiled EXE resource | M3 | Guidelines |
| 18 | Non-Elevated Drag and Drop | UIPI-compliant `WM_DROPFILES` file drag & drop into GUI | M3 | Guidelines |
| 19 | Background Multi-Threading | `std::thread` worker so UI never freezes during splitting | M4 | R3 & Guidelines |
| 20 | System Logging & Notepad Viewer | Append-only logging to `%SystemDrive%\EliteSoftware\Logs\FileSplitter.log` + Notepad menu link | M4 | Guidelines |
| 21 | Git Repository & Documentation | Local private git repo, `.gitignore`, and comprehensive `README.md` | M5 | Guidelines |
| 22 | Final E2E Test & Adversarial Hardening | Tier 5 white-box coverage hardening & forensic integrity audit | M5 | E2E & Audit |
| 23 | Multi-line Detailed Tooltips | Highly detailed, multi-line tooltips explaining implications and all item states with witty undertone | M3 | User Request Update |
| 24 | Powershell Build Script Chain | `Build.ps1` & `Scripts/` chain building 64-bit (`BuildOutput/`) and 32-bit (`BuildOutputx86/`) binaries for Windows Vista+ | M5 | User Request Update |
| 25 | Sideloaded Dynamic Icon Priority | Dynamic lookup for `<ExeName>.ico` alongside EXE taking precedence over embedded EXE icon for titlebar, taskbar, and banner | M3 | User Request Update |
| 26 | Live Agent Thread HTML Dashboard | `Agent-Thread_HTML/` folder with `index.html` (Live Thread & Historical Inter-Comms tabs, distinct agent colors, dynamic sub-file data loading) and `gemini.md` usage guide | M5 | User Request Update |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Core Engine & C++ Engine API | Implementation of `TextSplitterEngine`, C++ headers, character/line splitting, subfolders, batch mode | none | DONE |
| M2 | E2E Testing Suite Track | Creation of `TEST_INFRA.md`, Python verification harness (`tests/test_splitter.py`), Tiers 1-4 test cases | M1 (Engine CLI) | DONE |
| M3 | Win32 GUI & Aesthetics | Main window, Title Banner, 3D Inset, Chin, Segoe UI, multi-line tooltips, Menubar, About/Help/Settings dialogs, Statusbar, Toolbar, Drag-and-Drop, Sideloaded Dynamic Icon | M1 | DONE |
| M4 | Async Worker & System Logger | `std::thread` background splitting worker, `WM_USER` progress messages, `%SystemDrive%\EliteSoftware\Logs\FileSplitter.log` logger, Notepad link | M1, M3 | DONE |
| M5 | Final Integration, Build Chain & Agent Dashboard | `Build.ps1` & `Scripts/` (32/64-bit outputs), `Agent-Thread_HTML/` (`index.html`, `gemini.md`, thread data), Git repo init (`git init`), `.gitignore`, `README.md`, Tier 5 adversarial testing, forensic audit pass, human handoff | M1, M2, M3, M4 | DONE |

## Interface Contracts
### `TextSplitterEngine` API (C++)
- `SplitOptions`: `std::wstring inputFilePath`, `std::wstring outputDir`, `SplitMode mode` (`ByCharacters`, `ByLines`), `uint64_t maxLimit`, `std::function<void(size_t currentFile, size_t totalFiles, uint64_t bytesProcessed, uint64_t totalBytes)> progressCallback`, `std::atomic<bool>* cancelToken`.
- `FileSplitResult`: `bool success`, `size_t chunksCreated`, `uint64_t totalBytesProcessed`, `std::wstring outputFolderPath`, `std::wstring errorMessage`.
- Header: `include/TextSplitterEngine.h`
- Implementation: `src/TextSplitterEngine.cpp`

### Win32 Custom Window Messages
- `WM_SPLIT_PROGRESS`: `wParam` = percent (0-100), `lParam` = pointer to progress status struct.
- `WM_SPLIT_COMPLETE`: `wParam` = success boolean (1/0), `lParam` = pointer to `FileSplitResult`.
- `WM_SPLIT_ERROR`: `wParam` = error code, `lParam` = pointer to error message string.

## Code Layout
```
File_Splitter_ForAI-Upload/
├── Makefile                   # MinGW build script (g++, windres)
├── README.md                  # Project overview, scope, build, usage, features
├── ORIGINAL_REQUEST.md        # Verbatim original user request
├── PROJECT.md                 # Global architecture, features, milestones
├── include/
│   ├── TextSplitterEngine.h   # Core splitting logic header
│   ├── Resource.h             # Control IDs, Menu IDs, Resource IDs
│   ├── AppWindow.h            # Main Win32 window class & procedure
│   ├── Logger.h               # EliteSoftware logging system header
│   └── Dialogs.h              # About, Help, Settings dialog headers
├── src/
│   ├── main.cpp               # WinMain entry point, STA initialization, Visual Styles
│   ├── TextSplitterEngine.cpp # Core splitting implementation
│   ├── AppWindow.cpp          # Win32 window creation, paint, control handlers, drag-drop
│   ├── Logger.cpp            # Append-only logger to %SystemDrive%\EliteSoftware\Logs\FileSplitter.log
│   └── Dialogs.cpp           # Custom dialog procedures (About expander, Help, Settings)
├── res/
│   ├── FileSplitter.rc        # Win32 resource script (menus, dialogs, manifests, icons)
│   ├── FileSplitter.manifest  # ComCtl32 v6 Visual Styles manifest
│   └── FileSplitter.ico       # Dynamic application icon
├── tests/
│   ├── test_splitter.py       # Python automated test harness (10,000 -> 3,000 char verification)
│   └── test_main.cpp          # C++ unit test runner for core engine
└── .agents/                   # Agent state, handoffs, and logs
```
