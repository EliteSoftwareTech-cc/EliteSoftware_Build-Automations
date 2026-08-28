# Architecture Decisions Log — EliteSoftware Build Automations

## 1. The Absolute System Purity Mandate
The core philosophy of the EliteSoftware Build Automations framework is the complete rejection of bloated runtimes such as Java, Node, and Python in favor of native Win32 C++ binaries. Statically compiled unmanaged executables are mandated because they provide mathematical execution determinism, millisecond startup times, and zero runtime dependency chains. By relying on native Win32 APIs, we ensure the build pipeline remains pure, fast, and unencumbered by massive environment setups or unpredictable garbage collection cycles.

## 2. The Migration from PowerShell to Native C++
Historically, the build chain relied on monolithic PowerShell scripts (`build.ps1`), which often suffered from the infamous Windows execution policy nightmares (`Restricted` vs `RemoteSigned` vs `Bypass`). This unreliability drove the migration toward a config-driven C++ CLI architecture. While `PS2EXE` wrappers were initially used as a stopgap measure, they were eventually deprecated in favor of pure C++ compilation, completely sidestepping PowerShell Execution Policies and avoiding false-positive antivirus flagging commonly associated with wrapped PS scripts.

## 3. The Frutiger Aero Visual Standard
EliteSoftware retains a strict aesthetic philosophy celebrating the 2007-2011 skeuomorphic rebellion. Flat design is strictly forbidden. Any graphical interfaces built for the toolchain must adhere to the Frutiger Aero (and distinct from Frutiger Metro) aesthetic. This includes the mandatory use of the Title Banner, the 3D Client Edge inset, and the darker Chin panel to evoke tactile depth, gloss, and classic Windows user experience standards. 

## 4. The NTFS Alternate Data Stream Innovation
To avoid cluttering repositories with invisible metadata files (the classic `.dotfile` workspace pollution seen in Linux/Git environments), `EliteMetaStamper.exe` leverages NTFS Alternate Data Streams (ADS). This innovation allows the toolchain to invisibly tag and stamp project directories with necessary metadata directly on the file system level, keeping the visible workspace pristine and strictly containing only the source code.

## 5. The Cloudflare Integration Decision
When integrating with Cloudflare services, the official Cloudflare Wrangler CLI (which relies on Node.js) was explicitly rejected to maintain the System Purity Mandate. Instead, we implemented a lightweight native C++ REST API wrapper (the `EliteCloudManager` concept). This utilizes a God Mode Global API Key pattern, which is strictly driven by local `.config` files rather than heavy cloud-centric CLIs.

## 6. The Local LLM Sidecar Concept
The architectural vision includes embedding a tiny, specialized local language model (LLM) sidecar into the toolchain. By having a specialized model running natively, we avoid the latency, expense, and dependency of querying heavy cloud model APIs for routine workspace operations, parsing errors, or orchestration tasks.

## 7. The Environment Variable Architecture
The initialization pipeline evolved from an isolated, session-specific `EliteEnv.cmd` script into a permanent global PATH injection mechanism managed by `EliteSoftware-EnvManager_GUI.exe`. The final architectural decision is global injection (e.g., `ELITE_BUILD_X64`, `ELITE_COMPILER_PATHS`). The legacy session-isolated approach is now DEPRECATED and preserved only as a portable-mode fallback. This ensures tools are universally available from any terminal across the system without redundant configuration.

## 8. The Config-Driven Engine Philosophy
The `.config` files serve as the persistent memory bank for the toolchain. By centralizing the orchestration logic, targets, and parameters into a machine-readable JSON/config file (e.g., `EliteBuild.config`), we eliminate the need for LLMs or human developers to carry complex orchestration scripts in their working context. CLI arguments passed to the tools act purely as overrides to these smart defaults.

## 9. The --ai-mode Handshake Protocol
Every native CLI tool within the ecosystem natively implements the `--ai-mode` flag. This flag is an essential handshake protocol designed specifically for autonomous LLM agents. Passing `--ai-mode` instantly bypasses mandatory EULA dialogs, suppresses all interactive prompts, and guarantees headless autonomous execution without risking infinite terminal deadlocks waiting for standard input.

## 10. The Domain-Multiplexed Architecture (V2 Vision)
The current ecosystem comprises 54 highly atomized C++ CLI binaries. To prevent sequence hallucination and vastly improve token economics for MCP integrations, the V2 architecture mandates a consolidation into exactly 4 domain-multiplexed binaries:
- `EliteFile.exe` (I/O, splitting, syncing)
- `EliteWin.exe` (NT System operations, processes, registry)
- `EliteRepo.exe` (Repository lifecycle, versioning, releasing)
- `EliteAssets.exe` (PE/Resource surgery, icons, manifest patching)

These binaries will natively emit JSON-RPC schemas and deterministic JSON error payloads to `stderr`, completely removing guesswork from LLM integration.
