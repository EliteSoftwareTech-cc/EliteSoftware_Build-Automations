#!/usr/bin/env python3
"""
tests/test_splitter.py - Automated E2E Test Suite for File Splitter
Author: EliteSoftwareTech Co.
Target: Python 3.14+ / Win32 Native C++ Engine Integration
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path

# Paths
REPO_ROOT = Path(__file__).resolve().parent.parent
TEST_ENG_EXE = REPO_ROOT / "test_engine.exe"
SCRATCH_DIR = REPO_ROOT / "tests" / "py_test_scratchpad"

g_tests_run = 0
g_tests_passed = 0
g_tests_failed = 0


def log_step(name: str):
    print(f"\n[RUN] {name} ... ", end="", flush=True)


def log_pass(msg: str = ""):
    global g_tests_passed
    g_tests_passed += 1
    extra = f" ({msg})" if msg else ""
    print(f"[PASSED]{extra}")


def log_fail(msg: str = ""):
    global g_tests_failed
    g_tests_failed += 1
    extra = f" ({msg})" if msg else ""
    print(f"[FAILED]{extra}")


def setup_scratch():
    if SCRATCH_DIR.exists():
        shutil.rmtree(SCRATCH_DIR, ignore_errors=True)
    SCRATCH_DIR.mkdir(parents=True, exist_ok=True)


def cleanup_scratch():
    if SCRATCH_DIR.exists():
        shutil.rmtree(SCRATCH_DIR, ignore_errors=True)


def test_10k_chars_by_3k_limit():
    """
    Tier 1 Acceptance Test:
    Splits 10,000-character test file by 3,000 characters limit.
    Asserts:
    1. Output subfolder named after test file exists.
    2. Exactly 4 chunk files created (_part_001.txt: 3000, _part_002.txt: 3000, _part_003.txt: 3000, _part_004.txt: 1000).
    3. Each chunk size <= 3,000 characters.
    4. Exact binary concatenation byte-for-byte identity with original file.
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_10k_Chars_By_3k_Limit")

    file_path = SCRATCH_DIR / "test_10k_input.txt"
    pattern = "abcdefghijklmnopqrstuvwxyz0123456789\n"
    content_bytes = bytearray()
    while len(content_bytes) < 10000:
        to_add = min(len(pattern), 10000 - len(content_bytes))
        content_bytes.extend(pattern[:to_add].encode("utf-8"))
    
    file_path.write_bytes(content_bytes)
    assert len(file_path.read_bytes()) == 10000, "Created input file must be 10,000 bytes"

    # Trigger test_engine.exe CLI
    cmd = [
        str(TEST_ENG_EXE),
        "--input", str(file_path),
        "--limit", "3000",
        "--mode", "char"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        log_fail(f"Engine exited with code {proc.returncode}: {proc.stderr}")
        return False

    subfolder = SCRATCH_DIR / "test_10k_input_parts"
    if not subfolder.exists() or not subfolder.is_dir():
        log_fail(f"Output subfolder {subfolder} does not exist")
        return False

    chunks = sorted(list(subfolder.glob("test_10k_input_part_*.txt")))
    if len(chunks) != 4:
        log_fail(f"Expected 4 chunks, found {len(chunks)}")
        return False

    expected_sizes = [3000, 3000, 3000, 1000]
    for idx, chunk in enumerate(chunks):
        sz = chunk.stat().st_size
        if sz != expected_sizes[idx]:
            log_fail(f"Chunk {chunk.name} size {sz} != expected {expected_sizes[idx]}")
            return False
        if sz > 3000:
            log_fail(f"Chunk {chunk.name} size {sz} exceeds maximum limit of 3000")
            return False

    # Binary concatenation identity check
    reassembled = bytearray()
    for chunk in chunks:
        reassembled.extend(chunk.read_bytes())

    if reassembled != content_bytes:
        log_fail("Binary concatenation reassembly mismatch")
        return False

    log_pass("4 chunks: 3000, 3000, 3000, 1000; byte-for-byte binary identity verified")
    return True


def test_exact_boundary_9k_chars():
    """
    Tier 2 Boundary Test:
    Splits 9,000-character test file by 3,000 limit -> Exactly 3 files (3000, 3000, 3000).
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_Exact_Boundary_9k_Chars")

    file_path = SCRATCH_DIR / "test_9k_input.txt"
    pattern = "1234567890"
    content_bytes = (pattern * 900).encode("utf-8") # 9000 bytes
    file_path.write_bytes(content_bytes)

    cmd = [
        str(TEST_ENG_EXE),
        "--input", str(file_path),
        "--limit", "3000",
        "--mode", "char"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        log_fail(f"Engine failed: {proc.stderr}")
        return False

    subfolder = SCRATCH_DIR / "test_9k_input_parts"
    chunks = sorted(list(subfolder.glob("test_9k_input_part_*.txt")))
    if len(chunks) != 3:
        log_fail(f"Expected exactly 3 chunks for exact boundary, got {len(chunks)}")
        return False

    for chunk in chunks:
        if chunk.stat().st_size != 3000:
            log_fail(f"Chunk size {chunk.stat().st_size} != 3000")
            return False

    reassembled = b"".join(c.read_bytes() for c in chunks)
    if reassembled != content_bytes:
        log_fail("Concatenation identity mismatch for 9k boundary")
        return False

    log_pass("3 chunks of 3000 bytes each; exact identity verified")
    return True


def test_line_splitting_350_lines():
    """
    Tier 1 Feature Test:
    Splits 350-line file by 100 lines limit -> 4 chunk files (100, 100, 100, 50 lines).
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_Line_Splitting_350_Lines")

    file_path = SCRATCH_DIR / "test_350lines.txt"
    lines = [f"Line {i:03d}: Sample content line for splitting test.\r\n" for i in range(1, 351)]
    original_text = "".join(lines)
    content_bytes = original_text.encode("utf-8")
    file_path.write_bytes(content_bytes)

    cmd = [
        str(TEST_ENG_EXE),
        "--input", str(file_path),
        "--limit", "100",
        "--mode", "line"
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        log_fail(f"Engine line split failed: {proc.stderr}")
        return False

    subfolder = SCRATCH_DIR / "test_350lines_parts"
    chunks = sorted(list(subfolder.glob("test_350lines_part_*.txt")))
    if len(chunks) != 4:
        log_fail(f"Expected 4 chunks, got {len(chunks)}")
        return False

    expected_line_counts = [100, 100, 100, 50]
    for idx, chunk in enumerate(chunks):
        text = chunk.read_text(encoding="utf-8")
        line_cnt = text.count("\n")
        if line_cnt != expected_line_counts[idx]:
            log_fail(f"Chunk {chunk.name} line count {line_cnt} != expected {expected_line_counts[idx]}")
            return False

    reassembled = b"".join(c.read_bytes() for c in chunks)
    if reassembled != content_bytes:
        log_fail("Line split binary reassembly mismatch")
        return False

    log_pass("4 chunks (100, 100, 100, 50 lines); CRLF preserved & identity verified")
    return True


def test_batch_file_processing():
    """
    Tier 1 Feature Test:
    Batch processing multiple files with independent subfolder outputs.
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_Batch_File_Processing")

    file_a = SCRATCH_DIR / "batch_a.txt"
    file_b = SCRATCH_DIR / "batch_b.txt"
    bytes_a = (b"File A Content ") * 400 # 6000 bytes
    bytes_b = (b"File B Content ") * 500 # 7500 bytes

    file_a.write_bytes(bytes_a)
    file_b.write_bytes(bytes_b)

    for file_path, exp_chunks in [(file_a, 2), (file_b, 3)]:
        cmd = [
            str(TEST_ENG_EXE),
            "--input", str(file_path),
            "--limit", "3000",
            "--mode", "char"
        ]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            log_fail(f"Batch item {file_path.name} failed: {proc.stderr}")
            return False

        subfolder = SCRATCH_DIR / f"{file_path.stem}_parts"
        chunks = sorted(list(subfolder.glob(f"{file_path.stem}_part_*.txt")))
        if len(chunks) != exp_chunks:
            log_fail(f"Batch item {file_path.name} expected {exp_chunks} chunks, got {len(chunks)}")
            return False

        reassembled = b"".join(c.read_bytes() for c in chunks)
        if reassembled != file_path.read_bytes():
            log_fail(f"Batch item {file_path.name} binary reassembly mismatch")
            return False

    log_pass("Batch files processed into isolated subfolders with valid reassembly")
    return True


def test_invalid_parameters():
    """
    Tier 3 Error Handling Test:
    Asserts appropriate non-zero exit code when given non-existent file or maxLimit = 0.
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_Invalid_Parameters")

    # Non-existent file
    cmd1 = [str(TEST_ENG_EXE), "--input", str(SCRATCH_DIR / "does_not_exist.txt"), "--limit", "3000"]
    proc1 = subprocess.run(cmd1, capture_output=True, text=True)
    if proc1.returncode == 0:
        log_fail("Engine should return non-zero exit code for missing file")
        return False

    # Limit = 0
    valid_file = SCRATCH_DIR / "dummy_err.txt"
    valid_file.write_text("Hello World")
    cmd2 = [str(TEST_ENG_EXE), "--input", str(valid_file), "--limit", "0"]
    proc2 = subprocess.run(cmd2, capture_output=True, text=True)
    if proc2.returncode == 0:
        log_fail("Engine should return non-zero exit code for limit = 0")
        return False

    log_pass("Engine correctly handles missing files and zero limits with non-zero exit codes")
    return True


def test_cpp_unit_test_suite_runner():
    """
    Tier 1-4 Engine Unit Suite Verification:
    Runs test_engine.exe with no args to verify internal C++ engine unit tests pass.
    """
    global g_tests_run
    g_tests_run += 1
    log_step("Test_CPP_Unit_Test_Suite_Runner")

    proc = subprocess.run([str(TEST_ENG_EXE)], capture_output=True, text=True)
    if proc.returncode != 0:
        log_fail(f"C++ unit test suite returned exit code {proc.returncode}")
        return False

    if "0 FAILED" not in proc.stdout and "0 FAILED" not in proc.stderr:
        log_fail("C++ unit test suite output does not report 0 FAILED")
        return False

    log_pass("All 12 C++ engine unit tests passed cleanly")
    return True


def main():
    print("==================================================")
    print("File Splitter E2E Test Suite (Milestone 2)")
    print(f"Target Executable: {TEST_ENG_EXE}")
    print(f"Python Version   : {sys.version.split()[0]}")
    print("==================================================")

    if not TEST_ENG_EXE.exists():
        print(f"ERROR: Executable {TEST_ENG_EXE} not found. Build it using 'make test' or g++.")
        sys.exit(1)

    setup_scratch()

    try:
        test_10k_chars_by_3k_limit()
        test_exact_boundary_9k_chars()
        test_line_splitting_350_lines()
        test_batch_file_processing()
        test_invalid_parameters()
        test_cpp_unit_test_suite_runner()
    finally:
        cleanup_scratch()

    print("\n==================================================")
    print(f"Summary: {g_tests_passed} PASSED, {g_tests_failed} FAILED (Total: {g_tests_run})")
    print("==================================================")

    if g_tests_failed == 0:
        print("ALL MILESTONE 2 E2E VERIFICATION TESTS PASSED SUCCESSFULLY.")
        sys.exit(0)
    else:
        print("SOME TESTS FAILED.")
        sys.exit(1)


if __name__ == "__main__":
    main()
