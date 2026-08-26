<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware-EasySigner

**Information-First Engineering. Absolute System Purity.**

Welcome to the official source repository for **EliteSoftware-EasySigner**. 
This project serves as the digital station for EliteSoftware's engineering initiatives, providing a dedicated CLI tool (`EliteEasySigner.exe`) to handle all Authenticode `.exe` and `.dll` signing.

### 🔗 Quick Links
- 📖 [Continuous Changelog](changelog.md)
- 🌐 [Official Web Landing Page](index.html)

## 🚀 Mission Protocol
To replace the bloated WinForms GUI of the original Elite-EasySigner with a lightning-fast, C++ native CLI executable that embeds its own dependencies (`signtool.exe` and `EliteSoftware_Special.pfx`) to achieve true portability.

### Core Focus Areas:
- **System Purity:** Zero external dependencies. Resources are packed natively into the `.exe`.
- **Automation:** Smart fallback logic between SHA256 (Method A) and SHA1 (Legacy Method) signing. Non-blocking failure handling.
- **Modern Hybridization:** Blending classic C++ resource compilation (`windres`) with modern CI/CD deployment logic.

## 🛠️ Workstation Profile 
- **Automation:** Native C++ (Compiled via `g++` / MinGW)
- **Frameworks:** Windows CryptoAPI / SignTool
- **Languages:** C++

## 🌐 Global Conduits 
- **YouTube:** [EliteSoftware Channel](https://www.youtube.com/channel/UCkCJHfNFwSAJ2fu4kXmEaUg)
- **Main Portal:** [elitesoftwaretech.cc](https://MAIN.elitesoftwaretech.cc)

## 📡 Deployment Information
This utility is designed for high-density deployment in build pipelines.

### Local Development 
1. Run `build.ps1` to compile `EliteEasySigner.exe` natively using `g++` and `windres`.
2. Execute `EliteEasySigner.exe --file "MyCompiledApp.exe"`.

--- 
**Lead:** Zachary Whiteman 
**Region:** Fingerlakes, NY   *"Density is efficiency."*
