/**
 * @file stress_test_main.cpp
 * @brief Empirical stress testing suite for TextSplitterEngine (Milestone 1).
 * @author Challenger M1-1
 */

#include "TextSplitterEngine.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cassert>
#include <filesystem>
#include <chrono>
#include <thread>
#include <atomic>

using namespace FileSplitter;

namespace {
    int g_testsRun = 0;
    int g_testsPassed = 0;
    int g_testsFailed = 0;

    #define RUN_TEST(testFunc) \
        do { \
            g_testsRun++; \
            std::cout << "[RUN] " << #testFunc << " ... " << std::flush; \
            auto t0 = std::chrono::high_resolution_clock::now(); \
            bool passed = testFunc(); \
            auto t1 = std::chrono::high_resolution_clock::now(); \
            auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count(); \
            if (passed) { \
                g_testsPassed++; \
                std::cout << "[PASSED] (" << ms << " ms)" << std::endl; \
            } else { \
                g_testsFailed++; \
                std::cout << "[FAILED] (" << ms << " ms)" << std::endl; \
            } \
        } while(0)

    std::wstring CreateTempTestDir(const std::wstring& name) {
        std::filesystem::path p = std::filesystem::temp_directory_path() / L"FileSplitterStress" / name;
        std::filesystem::create_directories(p);
        return p.wstring();
    }

    std::wstring CreateTestFile(const std::wstring& dir, const std::wstring& filename, const std::string& content) {
        std::filesystem::path p = std::filesystem::path(dir) / filename;
        std::ofstream out(p.c_str(), std::ios::binary);
        out.write(content.data(), content.size());
        out.close();
        return p.wstring();
    }

    std::string ReadFileContent(const std::wstring& path) {
        std::ifstream in(path.c_str(), std::ios::binary);
        if (!in.is_open()) return "";
        return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    }

    std::string ConcatFiles(const std::vector<std::wstring>& paths) {
        std::string result;
        for (const auto& p : paths) {
            result += ReadFileContent(p);
        }
        return result;
    }
}

// -----------------------------------------------------------------------------
// Test 1: Line splitting on file WITHOUT trailing newline (Line unit counting)
// -----------------------------------------------------------------------------
bool Test_LineSplit_NoTrailingNewline_UnitCount() {
    std::wstring tempDir = CreateTempTestDir(L"line_no_nl");
    // "hello\nworld" has 2 lines. First line is "hello\n", second is "world".
    std::string content = "hello\nworld";
    std::wstring filePath = CreateTestFile(tempDir, L"no_trailing_nl.txt", content);

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByLines;
    opts.maxLimit = 1;

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (!result.success) {
        std::cout << "\n  [ERROR] Splitting failed: " << std::string(result.errorMessage.begin(), result.errorMessage.end());
        ok = false;
    }
    if (result.chunksCreated != 2) {
        std::cout << "\n  [MISMATCH] Expected 2 chunks, got " << result.chunksCreated;
        ok = false;
    }
    std::string reassembled = ConcatFiles(result.generatedChunkPaths);
    if (reassembled != content) {
        std::cout << "\n  [MISMATCH] Reassembled content does not match original";
        ok = false;
    }
    // Check totalUnitsProcessed: should be 2 lines ("hello\n" and "world")
    if (result.totalUnitsProcessed != 2) {
        std::cout << "\n  [BUG CONFIRMED] totalUnitsProcessed expected 2, got " << result.totalUnitsProcessed;
        ok = false; // Bug in engine totalUnitsProcessed for ByLines limit=1 without trailing newline
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 2: Overwrite existing chunks flag (options.overwriteExisting = false)
// -----------------------------------------------------------------------------
bool Test_OverwriteExisting_Flag() {
    std::wstring tempDir = CreateTempTestDir(L"overwrite_test");
    std::string content = "1234567890";
    std::wstring filePath = CreateTestFile(tempDir, L"sample.txt", content);

    // Pre-create output folder and existing chunk file with distinct content
    std::wstring subfolder = TextSplitterEngine::GenerateSubfolderPath(filePath, tempDir);
    std::filesystem::create_directories(subfolder);
    std::wstring existingChunk = TextSplitterEngine::GenerateChunkFileName(L"sample", 1);
    std::wstring existingChunkPath = (std::filesystem::path(subfolder) / existingChunk).wstring();
    
    std::ofstream preStream(existingChunkPath.c_str(), std::ios::binary);
    preStream << "PRE_EXISTING_DATA_THAT_SHOULD_NOT_BE_OVERWRITTEN";
    preStream.close();

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 5;
    opts.overwriteExisting = false; // Set to false!

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    std::string chunk1Content = ReadFileContent(existingChunkPath);
    if (chunk1Content == "PRE_EXISTING_DATA_THAT_SHOULD_NOT_BE_OVERWRITTEN") {
        // Did not overwrite -> respected flag
    } else {
        std::cout << "\n  [BUG CONFIRMED] overwriteExisting=false was IGNORED; existing chunk was overwritten!";
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 3: Multibyte UTF-8 characters across 64KB buffer boundaries & emojis
// -----------------------------------------------------------------------------
bool Test_Utf8_Multibyte_Complex_And_BufferBoundary() {
    std::wstring tempDir = CreateTempTestDir(L"utf8_multibyte");
    
    // Construct a large string (>70KB) with 4-byte emojis (😀 0xF0 0x9F 0x98 0x86),
    // 3-byte CJK chars (こんにちは 0xE3 0x81...), 2-byte chars (é 0xC3 0xA9)
    // positioned right around 64KB (65536 bytes)
    std::string pattern = "Hello World! 😀 こんにちは test éàüñ\n";
    std::string content;
    while (content.size() < 100000) {
        content += pattern;
    }

    std::wstring filePath = CreateTestFile(tempDir, L"utf8_large.txt", content);

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1500; // split by 1500 chars

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (!result.success) {
        std::cout << "\n  [ERROR] UTF-8 split failed: " << std::string(result.errorMessage.begin(), result.errorMessage.end());
        ok = false;
    }

    std::string reassembled = ConcatFiles(result.generatedChunkPaths);
    if (reassembled != content) {
        std::cout << "\n  [MISMATCH] UTF-8 reassembled content differs from original! Size original=" << content.size() << " reassembled=" << reassembled.size();
        ok = false;
    }

    // Verify none of the chunk files end with a truncated UTF-8 multibyte sequence
    for (size_t idx = 0; idx < result.generatedChunkPaths.size(); ++idx) {
        std::string chunkData = ReadFileContent(result.generatedChunkPaths[idx]);
        if (!chunkData.empty()) {
            unsigned char lastByte = static_cast<unsigned char>(chunkData.back());
            if ((lastByte & 0xE0) == 0xC0 || (lastByte & 0xF0) == 0xE0 || (lastByte & 0xF8) == 0xF0) {
                std::cout << "\n  [CORRECTION NEEDED] Chunk " << (idx+1) << " ends with incomplete UTF-8 lead byte 0x" << std::hex << (int)lastByte;
                ok = false;
            }
        }
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 4: 0-Byte Empty Input File
// -----------------------------------------------------------------------------
bool Test_ZeroByte_Input_File() {
    std::wstring tempDir = CreateTempTestDir(L"zero_byte");
    std::wstring filePath = CreateTestFile(tempDir, L"empty.txt", "");

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 1000;

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (!result.success) {
        std::cout << "\n  [ERROR] Zero-byte split failed: " << std::string(result.errorMessage.begin(), result.errorMessage.end());
        ok = false;
    }
    if (result.chunksCreated != 0) {
        std::cout << "\n  [NOTE] Zero-byte file created " << result.chunksCreated << " chunks";
    }
    if (result.totalBytesProcessed != 0) {
        std::cout << "\n  [MISMATCH] totalBytesProcessed=" << result.totalBytesProcessed;
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 5: Single Massive Line without newlines split by Lines mode
// -----------------------------------------------------------------------------
bool Test_MassiveLine_SplitByLines() {
    std::wstring tempDir = CreateTempTestDir(L"massive_line");
    std::string content(50000, 'A'); // 50,000 'A's without '\n'
    std::wstring filePath = CreateTestFile(tempDir, L"one_line.txt", content);

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByLines;
    opts.maxLimit = 10;

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (!result.success) {
        std::cout << "\n  [ERROR] Split failed: " << std::string(result.errorMessage.begin(), result.errorMessage.end());
        ok = false;
    }
    if (result.chunksCreated != 1) {
        std::cout << "\n  [MISMATCH] Expected 1 chunk for 0-newline file, got " << result.chunksCreated;
        ok = false;
    }
    if (result.totalUnitsProcessed != 1) {
        std::cout << "\n  [MISMATCH] Expected 1 line processed, got " << result.totalUnitsProcessed;
        ok = false;
    }
    std::string reassembled = ConcatFiles(result.generatedChunkPaths);
    if (reassembled != content) {
        std::cout << "\n  [MISMATCH] Reassembled content differs";
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 6: Zero Limit Validation (maxLimit = 0)
// -----------------------------------------------------------------------------
bool Test_ZeroLimit_Validation() {
    std::wstring tempDir = CreateTempTestDir(L"zero_limit");
    std::wstring filePath = CreateTestFile(tempDir, L"data.txt", "Some text data");

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 0; // Invalid

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (result.success) {
        std::cout << "\n  [BUG] SplitFile succeeded with maxLimit=0!";
        ok = false;
    }
    if (result.errorMessage.empty()) {
        std::cout << "\n  [BUG] Missing error message for maxLimit=0";
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 7: Non-Existent File and Directory Path Handling
// -----------------------------------------------------------------------------
bool Test_InvalidPaths_Handling() {
    std::wstring tempDir = CreateTempTestDir(L"invalid_paths");
    
    SplitOptions opts;
    opts.inputFilePath = tempDir + L"/non_existent_file_9999.txt";
    opts.outputDir = tempDir;
    opts.maxLimit = 100;

    FileSplitResult res1 = TextSplitterEngine::SplitFile(opts);
    bool ok = true;
    if (res1.success) {
        std::cout << "\n  [BUG] SplitFile succeeded on non-existent file!";
        ok = false;
    }

    // Directory as input file
    opts.inputFilePath = tempDir;
    FileSplitResult res2 = TextSplitterEngine::SplitFile(opts);
    if (res2.success) {
        std::cout << "\n  [BUG] SplitFile succeeded when inputFilePath is a directory!";
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 8: Cancellation Token Stress Test
// -----------------------------------------------------------------------------
bool Test_Cancellation_Token() {
    std::wstring tempDir = CreateTempTestDir(L"cancel_test");
    std::string largeContent(200000, 'X'); // 200 KB
    std::wstring filePath = CreateTestFile(tempDir, L"cancel_file.txt", largeContent);

    std::atomic<bool> cancelToken{false};

    SplitOptions opts;
    opts.inputFilePath = filePath;
    opts.outputDir = tempDir;
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 100;
    opts.cancelToken = &cancelToken;
    opts.progressCallback = [&](size_t, size_t, uint64_t bytesProcessed, uint64_t) {
        if (bytesProcessed > 5000) {
            cancelToken.store(true);
        }
    };

    FileSplitResult result = TextSplitterEngine::SplitFile(opts);

    bool ok = true;
    if (result.success) {
        std::cout << "\n  [BUG] SplitFile succeeded despite cancellation token set to true!";
        ok = false;
    }
    if (result.errorMessage.find(L"cancelled") == std::wstring::npos) {
        std::cout << "\n  [MISMATCH] Error message did not report cancellation";
        ok = false;
    }

    std::filesystem::remove_all(tempDir);
    return ok;
}

// -----------------------------------------------------------------------------
// Test 9: Filename Stem Sanitization with Special Windows Characters
// -----------------------------------------------------------------------------
bool Test_Filename_Sanitization() {
    std::wstring unsanitized = L"file:with*invalid?chars<name>|test";
    std::wstring sanitized = TextSplitterEngine::SanitizeFileName(unsanitized);

    bool ok = true;
    for (wchar_t ch : sanitized) {
        if (ch == L':' || ch == L'*' || ch == L'?' || ch == L'<' || ch == L'>' || ch == L'|') {
            std::cout << "\n  [BUG] Sanitization failed for character: " << (char)ch;
            ok = false;
        }
    }
    return ok;
}

// -----------------------------------------------------------------------------
// Test 10: Batch Split with mixed valid and invalid files
// -----------------------------------------------------------------------------
bool Test_BatchSplit_Mixed() {
    std::wstring tempDir = CreateTempTestDir(L"batch_mixed");
    std::wstring file1 = CreateTestFile(tempDir, L"file1.txt", "Content 1");
    std::wstring file2 = tempDir + L"/missing.txt"; // missing
    std::wstring file3 = CreateTestFile(tempDir, L"file3.txt", "Content 3");

    SplitOptions baseOpts;
    baseOpts.outputDir = tempDir;
    baseOpts.maxLimit = 100;

    BatchSplitResult batch = TextSplitterEngine::SplitBatch({file1, file2, file3}, baseOpts);

    bool ok = true;
    if (batch.totalFiles != 3) ok = false;
    if (batch.successfulFiles != 2) ok = false;
    if (batch.failedFiles != 1) ok = false;

    std::filesystem::remove_all(tempDir);
    return ok;
}

int main() {
    std::cout << "==================================================" << std::endl;
    std::cout << "TextSplitterEngine Stress & Edge-Case Test Harness" << std::endl;
    std::cout << "==================================================" << std::endl;

    RUN_TEST(Test_LineSplit_NoTrailingNewline_UnitCount);
    RUN_TEST(Test_OverwriteExisting_Flag);
    RUN_TEST(Test_Utf8_Multibyte_Complex_And_BufferBoundary);
    RUN_TEST(Test_ZeroByte_Input_File);
    RUN_TEST(Test_MassiveLine_SplitByLines);
    RUN_TEST(Test_ZeroLimit_Validation);
    RUN_TEST(Test_InvalidPaths_Handling);
    RUN_TEST(Test_Cancellation_Token);
    RUN_TEST(Test_Filename_Sanitization);
    RUN_TEST(Test_BatchSplit_Mixed);

    std::cout << "==================================================" << std::endl;
    std::cout << "Summary: " << g_testsPassed << " PASSED, " << g_testsFailed << " FAILED." << std::endl;
    std::cout << "==================================================" << std::endl;

    return (g_testsFailed == 0) ? 0 : 1;
}
