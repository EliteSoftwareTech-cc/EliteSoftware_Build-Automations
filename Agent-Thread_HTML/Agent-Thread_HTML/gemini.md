# Agent-Thread HTML Dashboard & Inter-Agent Communication Specification

## Overview
`Agent-Thread_HTML` provides a live, interactive web-based monitoring dashboard (`index.html`) for visualizing real-time agent communications, handoff reports, and historical project logs for the **File Splitter For AI Upload** project (EliteSoftwareTech Co.).

The interface features a dual-tab architecture:
- **Tab 1: Live Agent Thread**: Displays real-time message feeds from active agents with role badges, color coding, status indicators, and agent filtering.
- **Tab 2: Historical Inter-Communications & Handoffs**: Displays the complete chronological record of milestone handoffs, architectural decisions, and verification logs.

---

## Directory Structure
```
Agent-Thread_HTML/
├── index.html         # Interactive single-page web dashboard (HTML5/CSS3/JS)
├── thread_data.json   # Live agent thread message store
├── history_data.json  # Historical inter-agent communication & handoff store
└── gemini.md          # Architecture specification & append instructions
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
    }
  ]
}
```

---

## Agent Appending Guidelines

When an agent completes a task or sends an inter-agent update:
1. Load `Agent-Thread_HTML/thread_data.json` or `Agent-Thread_HTML/history_data.json`.
2. Append a new message entry into the `threads` array (or `history` array).
3. Update `"last_updated"` with the current UTC timestamp.
4. Save the file back to `Agent-Thread_HTML/`.

The dashboard (`index.html`) automatically renders new entries dynamically.
