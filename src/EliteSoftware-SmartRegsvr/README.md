<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware-SmartRegsvr

**Information-First Engineering. Absolute System Purity.**

Welcome to the official source repository for **EliteSoftware-SmartRegsvr**. 
This project serves as the digital station for EliteSoftware's engineering initiatives, providing a dedicated CLI tool (EliteSmartRegsvr.exe) to handle intelligent PE/DLL registration routing based on system architecture.

### ?? Quick Links
- ?? [Official Web Landing Page](index.html)

## ?? Mission Protocol
Automatically detects whether a dropped PE/DLL file is 32-bit or 64-bit and routes it to the correct 
egsvr32.exe (SysWOW64 for 32-bit, System32 for 64-bit).

### Core Focus Areas:
- **System Architecture Routing:** Dynamically parses the PE headers of the target DLL to determine bitness.
- **Automation:** Bypasses manual terminal hunting and guarantees the correct regsvr32 execution context.

## ??? Workstation Profile 
- **Automation:** Native C++ CLI
- **Frameworks:** Windows Win32 API / PE Parsing
- **Languages:** C++

## ?? Deployment Information
This utility acts as a Smart Drop Handler (DLL/PE Register) for your system.

### Usage & Arguments

**Supported Flags (Extracted from Source):**
- `--file`
- `--ai-mode`

1. Execute EliteSmartRegsvr.exe --file <path> to automatically register the DLL.

--- 
**Lead:** Zachary Whiteman 
**Region:** Fingerlakes, NY   *"Density is efficiency."*
