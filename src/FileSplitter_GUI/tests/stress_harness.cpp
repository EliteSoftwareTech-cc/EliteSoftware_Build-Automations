// ==============================================================================
// tests/stress_harness.cpp - Empirical Stress & Boundary Harness for TextSplitterEngine
// ==============================================================================

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <sstream>
#include <chrono>
#include <cstdlib>
#include <thread>
#include <atomic>
#include "TextSplitterEngine.h"

namespace fs = std::filesystem;
using namespace FileSplitter;

static int g_passCount = 0;
static int g_failCount = 0;

#define HARNESS_ASSERT(cond, msg) \
    do { \
        if (!(cond)) { \
            std::cerr << "\n  [HARNESS FAIL] " << msg << " (" << __FILE__ << ":" << __LINE__ << ")\n"; \
            return false; \
        } \
    } while(0)

static void RunHarnessTest(const std::string& name, bool (*func)()) {
    std::cout << "[STRESS TEST] " << name << " ... " << std::flush;
    auto start = std::chrono::high_resolution_clock::now();
    bool pass = func();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::high_resolution_clock::now() - start).count();

    if (pass) {
        std::cout << "[PASSED] (" << elapsed << " ms)\n";
        g_passCount++;
    } else {
        std::cout << "[FAILED]\n";
        g_failCount++;
    }
}

static fs::path GetScratchDir() {
    fs::path dir = fs::current_path() / "stress_scratchpad";
    std::error_code ec;
    fs::create_directories(dir, ec);
    return dir;
}

static void CleanScratchDir() {
    fs::path dir = fs::current_path() / "stress_scratchpad";
    std::error_code ec;
    if (fs::exists(dir, ec)) {
        fs::remove_all(dir, ec);
    }
}

static std::string ReadBinary(const fs::path& p) {
    std::ifstream in(p.c_str(), std::ios::binary);
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

static std::string ConcatChunks(const std::vector<std::wstring>& paths) {
    std::string out;
    for (const auto& w : paths) {
        out += ReadBinary(fs::path(w));
    }
    return out;
}

// ------------------------------------------------------------------------------
// Test 1: Exact 100,000 bytes split by 10,000 bytes
// ------------------------------------------------------------------------------
static bool Test_100k_Split_By_10k() {
    fs::path inputPath = GetScratchDir() / "100k_file.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    std::string pattern = "0123456789"; // 10 bytes pattern
    for (int i = 0; i < 10000; ++i) {
        out.write(pattern.data(), 10);
    }
    out.close();

    std::string original = ReadBinary(inputPath);
    HARNESS_ASSERT(original.size() == 100000, "Created file size is not 100,000 bytes");

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 10000;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(res.success, "Splitting 100k file failed");
    HARNESS_ASSERT(res.chunksCreated == 10, "Expected exactly 10 chunks");
    HARNESS_ASSERT(res.generatedChunkPaths.size() == 10, "Generated paths size mismatch");

    for (size_t i = 0; i < res.generatedChunkPaths.size(); ++i) {
        size_t sz = fs::file_size(res.generatedChunkPaths[i]);
        HARNESS_ASSERT(sz == 10000, "Chunk size is not exactly 10,000 bytes");
    }

    std::string reassembled = ConcatChunks(res.generatedChunkPaths);
    HARNESS_ASSERT(reassembled == original, "Concatenated 100k split does not match original");

    return true;
}

// ------------------------------------------------------------------------------
// Test 2: Empty input file (0 bytes)
// ------------------------------------------------------------------------------
static bool Test_Empty_File() {
    fs::path inputPath = GetScratchDir() / "empty_file.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    out.close();

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1000;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(res.success, "Splitting empty file reported error");
    HARNESS_ASSERT(res.chunksCreated == 0, "Empty file should result in 0 created chunks");
    HARNESS_ASSERT(res.totalBytesProcessed == 0, "Total bytes processed should be 0");
    HARNESS_ASSERT(res.totalUnitsProcessed == 0, "Total units processed should be 0");

    // Also test line split mode on empty file
    opts.mode = SplitMode::ByLines;
    FileSplitResult resLine = TextSplitterEngine::SplitFile(opts);
    HARNESS_ASSERT(resLine.success, "Splitting empty file by lines reported error");
    HARNESS_ASSERT(resLine.chunksCreated == 0, "Empty file by lines should result in 0 chunks");

    return true;
}

// ------------------------------------------------------------------------------
// Test 3: Single byte input file
// ------------------------------------------------------------------------------
static bool Test_Single_Byte_File() {
    fs::path inputPath = GetScratchDir() / "single_byte.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    out.put('Z');
    out.close();

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1000;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(res.success, "Single byte split failed");
    HARNESS_ASSERT(res.chunksCreated == 1, "Expected 1 chunk created for 1 byte file");
    HARNESS_ASSERT(fs::file_size(res.generatedChunkPaths[0]) == 1, "Chunk size is not 1 byte");

    std::string reassembled = ConcatChunks(res.generatedChunkPaths);
    HARNESS_ASSERT(reassembled == "Z", "Reassembled single byte does not match 'Z'");

    return true;
}

// ------------------------------------------------------------------------------
// Test 4: CRLF line end preservation
// ------------------------------------------------------------------------------
static bool Test_CRLF_Preservation() {
    fs::path inputPath = GetScratchDir() / "crlf_file.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    for (int i = 1; i <= 25; ++i) {
        out << "Windows Line " << i << "\r\n";
    }
    out.close();

    std::string original = ReadBinary(inputPath);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByLines;
    opts.maxLimit = 10;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(res.success, "CRLF line split failed");
    HARNESS_ASSERT(res.chunksCreated == 3, "Expected 3 chunks (10, 10, 5 lines)");

    // Inspect each chunk file content for \r\n endings
    for (size_t i = 0; i < res.generatedChunkPaths.size(); ++i) {
        std::string chunkData = ReadBinary(res.generatedChunkPaths[i]);
        HARNESS_ASSERT(!chunkData.empty(), "Chunk data empty");
        // Verify every line end in chunk data has \r\n
        size_t pos = 0;
        while ((pos = chunkData.find('\n', pos)) != std::string::npos) {
            HARNESS_ASSERT(pos > 0 && chunkData[pos - 1] == '\r', "Line ending missing CR '\\r' before LF '\\n'");
            pos++;
        }
    }

    std::string reassembled = ConcatChunks(res.generatedChunkPaths);
    HARNESS_ASSERT(reassembled == original, "CRLF reassembled content mismatch");

    return true;
}

// ------------------------------------------------------------------------------
// Test 5: UTF-8 Multi-byte character boundary stress test
// ------------------------------------------------------------------------------
static bool Test_Utf8_Multibyte_Boundaries() {
    fs::path inputPath = GetScratchDir() / "utf8_multibyte.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);

    // Write a mix of 1-byte, 2-byte (é), 3-byte (€), 4-byte (🌟) characters
    // 🌟 in UTF-8: 0xF0 0x9F 0x8C 0x9F (4 bytes, 1 character)
    // € in UTF-8: 0xE2 0x82 0xAC (3 bytes, 1 character)
    // é in UTF-8: 0xC3 0xA9 (2 bytes, 1 character)
    std::string utf8_sample = "Aé€🌟B"; // 5 characters, total 1 + 2 + 3 + 4 + 1 = 11 bytes

    // Repeat 500 times = 2500 characters
    for (int i = 0; i < 500; ++i) {
        out << utf8_sample;
    }
    out.close();

    std::string original = ReadBinary(inputPath);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 100; // Split by 100 characters

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(res.success, "UTF-8 multi-byte split failed");
    HARNESS_ASSERT(res.chunksCreated == 25, "Expected 25 chunks (2500 chars / 100)");

    // Verify concatenation identity
    std::string reassembled = ConcatChunks(res.generatedChunkPaths);
    HARNESS_ASSERT(reassembled == original, "UTF-8 reassembled content mismatch");

    // Verify no chunk has an invalid UTF-8 sequence at start or end
    for (const auto& wpath : res.generatedChunkPaths) {
        std::string chunkStr = ReadBinary(wpath);
        HARNESS_ASSERT(!chunkStr.empty(), "UTF-8 chunk empty");
        // Verify first byte of chunk is a lead byte (or ASCII)
        unsigned char first = static_cast<unsigned char>(chunkStr[0]);
        HARNESS_ASSERT(TextSplitterEngine::IsUtf8LeadByte(first), "Chunk starts with invalid UTF-8 continuation byte");
    }

    return true;
}

// ------------------------------------------------------------------------------
// Test 6: Thread Cancellation Token
// ------------------------------------------------------------------------------
static bool Test_Cancellation_Token() {
    fs::path inputPath = GetScratchDir() / "large_cancel_test.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    std::string line = "This is a dummy line for cancellation test.\n";
    for (int i = 0; i < 100000; ++i) {
        out << line;
    }
    out.close();

    std::atomic<bool> cancelFlag{false};

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 5000;
    opts.cancelToken = &cancelFlag;

    // Trigger cancel after callback receives progress
    opts.progressCallback = [&](size_t, size_t, uint64_t bytesProcessed, uint64_t) {
        if (bytesProcessed > 50000) {
            cancelFlag.store(true);
        }
    };

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    HARNESS_ASSERT(!res.success, "SplitFile should report success=false when cancelled");
    HARNESS_ASSERT(res.errorMessage.find(L"cancelled") != std::wstring::npos, "Error message should mention cancellation");

    return true;
}

// ------------------------------------------------------------------------------
// Test 7: Batch Error Isolation
// ------------------------------------------------------------------------------
static bool Test_Batch_Error_Isolation() {
    fs::path file1 = GetScratchDir() / "batch_valid1.txt";
    fs::path file2 = GetScratchDir() / "non_existent_file.txt";
    fs::path file3 = GetScratchDir() / "batch_valid2.txt";

    std::ofstream out1(file1.c_str(), std::ios::binary); out1 << "Valid file 1\n"; out1.close();
    std::ofstream out3(file3.c_str(), std::ios::binary); out3 << "Valid file 2\n"; out3.close();

    SplitOptions baseOpt;
    baseOpt.mode = SplitMode::ByLines;
    baseOpt.maxLimit = 10;

    std::vector<std::wstring> batchFiles = { file1.wstring(), file2.wstring(), file3.wstring() };

    BatchSplitResult batchRes = TextSplitterEngine::SplitBatch(batchFiles, baseOpt);

    HARNESS_ASSERT(batchRes.totalFiles == 3, "Batch total files count mismatch");
    HARNESS_ASSERT(batchRes.successfulFiles == 2, "Expected 2 successful files in batch");
    HARNESS_ASSERT(batchRes.failedFiles == 1, "Expected 1 failed file in batch");
    HARNESS_ASSERT(batchRes.results[0].success, "File 1 should succeed");
    HARNESS_ASSERT(!batchRes.results[1].success, "File 2 (missing) should fail");
    HARNESS_ASSERT(batchRes.results[2].success, "File 3 should succeed");

    return true;
}

// ------------------------------------------------------------------------------
// Test 8: Large File Performance Benchmark (10 MB)
// ------------------------------------------------------------------------------
static bool Test_Performance_Benchmark() {
    fs::path inputPath = GetScratchDir() / "perf_10mb.txt";
    std::ofstream out(inputPath.c_str(), std::ios::binary);
    std::string block(1024, 'A'); // 1 KB block
    block[1023] = '\n';

    for (int i = 0; i < 10240; ++i) { // 10 MB = 10,240 KB
        out.write(block.data(), block.size());
    }
    out.close();

    uint64_t fileSize = fs::file_size(inputPath);
    HARNESS_ASSERT(fileSize >= 10 * 1024 * 1024, "Performance test file size < 10 MB");

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 100000; // Split into ~100 chunks

    auto start = std::chrono::high_resolution_clock::now();
    FileSplitResult res = TextSplitterEngine::SplitFile(opts);
    auto elapsedMs = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::high_resolution_clock::now() - start).count();

    HARNESS_ASSERT(res.success, "10 MB performance split failed");
    HARNESS_ASSERT(res.chunksCreated > 0, "No chunks created");

    double mbProcessed = static_cast<double>(fileSize) / (1024.0 * 1024.0);
    double seconds = static_cast<double>(elapsedMs) / 1000.0;
    double mbPerSec = (seconds > 0.0) ? (mbProcessed / seconds) : mbProcessed * 1000.0;

    std::cout << "\n    [PERF STATS] 10.0 MB processed in " << elapsedMs << " ms (" 
              << mbPerSec << " MB/s throughput, " << res.chunksCreated << " chunks) ... ";

    return true;
}

// ------------------------------------------------------------------------------
// Main Runner
// ------------------------------------------------------------------------------
int main() {
    std::cout << "==================================================\n";
    std::cout << "TextSplitterEngine Empirical Stress Harness (M1-2)\n";
    std::cout << "==================================================\n";

    CleanScratchDir();

    RunHarnessTest("Test_100k_Split_By_10k", Test_100k_Split_By_10k);
    RunHarnessTest("Test_Empty_File", Test_Empty_File);
    RunHarnessTest("Test_Single_Byte_File", Test_Single_Byte_File);
    RunHarnessTest("Test_CRLF_Preservation", Test_CRLF_Preservation);
    RunHarnessTest("Test_Utf8_Multibyte_Boundaries", Test_Utf8_Multibyte_Boundaries);
    RunHarnessTest("Test_Cancellation_Token", Test_Cancellation_Token);
    RunHarnessTest("Test_Batch_Error_Isolation", Test_Batch_Error_Isolation);
    RunHarnessTest("Test_Performance_Benchmark", Test_Performance_Benchmark);

    CleanScratchDir();

    std::cout << "==================================================\n";
    std::cout << "Stress Harness Summary: " << g_passCount << " PASSED, " << g_failCount << " FAILED.\n";
    std::cout << "==================================================\n";

    return (g_failCount == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}
