#include <iostream>
#include <fstream>
#include <string>
#include <regex>

using namespace std;

void PrintHelp() {
    cout << "========================================" << endl;
    cout << " EliteBuild ReadmeGenerator (Native C++)" << endl;
    cout << "========================================" << endl;
    cout << "Usage: EliteReadmeGenerator.exe <TemplateID> <ProjectName> [Tagline]" << endl;
    cout << "  <TemplateID> : 1 to 5" << endl;
    cout << "                 1 = Master Hybrid (Architecture & GUI)" << endl;
    cout << "                 2 = Legacy GUI Application" << endl;
    cout << "                 3 = Headless CLI Tool" << endl;
    cout << "                 4 = Client/Server Architecture" << endl;
    cout << "                 5 = Automation & Shell Extension" << endl;
    cout << "  <ProjectName>: e.g., Elite-Taskbar" << endl;
    cout << "  [Tagline]    : Optional tagline." << endl;
    cout << endl;
    cout << "Generates a perfectly formatted readme.md in the current directory." << endl;
}

// ==========================================
// TEMPLATE 1: MASTER HYBRID (From User Spec)
// ==========================================
const char* TEMPLATE_1 = R"REGEX(<div align="center">

<a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 

# **__PROJECT_NAME__**

*__TAGLINE__*

</div>

---

## 🏢 Core Information 

* **Company**: EliteSoftware / EliteSoftwareTech Co. 
* **Authors**: Zachary Whiteman, Susan Gemm, TheShadyRainbow4, EliteSoftwareTech Co.  
* **Document Version**: 1.0.0.0  
* **Target OS**: Windows 10 IoT Enterprise LTSC (Legacy compatible with Vista / 7)
* **Core Technologies**: Native Unmanaged C++, .NET Framework 4.6 WinForms or Native Windows Functions

---

## 🚀 __PROJECT_NAME__ Deep Dive & Features

### 🖼️ Core Features & Capabilities

__PROJECT_NAME__ is designed from the ground up to seamlessly blend into the Windows environment, providing a perfect legacy Aero Glass experience while retaining 100% of the functionality expected from the Windows Shell.

<details>
<summary><b>1. Core Feature Set</b></summary>
* **System Integration**: Deep integration with the Win32 API.
* **Fallback Mechanisms**: Integrated custom modules for graceful degradation.
</details>

<details>
<summary><b>2. Visual & Theming Engine</b></summary>
* **GDI & GDI+ Drawing**: Pixel-perfect UI elements.
* **High DPI Awareness**: `PerMonitorV2` compliance ensuring crisp text and imagery across multi-monitor setups.
</details>

<details>
<summary><b>3. Advanced Settings & Configuration</b></summary>
* **EliteSettings Applet**: A dedicated CPL and EXE properties menu utilizing classic WinForms.
* **Aggressive Registry Sync**: Writes settings dynamically to `HKCU` to perfectly match native Explorer behaviors.
</details>

---

## 🏗️ Building the Project

**CRITICAL REQUIREMENT:** The entire build process for **all** `.exe` files in the entire project and all subfolders **MUST BE MANAGED BY** `build.ps1` and nothing else! Do not run individual build scripts manually.

Run the `build.ps1` script in the root directory to compile the project. The script acts as the master orchestrator, handling parallel builds, icon injection, code signing, and automatic backups.

Output binaries will be placed flat in the root directory and in the `BuildOutput/` directories.

---

## 📁 Directory Structure
- `__PROJECT_NAME__/`: Source code for the primary module.
- `Resources/`: Icons and visual assets.
- `Documentation/`: Build requirements, checklists, and architectural ledgers.
- `Backups/`: Historical CAB backups of the project state generated automatically before each build.

---

## 📜 Architecture Principles
__PROJECT_NAME__ strictly follows the EliteSoftwareTech Co. development guidelines:
* **No Generic UI**: Avoids modern flat design entirely.
* **DPI Awareness**: Manifests ensure `PerMonitorV2` DPI scaling.
* **Native Win32**: Deep hooks and subclassing to ensure stability.

---

## 🤖 A Note on "Vibe Coding"
This project was built in close collaboration with Google's Gemini. Many features, design choices, and lines of code were generated or heavily influenced by AI. The goal was less about perfect, clean code and more about exploring the creative potential of human-AI partnership. It's an experiment in letting the "vibe" of an idea guide the development process.

Expect the unexpected. Embrace the chaos. And have fun!

---

## 📸 Media Assets

<div align="center">
<!-- Embed Images Here -->
</div>

---
*License: Proprietary - EliteSoftwareTech Co.*

## Architecture
- `__PROJECT_NAME___App/`: Win32 / C++ Windows Application & Server (uses Win32 API, GDI+)
- Data Store: `__PROJECT_NAME___App/db.json` and static image assets

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | M1.1 Initial Feature | Initialize core routing | M1 | Engine |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Core Implementation | Base architecture | none | DONE |

## Interface Contracts
### Module A ↔ Module B
- `GET /api/status` -> JSON array

## Code Layout
- `main.cpp` — Main Win32 window, threads, UI layout, Win32 controls
- `build.bat` — MinGW build script
)REGEX";

// ==========================================
// TEMPLATE 2: LEGACY GUI APPLICATION
// ==========================================
const char* TEMPLATE_2 = R"REGEX(<div align="center">
<a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 
# **__PROJECT_NAME__**
*__TAGLINE__*
</div>

---

## 🏢 Core Information 
* **Company**: EliteSoftware / EliteSoftwareTech Co. 
* **Authors**: Zachary Whiteman, Susan Gemm, TheShadyRainbow4
* **Target OS**: Windows Vista / 7 / 10 IoT Enterprise
* **Core Technologies**: .NET Framework 4.6 WinForms (Legacy Aesthetic)

## 🎨 Visual & Aesthetic Compliance
__PROJECT_NAME__ is strictly bound to the EliteSoftware GUI guidelines:
* **3D Inset Client Edge**: Classic Win32 control shadowing.
* **The "Chin"**: Anchored footer for standard nomenclature buttons.
* **Dynamic Segoe UI**: Fallback capable layout handling.

## 🏗️ Compilation
Managed by the master `build.ps1` in the repository root utilizing PS2EXE (-STA mode, -noConsole) or MSBuild.

## 🤖 Vibe Coding
Built in partnership with Google's Gemini. Embrace the chaos. Have fun.
)REGEX";

// ==========================================
// TEMPLATE 3: HEADLESS CLI TOOL
// ==========================================
const char* TEMPLATE_3 = R"REGEX(<div align="center">
<a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 
# **__PROJECT_NAME__**
*__TAGLINE__*
</div>

---

## 🏢 Core Information 
* **Company**: EliteSoftwareTech Co.
* **Target OS**: Windows 10+
* **Core Technologies**: Native Unmanaged C++ (CLI Engine)

## ⚙️ Execution & Architecture
__PROJECT_NAME__ is a completely headless, argument-driven CLI utility. 
* **No Dependencies**: Statically linked for absolute portability.
* **Regex Engine**: Highly optimized file I/O scanning capabilities.
* **Environment Hooks**: Relies on `%ELITE_BUILD_X64%` and system path vars.

## 📋 Arguments & Usage
* `/help, -?, --help`: View all available arguments.
* Execute natively from terminal.

## 🏗️ Compilation
Compiled strictly via `g++` (MinGW) orchestrator via `build.ps1`.
)REGEX";

// ==========================================
// TEMPLATE 4: CLIENT/SERVER ARCHITECTURE
// ==========================================
const char* TEMPLATE_4 = R"REGEX(<div align="center">
<a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 
# **__PROJECT_NAME__**
*__TAGLINE__*
</div>

---

## 🏢 Core Information 
* **Company**: EliteSoftwareTech Co. 
* **Architecture**: HTTP/UDP Multi-Node System

## 🌐 Interface Contracts
### Manager ↔ Client Node
- `POST /api/heartbeat` -> Body JSON `{"client_id":"..."}`
- `POST /api/disconnect` -> Purge connection state.

## 📁 Repository Layout
- `Manager_App/`: Win32 / C++ Server Node.
- `Client_App/`: Remote/Mobile Client Application.
- `db.json`: Local storage schema.

## 🤖 Vibe Coding
Built in close collaboration with Google's Gemini. Expect the unexpected.
)REGEX";

// ==========================================
// TEMPLATE 5: AUTOMATION & SHELL EXTENSION
// ==========================================
const char* TEMPLATE_5 = R"REGEX(<div align="center">
<a href='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' target='_blank'><img src='https://i.postimg.cc/DZTjtNg1/Elite-Software-Company-Simulator-LOGO.png' border='0' alt='Elite-Software-Client' width="200"></a> 
# **__PROJECT_NAME__**
*__TAGLINE__*
</div>

---

## 🏢 Core Information 
* **Company**: EliteSoftwareTech Co. 
* **Integration Level**: Ring-3 Windows Shell Namespace

## 🔧 Shell Extension Modding
__PROJECT_NAME__ heavily modifies `HKEY_LOCAL_MACHINE\Software\Classes` to hijack native folder execution and context menus.
* **Aggressive Registry Sync**: Forces global settings override.
* **Win32 Hooks**: Subclasses `SHELLDLL_DefView` for drawing interceptions.

## 🏗️ Test Suite & Automation
* Includes E2E Verification Scripts (`run_comprehensive_e2e.ps1`).
* Uses `verify_final_polish.ps1` for environment validation prior to commits.

## 🤖 Vibe Coding
Developed aggressively alongside Google's Gemini. Absolute System Purity.
)REGEX";

int main(int argc, char* argv[]) {
    if (argc < 3) {
        PrintHelp();
        return 1;
    }

    string templateIdStr = argv[1];
    string projectName = argv[2];
    string tagline = (argc >= 4) ? argv[3] : "An EliteSoftware Engineering Initiative.";

    if (templateIdStr == "/help" || templateIdStr == "-help" || templateIdStr == "-?") {
        PrintHelp();
        return 0;
    }

    int templateId = 1;
    try {
        templateId = stoi(templateIdStr);
    } catch (...) {
        cerr << "[ReadmeGenerator] ERROR: Invalid Template ID." << endl;
        return 1;
    }

    string selectedTemplate;
    switch (templateId) {
        case 1: selectedTemplate = TEMPLATE_1; break;
        case 2: selectedTemplate = TEMPLATE_2; break;
        case 3: selectedTemplate = TEMPLATE_3; break;
        case 4: selectedTemplate = TEMPLATE_4; break;
        case 5: selectedTemplate = TEMPLATE_5; break;
        default:
            cerr << "[ReadmeGenerator] ERROR: Template ID must be 1-5." << endl;
            return 1;
    }

    // Replace Placeholders
    selectedTemplate = regex_replace(selectedTemplate, regex("__PROJECT_NAME__"), projectName);
    selectedTemplate = regex_replace(selectedTemplate, regex("__TAGLINE__"), tagline);

    // Write to readme.md
    ofstream outFile("readme.md");
    if (!outFile.is_open()) {
        cerr << "[ReadmeGenerator] ERROR: Could not open readme.md for writing in current directory." << endl;
        return 1;
    }

    outFile << selectedTemplate;
    outFile.close();

    cout << "[ReadmeGenerator] Successfully generated readme.md using Template " << templateId << " for project '" << projectName << "'!" << endl;
    return 0;
}
