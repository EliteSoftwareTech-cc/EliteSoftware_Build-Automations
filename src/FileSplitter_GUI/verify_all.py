import os
import sys
import struct
import subprocess
import shutil

def verify_pe_headers():
    print("--- 1. PE Machine Header Verification ---")
    files = {
        r"BuildOutput\FileSplitter.exe": 0x8664,
        r"BuildOutputx86\FileSplitter.exe": 0x014C
    }
    all_ok = True
    for path, expected in files.items():
        if not os.path.exists(path):
            print(f"FAIL: File does not exist: {path}")
            all_ok = False
            continue
        with open(path, "rb") as f:
            f.seek(0x3C)
            pe_off = struct.unpack("<I", f.read(4))[0]
            f.seek(pe_off + 4)
            mach = struct.unpack("<H", f.read(2))[0]
        mach_hex = f"0x{mach:04X}"
        exp_hex = f"0x{expected:04X}"
        if mach == expected:
            print(f"PASS: {path} PE Machine Header is {mach_hex} (matches expected {exp_hex})")
        else:
            print(f"FAIL: {path} PE Machine Header is {mach_hex} (expected {exp_hex})")
            all_ok = False
    return all_ok

def run_adversarial_text_splitting_test():
    print("\n--- 2. Adversarial Text Splitting Test ---")
    # Task: 10,000 UTF-8 characters with mixed CRLF/LF line endings split into 3,000-character chunks -> exactly 4 chunks, valid UTF-8, byte-for-byte binary identity.
    scratch_dir = os.path.abspath("test_adv_scratch")
    if os.path.exists(scratch_dir):
        shutil.rmtree(scratch_dir)
    os.makedirs(scratch_dir, exist_ok=True)
    input_file = os.path.join(scratch_dir, "adv_input_10k.txt")

    # Construct a 10,000 UTF-8 character string with mixed CRLF/LF line endings and multi-byte UTF-8 chars.
    # Unicode characters: ASCII, Spanish (é), Greek (α, β, γ), CJK (漢, 字), Emoji (😊), line endings \r\n and \n.
    sample = "Hello World! 😊 Alpha-β-γ-δ-ε 漢字-テスト. \r\nLine 2 with LF:\nLine 3 with CRLF:\r\nSome more text here. "
    full_text = (sample * (10000 // len(sample) + 1))[:10000]
    assert len(full_text) == 10000, f"Expected 10000 chars, got {len(full_text)}"

    with open(input_file, "w", encoding="utf-8", newline="") as f:
        f.write(full_text)

    # Input binary content
    with open(input_file, "rb") as f:
        input_bytes = f.read()

    print(f"Generated input file: {input_file} ({len(full_text)} characters, {len(input_bytes)} bytes)")

    engine_exe = os.path.abspath("test_engine.exe")
    if not os.path.exists(engine_exe):
        print(f"FAIL: {engine_exe} not found.")
        return False

    cmd = [engine_exe, "--input", input_file, "--limit", "3000", "--mode", "char"]
    print(f"Running command: {' '.join(cmd)}")
    res = subprocess.run(cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"FAIL: Command failed with exit code {res.returncode}. Stderr: {res.stderr}")
        return False

    subfolder = os.path.join(scratch_dir, "adv_input_10k_parts")
    if not os.path.exists(subfolder):
        print(f"FAIL: Expected subfolder {subfolder} does not exist.")
        return False

    chunk_files = sorted([os.path.join(subfolder, f) for f in os.listdir(subfolder) if f.endswith(".txt")])
    print(f"Produced {len(chunk_files)} chunk files: {[os.path.basename(f) for f in chunk_files]}")

    if len(chunk_files) != 4:
        print(f"FAIL: Expected exactly 4 chunks, got {len(chunk_files)}")
        return False

    reassembled_bytes = bytearray()
    valid_utf8_all = True
    char_counts = []

    for i, cpath in enumerate(chunk_files):
        with open(cpath, "rb") as f:
            cdata = f.read()
        reassembled_bytes.extend(cdata)
        try:
            ctext = cdata.decode("utf-8")
            char_counts.append(len(ctext))
            print(f" Chunk {i+1} ({os.path.basename(cpath)}): {len(cdata)} bytes, {len(ctext)} characters")
            if len(ctext) > 3000:
                print(f"FAIL: Chunk {i+1} character count {len(ctext)} exceeds 3000 limit!")
                return False
        except UnicodeDecodeError as e:
            print(f"FAIL: Chunk {i+1} ({cpath}) contains invalid UTF-8: {e}")
            valid_utf8_all = False

    if not valid_utf8_all:
        return False

    if char_counts != [3000, 3000, 3000, 1000]:
        print(f"FAIL: Expected character counts [3000, 3000, 3000, 1000], got {char_counts}")
        return False

    # Check byte-for-byte binary identity
    if reassembled_bytes == input_bytes:
        print("PASS: Reassembled chunks match input file byte-for-byte!")
    else:
        print("FAIL: Reassembled bytes do NOT match input bytes!")
        print(f"Input bytes len: {len(input_bytes)}, Reassembled bytes len: {len(reassembled_bytes)}")
        return False

    print("PASS: Adversarial text splitting test PASSED perfectly (4 chunks [3000, 3000, 3000, 1000], valid UTF-8, binary identity verified)!")
    return True

def run_test_suites():
    print("\n--- 3. Running Test Suites ---")
    # Run test_engine.exe
    print("Running C++ unit test runner (test_engine.exe)...")
    res1 = subprocess.run(["test_engine.exe"], capture_output=True, text=True)
    print(res1.stdout)
    if res1.returncode != 0:
        print(f"FAIL: test_engine.exe failed with code {res1.returncode}")
        return False
    print("PASS: C++ unit test runner passed.")

    # Run Python E2E tests (tests/test_splitter.py)
    print("Running Python E2E integration test suite (tests/test_splitter.py)...")
    res2 = subprocess.run([sys.executable, r"tests\test_splitter.py"], capture_output=True, text=True)
    print(res2.stdout)
    if res2.returncode != 0:
        print(f"FAIL: tests/test_splitter.py failed with code {res2.returncode}")
        print(res2.stderr)
        return False
    print("PASS: Python E2E integration test suite passed.")
    return True

def verify_icon_and_html():
    print("\n--- 4. Icon Sideloading and Agent-Thread_HTML Verification ---")
    # Check FileSplitter.ico in root, BuildOutput, BuildOutputx86
    icon_paths = [
        "FileSplitter.ico",
        r"BuildOutput\FileSplitter.ico",
        r"BuildOutputx86\FileSplitter.ico"
    ]
    all_ok = True
    for ip in icon_paths:
        if os.path.exists(ip) and os.path.getsize(ip) > 0:
            print(f"PASS: Icon exists: {ip} ({os.path.getsize(ip)} bytes)")
        else:
            print(f"FAIL: Icon missing or empty: {ip}")
            all_ok = False

    # Check Agent-Thread_HTML/index.html
    html_path = r"Agent-Thread_HTML\index.html"
    if os.path.exists(html_path) and os.path.getsize(html_path) > 0:
        print(f"PASS: HTML dashboard exists: {html_path} ({os.path.getsize(html_path)} bytes)")
        with open(html_path, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        print(f" HTML Dashboard Title/Content snippet: {content[:300]}...")
    else:
        print(f"FAIL: HTML dashboard missing or empty: {html_path}")
        all_ok = False

    # Check if HTML was packaged into BuildOutput and BuildOutputx86
    pkg_html = [
        r"BuildOutput\Agent-Thread_HTML\index.html",
        r"BuildOutputx86\Agent-Thread_HTML\index.html"
    ]
    for hp in pkg_html:
        if os.path.exists(hp) and os.path.getsize(hp) > 0:
            print(f"PASS: Packaged HTML exists: {hp}")
        else:
            print(f"FAIL: Packaged HTML missing: {hp}")
            all_ok = False

    return all_ok

if __name__ == "__main__":
    t1 = verify_pe_headers()
    t2 = run_adversarial_text_splitting_test()
    t3 = run_test_suites()
    t4 = verify_icon_and_html()

    print("\n================ FINAL RESULTS ================")
    print(f"PE Headers       : {'PASS' if t1 else 'FAIL'}")
    print(f"Adversarial Split: {'PASS' if t2 else 'FAIL'}")
    print(f"Test Suites      : {'PASS' if t3 else 'FAIL'}")
    print(f"Icon & HTML      : {'PASS' if t4 else 'FAIL'}")

    if t1 and t2 and t3 and t4:
        print("\nVERDICT: APPROVE")
        sys.exit(0)
    else:
        print("\nVERDICT: REJECT")
        sys.exit(1)
