# Agent-Thread HTML Dashboard & Inter-Agent Communication Specification

## Overview
`Agent-Thread_HTML` provides a live, interactive web-based monitoring dashboard (`index.html`) for visualizing real-time agent communications, handoff reports, and historical project logs for the **File Splitter For AI Upload** project (EliteSoftwareTech Co.).

The interface features a 4-tab architecture:
- **Tab 1: Live Agent Thread**: Displays real-time message feeds from active agents with role badges, color coding, status indicators, and agent filtering.
- **Tab 2: Historical Inter-Communications & Handoffs**: Displays the complete chronological record of milestone handoffs, architectural decisions, and verification logs.
- **Tab 3: Build Artifacts & Version History**: Displays all active compiled binaries (`BuildOutput/FileSplitter.exe` 64-bit, `BuildOutputx86/FileSplitter.exe` 32-bit, `test_engine.exe`), target PE machine architectures, file sizes, SHA256 hashes, and version history logs.
- **Tab 4: Project Plan & Outline**: Displays overall project status, milestone breakdown, 26-feature requirements matrix, and acceptance criteria verification results.

---

## Directory Structure
```
Agent-Thread_HTML/
├── index.html           # Interactive single-page web dashboard (HTML5/CSS3/JS)
├── thread_data.json     # Live agent thread message store
├── history_data.json    # Historical inter-agent communication & handoff store
├── artifacts_data.json  # Build artifacts & version history store
├── plan_data.json       # Project plan, milestones, feature matrix & criteria store
└── gemini.md            # Architecture specification & data schema manual
```

---

## Data Schemas

### 1. `thread_data.json` Schema
```json
{
  "project": "File Splitter For AI Upload",
  "version": "1.2.0.0",
  "company": "EliteSoftwareTech Co.",
  "last_updated": "2026-07-29T12:13:00Z",
  "agents": [
    {
      "id": "agent_identifier",
      "name": "Human Readable Agent Name",
      "role": "Agent Role / Specialty",
      "color": "#HEX_COLOR_CODE"
    }
  ],
  "threads": [
    {
      "id": "msg-XXX",
      "timestamp": "ISO-8601 UTC Timestamp",
      "sender_id": "agent_id",
      "recipient": "recipient_id_or_all",
      "subject": "Message Title",
      "content": "Message body text...",
      "status": "complete | in_progress | verified"
    }
  ]
}
```

### 2. `history_data.json` Schema
```json
{
  "project": "File Splitter For AI Upload",
  "history": [
    {
      "milestone": "M1 | M2 | M3 | M4 | M5",
      "timestamp": "ISO-8601 UTC Timestamp",
      "sender": "Agent Name",
      "recipient": "Recipient Name",
      "action": "Summary of Action",
      "details": "Full handoff or log details..."
### 3. `artifacts_data.json` Schema
```json
{
  "project": "File Splitter For AI Upload",
  "version": "1.2.0.0",
  "last_updated": "ISO-8601 UTC Timestamp",
  "artifacts": [
    {
      "name": "Artifact Name",
      "path": "Relative / Absolute Path",
      "architecture": "PE Target Architecture",
      "size": "File Size",
      "target_os": "Target Operating Systems",
      "status": "Release Status",
      "sha256": "SHA256 Checksum",
      "description": "Artifact Description"
    }
  ],
  "version_history": [
    {
      "version": "Version Tag",
      "timestamp": "ISO-8601 UTC Timestamp",
      "changes": "Summary of Changes",
      "build_notes": "Compilation & Test Notes"
    }
  ]
}
```

### 4. `plan_data.json` Schema
```json
{
  "project": "File Splitter For AI Upload",
  "version": "1.2.0.0",
  "company": "EliteSoftwareTech Co.",
  "status": "100% COMPLETE & VERIFIED",
  "milestones": [
    { "id": "M1", "name": "Milestone Name", "scope": "Scope Description", "status": "DONE", "progress": 100 }
  ],
  "feature_matrix": [
    { "id": 1, "name": "Feature Name", "milestone": "M1", "status": "Implemented & Verified" }
  ],
  "acceptance_criteria": [
    { "criterion": "Criteria Requirement Statement", "status": "PASSED" }
  ]
}
```

---

## Auto-Reloading Mechanism & Continuous PowerShell Service

The dashboard (`index.html`) implements a smooth, zero-flicker live auto-reload mechanism powered by a continuous background PowerShell service:
1. **Dynamic Polling**: Automatically polls `thread_data.json`, `history_data.json`, `artifacts_data.json`, and `plan_data.json` every 3 seconds via `setInterval()`.
2. **Cache-Busting**: Appends a `?t=Date.now()` timestamp query parameter to `fetch()` calls to prevent browser HTTP caching and ensure instant visibility of new agent posts across all 4 HTML tabs.
3. **Toggle Controls**: Includes an interactive header badge (`LIVE AUTO-RELOAD: ON (3s)`) allowing users to pause or resume live stream auto-reloading at any time.
4. **Continuous PowerShell Service (`Scripts/LiveThreadWatcher.ps1`)**:
   - Runs continuously in the background scanning `.agents/` handoffs and logs, `BuildOutput/` (64-bit), `BuildOutputx86/` (32-bit), `plan.md`, `PROJECT.md`, and `progress.md`.
   - Automatically parses and synchronizes state updates into `thread_data.json`, `history_data.json`, `artifacts_data.json`, and `plan_data.json`.
   - Execution command: `powershell -ExecutionPolicy Bypass -File .\Scripts\LiveThreadWatcher.ps1 -IntervalSeconds 3`.

## Local Network HTTP Server Hosting (`StartHttpServer.ps1`)

The dashboard is served via a local HTTP service bound to all network interfaces (`0.0.0.0`) to ensure accessibility across the local network:
1. **Background Service Script**: `Scripts/StartHttpServer.ps1` runs `python -m http.server 8888 --bind 0.0.0.0` serving the `Agent-Thread_HTML/` directory.
2. **Access Endpoints**:
   - Local Machine: `http://localhost:8888` or `http://127.0.0.1:8888`
   - Local Area Network (LAN): `http://<Host-IP-Address>:8888`
3. **Execution Command**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Scripts\StartHttpServer.ps1 -Port 8888
   ```

---

## Mandatory Verbose Logging Guidelines

All agents participating in the project MUST output exceptionally rich, detailed, and comprehensive turn summaries to `Agent-Thread_HTML/thread_data.json` and `Agent-Thread_HTML/history_data.json`:
1. **Technical Specifications**: Include exact C++ struct definitions, Win32 API functions, buffer sizes, and character encoding mechanics.
2. **Architectural Choices**: Document rationale for UI layouts (Title Banner, 3D Inset, Darker Chin, Segoe UI, tooltips), dynamic icon sideloading, thread messaging (`WM_USER`), and PowerShell build script chain.
3. **Verification Commands & Output**: Include exact PowerShell / CMD compilation commands (`g++`, `windres`, `Build.ps1`), test runner outputs (`test_engine.exe`, `test_splitter.py`), and PE machine header values (`0x8664` vs `0x014C`).
4. **Logic Chains & File Diffs**: Detail step-by-step reasoning for bug fixes, edge-case resolutions, and file modifications.
5. **Dynamic Rendering**: The dashboard (`index.html`) auto-reloads every 3 seconds via cache-busting `fetch()`, presenting this rich feed continuously to developers and users.
