# 🔮 Upcoming Features & Implementation Plan

This document serves as the roadmap for future enhancements and planned architectural upgrades to the EliteSoftware Master Toolchain.

## 1. Web-Interface Integration (Agent-Thread HTML)
- **Goal:** Finalize the web-socket backend for Start-AgentThreadServer.exe to allow real-time browser viewing of agent pipelines, workflow history, and artifact generation.
- **Current Issue:** AI agents have difficulty maintaining the live server state. They tend to repeatedly close and re-open the server during task execution, which severs the WebSocket connection and results in lost standard output in the browser. 
- **Proposed Solution:** Refactor the server to run completely detached as a persistent daemon (similar to EliteOptiLink.exe) so agents can simply push IPC messages to it without directly managing the server process lifecycle.
- **Status:** *COMPLETE* (Refactored into AgentThread.exe C++ Daemon)


## 2. Domain-Multiplexed Toolchain Architecture (Refactor V2)
- **Goal:** Consolidate the 54 isolated EliteTools into 4 primary domain-multiplexed binaries (EliteFile.exe, EliteWin.exe, EliteRepo.exe, EliteAssets.exe) to minimize LLM sequence hallucination and token consumption.
- **MCP Native Contracts:**
  - **Self-Documenting JSON Schemas:** All binaries must natively support a --schema flag that outputs standard JSON-RPC parameter schemas so the AI never guesses arguments based on vibes.
  - **Deterministic Error Recovery:** Binaries must adopt a universal exit code taxonomy (e.g. Exit 10 = Missing Env, Exit 20 = Process Locked) and output structured JSON payloads to stderr explaining the exact failure point and remediation steps.
- **Workflow Dependency Mapping:** Define Directed Acyclic Graphs (DAGs) and Macro execution wrappers directly in GEMINI.md to prevent out-of-order execution (e.g. Version bumping before packaging).
- **Status:** *Planned Architecture Overhaul*

## 3. Documentation Bifurcation (Critique Response)
- **Goal:** Separate human-facing narrative documentation from strictly machine-readable agent protocols, as recommended by the external architectural critique.
- **Deliverables:**
  - **`architecture_decisions.md`**: Extracted engineering philosophy, design history, Frutiger Aero rationale, and migration decisions. For human developers. ✅ COMPLETE
  - **`agent_protocols.md`**: Zero-humor, strictly structured execution schemas with JSON parameter definitions, exit code taxonomy, and DAG dependency mappings. For AI agents. ⏳ IN PROGRESS
  - **`GEMINI.md` Restructure**: Resolved environment contradiction (global PATH injection is STANDARD, session-isolated `EliteEnv.cmd` is DEPRECATED). Added State Ledger Protocol. ✅ COMPLETE
- **Status:** *In Progress*

## 4. Proposed New Tools (From Architectural Critique)

### 4a. `EliteManifestSentry.exe` (DPI & Privilege Injector)
- **Goal:** Inspect compiled PE headers and directly parse/modify embedded XML manifest resources.
- **Capabilities:**
  - Inject PerMonitorV2 DPI awareness declarations
  - Declare Windows Vista/7/10/11 compatibility GUIDs
  - Set UAC execution levels (`asInvoker` or `requireAdministrator`)
- **Rationale:** Bypasses complex MSBuild post-build manifest merging. Programmatically guarantees that executables are compiled with exact scaling and security parameters. Critical for resolving UIPI Drag & Drop boundaries by keeping launchers unelevated.
- **Status:** *Proposed*

### 4b. `ElitePeHeaderGuard.exe` (Mathematical Checksum Rebase)
- **Goal:** Dedicated utility utilizing `imagehlp.dll` to recalculate PE header checksums after resource modification.
- **Rationale:** Standard resource modification (icon injection, manifest patching) breaks the binary checksum, causing Authenticode signing to fail. Chaining this tool after `ResourceAlchemyHacker_CLI.exe` and before `EliteEasySigner.exe` creates an unbreakable automated repair pipeline.
- **Note:** `EliteIconReplacer.exe` already performs checksum recalculation after icon injection. This tool generalizes that capability for ALL PE modifications.
- **Status:** *Proposed*

### 4c. `EliteWimScribe.exe` (Native WIMGAPI Backpacker)
- **Goal:** Native C++ wrapper interacting directly with Windows' `wimgapi.dll` or `cabinet.dll` to capture, compress, and append local project directories into high-density `.wim` or `.cab` archives.
- **Rationale:** Bypasses the need to shell out to heavy external executables like `dism.exe`. Captures NTFS metadata, symbolic links, and security descriptors with zero external tool dependencies, ensuring absolute backup fidelity.
- **Status:** *Proposed*

### 4d. `EliteLogRoller.exe` (Log Compressor and Rotator)
- **Goal:** Lightweight background worker monitoring `%SystemDrive%\EliteSoftware\Logs\`. When a log file exceeds a configured threshold, it automatically rolls the log, compresses older text into a native cabinet archive, and keeps the active `.log` stream fresh.
- **Rationale:** Prevents infinite log accumulation from clogging up the system drive, maintaining a pristine workstation entirely on autopilot.
- **Status:** *Proposed*

## 5. Reusable Workflow Pipelines (Macro Skill Bundles)

### 5a. "Clone, Scaff, and Sync" Pipeline
- **Sequence:** `EliteGitHubAutomator.exe init` → `EliteReadmeGenerator.exe` → `EliteSymlinker.exe` (link EliteBuild.exe) → `EliteMetaStamper.exe` (NTFS ADS tag)
- **Status:** *Proposed Macro*

### 5b. "Mutate, Rebase, and Sign" Chain
- **Sequence:** `ResourceAlchemyHacker_CLI.exe` (inject icon) → `ElitePeHeaderGuard.exe` (checksum) → `EliteEasySigner.exe` (Authenticode sign)
- **Status:** *Proposed Macro (Pending ElitePeHeaderGuard.exe)*

### 5c. "Full Build & Release" Pipeline
- **Sequence:** `EliteVersionBumper.exe` → `EliteSoftware-Compiler.exe` → `EliteRCManager.exe` → `EliteIconReplacer.exe` → `EliteEasySigner.exe` → `ElitePackager.exe` → `EliteGitHubAutomator.exe release`
- **Status:** *Documented in agent_protocols.md DAG section*
