# Test Infrastructure & Specification (`TEST_INFRA.md`)

## Overview
This document specifies the end-to-end (E2E) automated testing strategy, architecture, and multi-tier test matrix for the **File Splitter For AI Upload** project. 

The test infrastructure encompasses both native C++ engine unit tests (`test_engine.exe` and `stress_harness.exe`) and Python-driven E2E integration verification (`tests/test_splitter.py`).

---

## Test Architecture & Tiering Matrix

```
                      +------------------------------------------+
                      |      python tests/test_splitter.py       |
                      |        (Python 3.14 E2E Harness)         |
                      +--------------------+---------------------+
                                           |
                                 Executes / Asserts
                                           v
  +----------------------------------------+----------------------------------------+
  |                                                                                 |
  v                                                                                 v
+-----------------------------------+                             +-----------------------------------+
|         test_engine.exe           |                             |        stress_harness.exe         |
|  (C++ Unit & CLI Splitter Engine) |                             | (Empirical Stress & Perf Harness) |
+-----------------------------------+                             +-----------------------------------+
```

---

## Test Tiers

### Tier 1: Feature Coverage (Core Functional Requirements)
* **T1.1: Standard 10k Character Splitting**: Split 10,000-character text file by 3,000-character limit into a dedicated subfolder (`<stem>_parts`).
  * *Verification*: Asserts exactly 4 chunks (`_part_001.txt` [3000], `_part_002.txt` [3000], `_part_003.txt` [3000], `_part_004.txt` [1000]).
  * *Identity Check*: Binary concatenation of chunks equals original 10,000-character input.
* **T1.2: Standard Line-Based Splitting**: Split 350-line file by 100-line limit.
  * *Verification*: Asserts exactly 4 chunks (100, 100, 100, 50 lines). Binary concatenation match.
* **T1.3: Subfolder Generation**: Automatic creation of `<OriginalFilename>_parts` directory in input or specified output folder.
* **T1.4: Batch File Processing**: Sequential batch execution of multiple input files with isolated output subfolders.

---

### Tier 2: Boundary & Corner Cases
* **T2.1: Exact Multiple Boundary**: Split 9,000-character file by 3,000-character limit.
  * *Verification*: Asserts exactly 3 chunks (3000, 3000, 3000 characters) with zero leftover empty files.
* **T2.2: Single Byte Input**: Split 1-byte file.
  * *Verification*: Asserts 1 chunk created containing 1 byte.
* **T2.3: Empty Input File (0 bytes)**: Process 0-byte input file.
  * *Verification*: Asserts 0 chunks created without crash or file creation error.
* **T2.4: UTF-8 Multibyte Preservation**: Split UTF-8 strings containing multi-byte characters (2-byte, 3-byte, and 4-byte emoji `🌟`).
  * *Verification*: Ensures codepoint boundaries are respected without splitting multi-byte sequences mid-character.
* **T2.5: Line Ending Preservation**: CRLF (`\r\n`) and LF (`\n`) handling without newline corruption.
* **T2.6: Overwrite Protection**: Verify `overwriteExisting = false` raises error when target chunk files pre-exist.

---

### Tier 3: Cross-Feature & Error Isolation
* **T3.1: Thread Cancellation**: Immediate and mid-stream atomic cancellation tokens cleans up partial chunk files from disk.
* **T3.2: Batch Isolation**: Ensure invalid/missing files in a batch do not halt processing of subsequent valid files.
* **T3.3: Invalid Parameter Handling**: Verify clear error messages and non-zero exit codes for limit = 0 or missing files.

---

### Tier 4: Real-World Workloads & Performance
* **T4.1: Large File Streaming Performance**: 10 MB file split benchmark measuring throughput (MB/s) with 64 KB memory buffer.
* **T4.2: Filename Sanitization**: Automatic replacement of invalid path characters (`:`, `*`, `?`, `<`, `>`, `|`) with underscores.

---

## Execution Commands

### 1. Execute Python 3.14 E2E Test Suite
```pwsh
python tests/test_splitter.py
```

### 2. Execute C++ Engine Unit Test Runner
```pwsh
.\test_engine.exe
```

### 3. Execute Empirical Stress & Performance Harness
```pwsh
.\stress_harness.exe
```

---

## Verification Criteria & Acceptance Gate

To satisfy Milestone 2 acceptance criteria, all tests must pass with:
1. Exit code `0` across all test runners.
2. 100% byte-for-byte identity on binary concatenation reassembly.
3. Strict adherence to maximum chunk size constraints (chunk size <= limit).
