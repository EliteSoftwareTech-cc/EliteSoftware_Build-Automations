<div align="center"> <a href='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' target='_blank'><img src='https://i.postimg.cc/85mKDbX8/EliteSoftware-Company-Logo.png' height='80' border='0' alt='Elite-Software-Company-Logo'></a> </div>

# EliteSoftware EasySigner (CLI Component)

**Information-First Engineering. Absolute System Purity.**

This document details the **EliteEasySigner** CLI tool. Written in native C++, it replaces the heavy PowerShell/WinForms utility from the original `Elite-EasySigner` project with a seamless, pipeline-ready executable.

## 🛠️ Tool Features

- **Resource Embedding:** The tool bundles `signtool.exe` and the `EliteSoftware_Special.pfx` certificate directly inside the executable's `.rc` payload, leaving zero external dependencies.
- **Fail-Safe Mechanism:**
  - **Method A:** Attempts modern SHA256 signing with RFC3161 Digicert timestamping.
  - **Legacy Method:** If Method A fails, it falls back to SHA1 Authenticode timestamping.
  - **Pipeline Continuation:** If both methods fail, the tool throws a detailed error to stdout/stderr but explicitly returns a `0` (Success) exit code to prevent the CI/CD pipeline from halting, delivering the unsigned file with an alert.
- **Argument-Driven Overrides:** The target file and PFX passwords can be explicitly defined via arguments.
- **Comprehensive Help System:** Global help guides built into the executable.

## 📜 Command Reference

The tool responds to `/help`, `//help`, `-help`, `--help`, `-?`, and `--?` anywhere to print detailed instructions.

### Usage
`EliteEasySigner.exe --file <path> [options]`

**Options:**
- `--file <path>`: **(Required)** The target `.exe` or `.dll` to sign.
- `--password <string>`: **(Optional)** Overrides the internal EliteSoftware `Minecraft145!!` default password for the embedded `.pfx`.

## 🧠 Component Philosophy
This CLI embodies the EliteSoftware goal of eliminating massive, nested PowerShell scripts. By embedding the `.pfx` and `signtool.exe` as C++ resources, the utility is 100% standalone and portable across all EliteSoftware projects.
