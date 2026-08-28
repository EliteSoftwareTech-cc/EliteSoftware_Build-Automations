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
