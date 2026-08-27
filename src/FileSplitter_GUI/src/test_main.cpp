// ==============================================================================
// src/test_main.cpp - C++ Unit Test Runner for TextSplitterEngine
// ==============================================================================

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <sstream>
#include <chrono>
#include <cstdlib>
#include "TextSplitterEngine.h"

namespace fs = std::filesystem;
using namespace FileSplitter;

// ------------------------------------------------------------------------------
// Test Harness Utilities
// ------------------------------------------------------------------------------

static int g_testsPassed = 0;
static int g_testsFailed = 0;

#define TEST_ASSERT(cond, msg) \
    do { \
        if (!(cond)) { \
            std::cerr << "\n  [FAIL] " << msg << " (" << __FILE__ << ":" << __LINE__ << ")\n"; \
            return false; \
        } \
    } while(0)

static void RunTest(const std::string& testName, bool (*testFunc)()) {
    std::cout << "[RUN] " << testName << " ... " << std::flush;
    auto start = std::chrono::high_resolution_clock::now();
    bool passed = testFunc();
    auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::high_resolution_clock::now() - start).count();

    if (passed) {
        std::cout << "[PASSED] (" << elapsed << " ms)\n";
        g_testsPassed++;
    } else {
        std::cout << "[FAILED]\n";
        g_testsFailed++;
    }
}

// ------------------------------------------------------------------------------
// Helper Functions for Generating & Inspecting Test Files
// ------------------------------------------------------------------------------

static fs::path GetTestTempDir() {
    fs::path tempDir = fs::current_path() / "test_scratchpad";
    std::error_code ec;
    fs::create_directories(tempDir, ec);
    return tempDir;
}

static void CleanTestTempDir() {
    fs::path tempDir = fs::current_path() / "test_scratchpad";
    std::error_code ec;
    if (fs::exists(tempDir, ec)) {
        fs::remove_all(tempDir, ec);
    }
}

static fs::path CreateDummyCharFile(const std::string& filename, size_t charCount) {
    fs::path filePath = GetTestTempDir() / filename;
    std::ofstream out(filePath.c_str(), std::ios::binary);
    std::string pattern = "abcdefghijklmnopqrstuvwxyz0123456789\n";
    size_t written = 0;
    while (written < charCount) {
        size_t toWrite = std::min(pattern.size(), charCount - written);
        out.write(pattern.data(), toWrite);
        written += toWrite;
    }
    out.close();
    return filePath;
}

static fs::path CreateDummyLineFile(const std::string& filename, size_t lineCount) {
    fs::path filePath = GetTestTempDir() / filename;
    std::ofstream out(filePath.c_str(), std::ios::binary);
    for (size_t i = 1; i <= lineCount; ++i) {
        out << "Line " << i << ": Lorem ipsum dolor sit amet, consectetur adipiscing elit.\r\n";
    }
    out.close();
    return filePath;
}

static std::string ReadFileBinary(const fs::path& filePath) {
    std::ifstream in(filePath.c_str(), std::ios::binary);
    std::ostringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

static std::string ConcatChunkPaths(const std::vector<std::wstring>& chunkPaths) {
    std::string combined;
    for (const auto& wpath : chunkPaths) {
        combined += ReadFileBinary(fs::path(wpath));
    }
    return combined;
}

// ------------------------------------------------------------------------------
// Test Case 1: 10,000 Chars split by 3,000 Chars -> Exactly 4 files (3k, 3k, 3k, 1k)
// ------------------------------------------------------------------------------
static bool Test_Split_10k_Chars_By_3k_Limit() {
    fs::path inputPath = CreateDummyCharFile("test_10k.txt", 10000);
    std::string originalContent = ReadFileBinary(inputPath);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 3000;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(res.success, "Engine reported failure during 10k split");
    TEST_ASSERT(res.chunksCreated == 4, "Expected exactly 4 chunks created");
    TEST_ASSERT(res.generatedChunkPaths.size() == 4, "generatedChunkPaths size mismatch");
    TEST_ASSERT(fs::exists(res.outputFolderPath), "Output subfolder does not exist");

    // Check individual chunk file sizes
    size_t size1 = fs::file_size(res.generatedChunkPaths[0]);
    size_t size2 = fs::file_size(res.generatedChunkPaths[1]);
    size_t size3 = fs::file_size(res.generatedChunkPaths[2]);
    size_t size4 = fs::file_size(res.generatedChunkPaths[3]);

    TEST_ASSERT(size1 == 3000, "Part 1 size is not 3,000 bytes");
    TEST_ASSERT(size2 == 3000, "Part 2 size is not 3,000 bytes");
    TEST_ASSERT(size3 == 3000, "Part 3 size is not 3,000 bytes");
    TEST_ASSERT(size4 == 1000, "Part 4 size is not 1,000 bytes");

    // Verify concatenation identity
    std::string reassembled = ConcatChunkPaths(res.generatedChunkPaths);
    TEST_ASSERT(reassembled == originalContent, "Concatenated content does not match original file");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 2: Exact Boundary 9,000 Chars split by 3,000 -> Exactly 3 files
// ------------------------------------------------------------------------------
static bool Test_Split_Exact_Boundary_9k_Chars_By_3k_Limit() {
    fs::path inputPath = CreateDummyCharFile("test_9k.txt", 9000);
    std::string originalContent = ReadFileBinary(inputPath);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 3000;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(res.success, "Engine reported failure during 9k exact boundary split");
    TEST_ASSERT(res.chunksCreated == 3, "Expected exactly 3 chunks created for exact boundary");
    TEST_ASSERT(res.generatedChunkPaths.size() == 3, "generatedChunkPaths size mismatch");

    std::string reassembled = ConcatChunkPaths(res.generatedChunkPaths);
    TEST_ASSERT(reassembled == originalContent, "Concatenated content does not match original file");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 3: 350 Lines split by 100 Line Limit -> 4 files (100, 100, 100, 50)
// ------------------------------------------------------------------------------
static bool Test_Split_350_Lines_By_100_Line_Limit() {
    fs::path inputPath = CreateDummyLineFile("test_350lines.txt", 350);
    std::string originalContent = ReadFileBinary(inputPath);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByLines;
    opts.maxLimit = 100;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(res.success, "Engine reported failure during 350-line split");
    TEST_ASSERT(res.chunksCreated == 4, "Expected exactly 4 line chunks");
    TEST_ASSERT(res.generatedChunkPaths.size() == 4, "generatedChunkPaths size mismatch");

    std::string reassembled = ConcatChunkPaths(res.generatedChunkPaths);
    TEST_ASSERT(reassembled == originalContent, "Line split content identity failed");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 4: Batch Processing Multiple Files
// ------------------------------------------------------------------------------
static bool Test_Split_Batch_Processing() {
    fs::path fileA = CreateDummyCharFile("batch_a.txt", 5000);
    fs::path fileB = CreateDummyCharFile("batch_b.txt", 7000);

    SplitOptions optA;
    optA.inputFilePath = fileA.wstring();
    optA.mode = SplitMode::ByCharacters;
    optA.maxLimit = 3000;

    SplitOptions optB;
    optB.inputFilePath = fileB.wstring();
    optB.mode = SplitMode::ByCharacters;
    optB.maxLimit = 3000;

    std::vector<SplitOptions> batchOpts = { optA, optB };
    BatchSplitResult batchRes = TextSplitterEngine::SplitBatch(batchOpts);
    std::vector<FileSplitResult> results = batchRes;

    TEST_ASSERT(results.size() == 2, "Expected 2 batch results");
    TEST_ASSERT(results[0].success && results[0].chunksCreated == 2, "Batch item A failed");
    TEST_ASSERT(results[1].success && results[1].chunksCreated == 3, "Batch item B failed");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 5: Error Handling & Invalid Options
// ------------------------------------------------------------------------------
static bool Test_Split_Error_Handling() {
    // 5a. Non-existent file
    SplitOptions optMissing;
    optMissing.inputFilePath = (GetTestTempDir() / "non_existent.txt").wstring();
    optMissing.mode = SplitMode::ByCharacters;
    optMissing.maxLimit = 1000;

    FileSplitResult resMissing = TextSplitterEngine::SplitFile(optMissing);
    TEST_ASSERT(!resMissing.success, "Engine should report failure for non-existent file");
    TEST_ASSERT(!resMissing.errorMessage.empty(), "Error message should not be empty");

    // 5b. Invalid limit zero
    fs::path dummyPath = CreateDummyCharFile("dummy_err.txt", 500);
    SplitOptions optZero;
    optZero.inputFilePath = dummyPath.wstring();
    optZero.mode = SplitMode::ByCharacters;
    optZero.maxLimit = 0;

    FileSplitResult resZero = TextSplitterEngine::SplitFile(optZero);
    TEST_ASSERT(!resZero.success, "Engine should report failure when maxLimit is 0");

    return true;
}

// ------------------------------------------------------------------------------
// Stress Test 6: UTF-8 Multibyte Codepoint Preservation
// ------------------------------------------------------------------------------
static bool Test_Split_UTF8_Multibyte_Preservation() {
    fs::path filePath = GetTestTempDir() / "utf8_test.txt";
    {
        std::ofstream out(filePath.c_str(), std::ios::binary);
        // "Hello 世界 🌍!" -> 6 ASCII + 2x3-byte Japanese + 1 space + 1x4-byte Emoji + 1 exclamation = 17 bytes, 11 codepoints
        for (int i = 0; i < 100; ++i) {
            out << "Hello 世界 🌍! ";
        }
    }
    std::string originalContent = ReadFileBinary(filePath);

    SplitOptions opts;
    opts.inputFilePath = filePath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 15; // Force split across multi-byte codepoint boundaries

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(res.success, "UTF-8 split failed");
    std::string reassembled = ConcatChunkPaths(res.generatedChunkPaths);
    TEST_ASSERT(reassembled == originalContent, "UTF-8 reassembled content mismatch");

    return true;
}

// ------------------------------------------------------------------------------
// Stress Test 7: Line Splitting without Trailing Newline & Unit Counting
// ------------------------------------------------------------------------------
static bool Test_Split_No_Trailing_Newline() {
    fs::path filePath = GetTestTempDir() / "no_trailing_nl.txt";
    {
        std::ofstream out(filePath.c_str(), std::ios::binary);
        out << "Line 1\nLine 2\nLine 3 without newline";
    }
    std::string originalContent = ReadFileBinary(filePath);

    SplitOptions opts;
    opts.inputFilePath = filePath.wstring();
    opts.mode = SplitMode::ByLines;
    opts.maxLimit = 1;

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(res.success, "Line split without trailing newline failed");
    TEST_ASSERT(res.chunksCreated == 3, "Expected 3 chunks for 3 lines without trailing newline");
    TEST_ASSERT(res.totalUnitsProcessed == 3, "totalUnitsProcessed expected 3 for 3 lines");
    std::string reassembled = ConcatChunkPaths(res.generatedChunkPaths);
    TEST_ASSERT(reassembled == originalContent, "Reassembled content mismatch for no trailing newline");

    // Also test 1 line without trailing newline
    fs::path lineFile = GetTestTempDir() / "one_line_no_nl.txt";
    {
        std::ofstream out(lineFile.c_str(), std::ios::binary);
        out << "Single line content without newline";
    }
    opts.inputFilePath = lineFile.wstring();
    FileSplitResult resLine = TextSplitterEngine::SplitFile(opts);
    TEST_ASSERT(resLine.success, "Single line without newline split failed");
    TEST_ASSERT(resLine.chunksCreated == 1, "Expected 1 chunk for single line");
    TEST_ASSERT(resLine.totalUnitsProcessed == 1, "totalUnitsProcessed expected 1 for single line without newline");

    return true;
}

// ------------------------------------------------------------------------------
// Stress Test 8: Cancellation Token Mid-Stream & Full Cleanup
// ------------------------------------------------------------------------------
static bool Test_Split_Cancellation() {
    fs::path inputPath = CreateDummyCharFile("cancel_test.txt", 500000);

    std::atomic<bool> cancelToken{false};
    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1000;
    opts.cancelToken = &cancelToken;
    opts.progressCallback = [&](size_t, size_t, uint64_t bytesProcessed, uint64_t) {
        if (bytesProcessed > 5000) {
            cancelToken.store(true);
        }
    };

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(!res.success, "Engine should report failure when cancelled");
    TEST_ASSERT(res.errorMessage.find(L"cancelled") != std::wstring::npos, "Error message should mention cancellation");
    TEST_ASSERT(res.generatedChunkPaths.empty(), "generatedChunkPaths should be empty on cancellation");

    return true;
}

// ------------------------------------------------------------------------------
// Stress Test 9: Batch File Error Isolation
// ------------------------------------------------------------------------------
static bool Test_Split_Batch_Isolation() {
    fs::path validFile = CreateDummyCharFile("batch_valid.txt", 3000);
    fs::path missingFile = GetTestTempDir() / "non_existent_batch.txt";

    SplitOptions optValid;
    optValid.inputFilePath = validFile.wstring();
    optValid.maxLimit = 1000;

    SplitOptions optMissing;
    optMissing.inputFilePath = missingFile.wstring();
    optMissing.maxLimit = 1000;

    std::vector<SplitOptions> batchOpts = { optMissing, optValid };
    BatchSplitResult batchRes = TextSplitterEngine::SplitBatch(batchOpts);

    TEST_ASSERT(batchRes.totalFiles == 2, "Batch total files count mismatch");
    TEST_ASSERT(batchRes.successfulFiles == 1, "Expected 1 successful file");
    TEST_ASSERT(batchRes.failedFiles == 1, "Expected 1 failed file");
    TEST_ASSERT(!batchRes.results[0].success, "First file (missing) should fail");
    TEST_ASSERT(batchRes.results[1].success, "Second file (valid) should succeed");

    return true;
}

// ------------------------------------------------------------------------------
// Stress Test 10: Filename Sanitization & Subfolder Path Generation
// ------------------------------------------------------------------------------
static bool Test_Split_Sanitize_Filename() {
    std::wstring dirty = L"file:with*invalid?chars<tag>|pipe";
    std::wstring clean = TextSplitterEngine::SanitizeFileName(dirty);
    TEST_ASSERT(clean == L"file_with_invalid_chars_tag__pipe", "Sanitized string mismatch");

    std::wstring subfolder = TextSplitterEngine::GenerateSubfolderPath(L"C:\\TestDir\\my_file.txt", L"");
    TEST_ASSERT(subfolder.find(L"my_file_parts") != std::wstring::npos, "Subfolder path mismatch");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 11: overwriteExisting = false Enforcement
// ------------------------------------------------------------------------------
static bool Test_Split_Overwrite_Existing_Flag() {
    fs::path inputPath = CreateDummyCharFile("overwrite_test.txt", 100);

    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 50;

    // First split to generate chunk files
    FileSplitResult res1 = TextSplitterEngine::SplitFile(opts);
    TEST_ASSERT(res1.success, "Initial split failed");
    TEST_ASSERT(!res1.generatedChunkPaths.empty(), "No chunk paths generated");

    // Modify existing chunk file
    fs::path chunk1 = res1.generatedChunkPaths[0];
    {
        std::ofstream out(chunk1.c_str(), std::ios::binary);
        out << "PRE_EXISTING_DATA_MODIFIED";
    }

    // Split again with overwriteExisting = false
    opts.overwriteExisting = false;
    FileSplitResult res2 = TextSplitterEngine::SplitFile(opts);
    TEST_ASSERT(!res2.success, "Engine should report failure when overwriteExisting=false and file exists");
    TEST_ASSERT(res2.errorMessage.find(L"already exists") != std::wstring::npos, "Error message should report existing file");

    // Verify existing chunk was not overwritten
    std::string content = ReadFileBinary(chunk1);
    TEST_ASSERT(content == "PRE_EXISTING_DATA_MODIFIED", "Existing file content was overwritten despite overwriteExisting=false");

    return true;
}

// ------------------------------------------------------------------------------
// Test Case 12: Immediate Cancellation in Progress Callback & Full Cleanup
// ------------------------------------------------------------------------------
static bool Test_Split_Cancellation_Immediate_And_Cleanup() {
    // Small file (10 KB <= 64 KB single buffer read)
    fs::path inputPath = CreateDummyCharFile("cancel_immediate.txt", 10000);

    std::atomic<bool> cancelToken{false};
    SplitOptions opts;
    opts.inputFilePath = inputPath.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1000;
    opts.cancelToken = &cancelToken;
    opts.progressCallback = [&](size_t, size_t, uint64_t, uint64_t) {
        cancelToken.store(true); // Cancel on very first callback
    };

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);

    TEST_ASSERT(!res.success, "Engine should report failure when cancelled immediately");
    TEST_ASSERT(res.errorMessage.find(L"cancelled") != std::wstring::npos, "Error message should mention cancellation");
    TEST_ASSERT(res.generatedChunkPaths.empty(), "generatedChunkPaths should be empty on cancellation");

    // Verify chunk files deleted from disk
    std::wstring subfolder = TextSplitterEngine::GenerateSubfolderPath(inputPath.wstring(), L"");
    if (fs::exists(subfolder)) {
        for (const auto& entry : fs::directory_iterator(subfolder)) {
            (void)entry;
            TEST_ASSERT(false, "No chunk files should remain in subfolder after cancellation");
        }
    }

    return true;
}

// ------------------------------------------------------------------------------
// Main Entry Point
// ------------------------------------------------------------------------------
int main(int argc, char* argv[]) {
    if (argc > 1) {
        std::string firstArg = argv[1];
        if (firstArg == "--help" || firstArg == "-h") {
            std::cout << "Usage: test_engine.exe [--input <file>] [--limit <number>] [--mode <char|line>] [--output <dir>]\n";
            std::cout << "       test_engine.exe <input_file> <limit> [mode] [output_dir]\n";
            std::cout << "Running without arguments executes internal engine unit test suite.\n";
            return EXIT_SUCCESS;
        }

        SplitOptions opts;
        std::vector<std::string> args;
        for (int i = 1; i < argc; ++i) {
            args.push_back(argv[i]);
        }

        std::string inputPathStr;
        uint64_t limitVal = 3000;
        std::string modeStr = "char";
        std::string outputDirStr;

        for (size_t i = 0; i < args.size(); ++i) {
            if ((args[i] == "--input" || args[i] == "-i") && i + 1 < args.size()) {
                inputPathStr = args[++i];
            } else if ((args[i] == "--limit" || args[i] == "-l") && i + 1 < args.size()) {
                limitVal = std::stoull(args[++i]);
            } else if ((args[i] == "--mode" || args[i] == "-m") && i + 1 < args.size()) {
                modeStr = args[++i];
            } else if ((args[i] == "--output" || args[i] == "-o") && i + 1 < args.size()) {
                outputDirStr = args[++i];
            } else if (inputPathStr.empty() && args[i][0] != '-') {
                inputPathStr = args[i];
            } else if (i == 1 && args[i][0] != '-') {
                try {
                    limitVal = std::stoull(args[i]);
                } catch (...) {}
            }
        }

        if (inputPathStr.empty()) {
            std::cerr << "Error: No input file specified.\n";
            return EXIT_FAILURE;
        }

        fs::path p(inputPathStr);
        opts.inputFilePath = p.wstring();
        opts.maxLimit = limitVal;
        if (modeStr == "line" || modeStr == "lines" || modeStr == "ByLines" || modeStr == "1") {
            opts.mode = SplitMode::ByLines;
        } else {
            opts.mode = SplitMode::ByCharacters;
        }
        if (!outputDirStr.empty()) {
            opts.outputDir = fs::path(outputDirStr).wstring();
        }

        FileSplitResult res = TextSplitterEngine::SplitFile(opts);
        if (res.success) {
            std::cout << "SUCCESS\n";
            std::cout << "Chunks: " << res.chunksCreated << "\n";
            std::cout << "OutputFolder: " << fs::path(res.outputFolderPath).string() << "\n";
            for (const auto& chunkPath : res.generatedChunkPaths) {
                std::cout << "Chunk: " << fs::path(chunkPath).string() << "\n";
            }
            return EXIT_SUCCESS;
        } else {
            std::cerr << "ERROR: ";
            std::wcerr << res.errorMessage << L"\n";
            return EXIT_FAILURE;
        }
    }

    std::cout << "==================================================\n";
    std::cout << "TextSplitterEngine C++ Unit Test Runner (M1)\n";
    std::cout << "==================================================\n";

    CleanTestTempDir();

    RunTest("Test_Split_10k_Chars_By_3k_Limit", Test_Split_10k_Chars_By_3k_Limit);
    RunTest("Test_Split_Exact_Boundary_9k_Chars_By_3k_Limit", Test_Split_Exact_Boundary_9k_Chars_By_3k_Limit);
    RunTest("Test_Split_350_Lines_By_100_Line_Limit", Test_Split_350_Lines_By_100_Line_Limit);
    RunTest("Test_Split_Batch_Processing", Test_Split_Batch_Processing);
    RunTest("Test_Split_Error_Handling", Test_Split_Error_Handling);
    RunTest("Test_Split_UTF8_Multibyte_Preservation", Test_Split_UTF8_Multibyte_Preservation);
    RunTest("Test_Split_No_Trailing_Newline", Test_Split_No_Trailing_Newline);
    RunTest("Test_Split_Cancellation", Test_Split_Cancellation);
    RunTest("Test_Split_Batch_Isolation", Test_Split_Batch_Isolation);
    RunTest("Test_Split_Sanitize_Filename", Test_Split_Sanitize_Filename);
    RunTest("Test_Split_Overwrite_Existing_Flag", Test_Split_Overwrite_Existing_Flag);
    RunTest("Test_Split_Cancellation_Immediate_And_Cleanup", Test_Split_Cancellation_Immediate_And_Cleanup);

    CleanTestTempDir();

    std::cout << "==================================================\n";
    std::cout << "Summary: " << g_testsPassed << " PASSED, " << g_testsFailed << " FAILED.\n";
    std::cout << "==================================================\n";

    return (g_testsFailed == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}


