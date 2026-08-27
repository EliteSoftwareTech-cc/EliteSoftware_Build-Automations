/**
 * @file emp_stress_m5_2.cpp
 * @brief Empirical stress testing runner for Milestone 5 Challenger 2.
 */

#include "TextSplitterEngine.h"
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <chrono>
#include <windows.h>

using namespace FileSplitter;
namespace fs = std::filesystem;

static int g_passCount = 0;
static int g_failCount = 0;

#define EMP_TEST(name, func) \
    do { \
        std::cout << "[EMP_TEST] " << name << " ... " << std::flush; \
        auto t0 = std::chrono::high_resolution_clock::now(); \
        bool pass = func(); \
        auto t1 = std::chrono::high_resolution_clock::now(); \
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(t1 - t0).count(); \
        if (pass) { \
            std::cout << "[PASSED] (" << ms << " ms)\n"; \
            g_passCount++; \
        } else { \
            std::cout << "[FAILED] (" << ms << " ms)\n"; \
            g_failCount++; \
        } \
    } while(0)

static fs::path GetTempDir() {
    fs::path p = fs::temp_directory_path() / "M5_2_StressTest";
    std::error_code ec;
    fs::create_directories(p, ec);
    return p;
}

static std::string ReadFileBinary(const fs::path& p) {
    std::ifstream in(p.c_str(), std::ios::binary);
    if (!in.is_open()) return "";
    return std::string((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
}

static std::string ConcatChunkFiles(const std::vector<std::wstring>& paths) {
    std::string result;
    for (const auto& p : paths) {
        result += ReadFileBinary(fs::path(p));
    }
    return result;
}

// 1a. Empty input file (0 bytes)
bool Test_Empty_File_ByChars_And_ByLines() {
    fs::path dir = GetTempDir() / "empty_test";
    fs::create_directories(dir);
    fs::path emptyFile = dir / "zero_byte.txt";
    {
        std::ofstream out(emptyFile.c_str(), std::ios::binary);
    } // create 0-byte file

    // Test ByCharacters mode
    SplitOptions opts1;
    opts1.inputFilePath = emptyFile.wstring();
    opts1.outputDir = dir.wstring();
    opts1.mode = SplitMode::ByCharacters;
    opts1.maxLimit = 100;

    FileSplitResult res1 = TextSplitterEngine::SplitFile(opts1);
    if (!res1.success) {
        std::cout << " (res1.success false: " << std::string(res1.errorMessage.begin(), res1.errorMessage.end()) << ")";
        return false;
    }
    if (res1.chunksCreated != 0 || res1.totalBytesProcessed != 0) {
        std::cout << " (res1 expected 0 chunks/bytes, got " << res1.chunksCreated << " chunks, " << res1.totalBytesProcessed << " bytes)";
        return false;
    }

    // Test ByLines mode
    SplitOptions opts2;
    opts2.inputFilePath = emptyFile.wstring();
    opts2.outputDir = dir.wstring();
    opts2.mode = SplitMode::ByLines;
    opts2.maxLimit = 10;

    FileSplitResult res2 = TextSplitterEngine::SplitFile(opts2);
    if (!res2.success) {
        std::cout << " (res2.success false: " << std::string(res2.errorMessage.begin(), res2.errorMessage.end()) << ")";
        return false;
    }
    if (res2.chunksCreated != 0 || res2.totalBytesProcessed != 0) {
        std::cout << " (res2 expected 0 chunks/bytes, got " << res2.chunksCreated << " chunks)";
        return false;
    }

    fs::remove_all(dir);
    return true;
}

// 1b. Very small limit: 1 char limit & 1 line limit
bool Test_VerySmall_Limit_1Char_And_1Line() {
    fs::path dir = GetTempDir() / "small_limit_test";
    fs::create_directories(dir);

    // 1Char limit test
    fs::path charFile = dir / "chars500.txt";
    std::string charData;
    for (int i = 0; i < 500; ++i) {
        charData += (char)('a' + (i % 26));
    }
    {
        std::ofstream out(charFile.c_str(), std::ios::binary);
        out.write(charData.data(), charData.size());
    }

    SplitOptions optsChar;
    optsChar.inputFilePath = charFile.wstring();
    optsChar.outputDir = dir.wstring();
    optsChar.mode = SplitMode::ByCharacters;
    optsChar.maxLimit = 1;

    FileSplitResult resChar = TextSplitterEngine::SplitFile(optsChar);
    if (!resChar.success) {
        std::cout << " (1Char split failed)";
        return false;
    }
    if (resChar.chunksCreated != 500) {
        std::cout << " (1Char expected 500 chunks, got " << resChar.chunksCreated << ")";
        return false;
    }
    std::string reassembledChar = ConcatChunkFiles(resChar.generatedChunkPaths);
    if (reassembledChar != charData) {
        std::cout << " (1Char reassembled mismatch)";
        return false;
    }

    // 1Line limit test
    fs::path lineFile = dir / "lines300.txt";
    std::string lineData;
    for (int i = 0; i < 300; ++i) {
        lineData += "Line number " + std::to_string(i) + "\r\n";
    }
    {
        std::ofstream out(lineFile.c_str(), std::ios::binary);
        out.write(lineData.data(), lineData.size());
    }

    SplitOptions optsLine;
    optsLine.inputFilePath = lineFile.wstring();
    optsLine.outputDir = dir.wstring();
    optsLine.mode = SplitMode::ByLines;
    optsLine.maxLimit = 1;

    FileSplitResult resLine = TextSplitterEngine::SplitFile(optsLine);
    if (!resLine.success) {
        std::cout << " (1Line split failed)";
        return false;
    }
    if (resLine.chunksCreated != 300) {
        std::cout << " (1Line expected 300 chunks, got " << resLine.chunksCreated << ")";
        return false;
    }
    std::string reassembledLine = ConcatChunkFiles(resLine.generatedChunkPaths);
    if (reassembledLine != lineData) {
        std::cout << " (1Line reassembled mismatch)";
        return false;
    }

    // Zero limit validation check
    SplitOptions optsZero;
    optsZero.inputFilePath = charFile.wstring();
    optsZero.outputDir = dir.wstring();
    optsZero.maxLimit = 0;

    FileSplitResult resZero = TextSplitterEngine::SplitFile(optsZero);
    if (resZero.success || resZero.errorMessage.empty()) {
        std::cout << " (maxLimit=0 did not fail as expected)";
        return false;
    }

    fs::remove_all(dir);
    return true;
}

// 1c. Large input file
bool Test_Large_Input_File() {
    fs::path dir = GetTempDir() / "large_file_test";
    fs::create_directories(dir);
    fs::path largeFile = dir / "large_5mb.txt";

    std::string chunkBlock(1024, 'X');
    chunkBlock[1023] = '\n';
    std::string largeData;
    largeData.reserve(5 * 1024 * 1024);
    for (int i = 0; i < 5120; ++i) { // 5 MB
        largeData += chunkBlock;
    }

    {
        std::ofstream out(largeFile.c_str(), std::ios::binary);
        out.write(largeData.data(), largeData.size());
    }

    SplitOptions opts;
    opts.inputFilePath = largeFile.wstring();
    opts.outputDir = dir.wstring();
    opts.mode = SplitMode::ByCharacters;
    opts.maxLimit = 50000; // Split into 105 chunks

    FileSplitResult res = TextSplitterEngine::SplitFile(opts);
    if (!res.success) {
        std::cout << " (Large file split failed: " << std::string(res.errorMessage.begin(), res.errorMessage.end()) << ")";
        return false;
    }

    std::string reassembled = ConcatChunkFiles(res.generatedChunkPaths);
    if (reassembled != largeData) {
        std::cout << " (Large file reassembled binary identity mismatch!)";
        return false;
    }

    fs::remove_all(dir);
    return true;
}

// 1d. Invalid / read-only output directory paths
bool Test_Invalid_And_ReadOnly_Output_Dir() {
    fs::path dir = GetTempDir() / "invalid_out_test";
    fs::create_directories(dir);

    fs::path sampleFile = dir / "input.txt";
    {
        std::ofstream out(sampleFile.c_str(), std::ios::binary);
        out << "Sample test content for invalid directory test.\n";
    }

    // Subtest A: Truly invalid path containing illegal characters or impossible path
    SplitOptions optsInvalid;
    optsInvalid.inputFilePath = sampleFile.wstring();
    optsInvalid.outputDir = L"C:\\InvalidPath_?:*<>|/Subdir";
    optsInvalid.maxLimit = 100;

    FileSplitResult resInvalid = TextSplitterEngine::SplitFile(optsInvalid);
    std::cout << "\n    [DIAG] resInvalid.outputFolderPath = '"
              << std::string(resInvalid.outputFolderPath.begin(), resInvalid.outputFolderPath.end()) << "'\n"
              << "    [DIAG] resInvalid.success = " << (resInvalid.success ? "true" : "false")
              << ", errorMessage = '" << std::string(resInvalid.errorMessage.begin(), resInvalid.errorMessage.end()) << "'"
              << ", chunksCreated = " << resInvalid.chunksCreated << "\n    ";

    if (resInvalid.success) {
        return false;
    }

    // Subtest B: Using a regular file path as output directory
    fs::path fileAsDir = dir / "some_file.txt";
    {
        std::ofstream out(fileAsDir.c_str());
        out << "I am a file, not a folder.";
    }

    SplitOptions optsFileAsDir;
    optsFileAsDir.inputFilePath = sampleFile.wstring();
    optsFileAsDir.outputDir = fileAsDir.wstring();
    optsFileAsDir.maxLimit = 100;

    FileSplitResult resFileAsDir = TextSplitterEngine::SplitFile(optsFileAsDir);
    std::cout << "[DIAG] resFileAsDir.outputFolderPath = '"
              << std::string(resFileAsDir.outputFolderPath.begin(), resFileAsDir.outputFolderPath.end()) << "'\n"
              << "    [DIAG] resFileAsDir.success = " << (resFileAsDir.success ? "true" : "false")
              << ", errorMessage = '" << std::string(resFileAsDir.errorMessage.begin(), resFileAsDir.errorMessage.end()) << "'"
              << ", chunksCreated = " << resFileAsDir.chunksCreated << "\n    ";

    if (resFileAsDir.success) {
        return false;
    }

    fs::remove_all(dir);
    return true;
}

int main() {
    std::cout << "==================================================" << std::endl;
    std::cout << "Milestone 5 Challenger 2 Empirical Stress Test Suite" << std::endl;
    std::cout << "==================================================" << std::endl;

    EMP_TEST("Test_Empty_File_ByChars_And_ByLines", Test_Empty_File_ByChars_And_ByLines);
    EMP_TEST("Test_VerySmall_Limit_1Char_And_1Line", Test_VerySmall_Limit_1Char_And_1Line);
    EMP_TEST("Test_Large_Input_File", Test_Large_Input_File);
    EMP_TEST("Test_Invalid_And_ReadOnly_Output_Dir", Test_Invalid_And_ReadOnly_Output_Dir);

    std::cout << "==================================================" << std::endl;
    std::cout << "Stress Suite Summary: " << g_passCount << " PASSED, " << g_failCount << " FAILED." << std::endl;
    std::cout << "==================================================" << std::endl;

    return (g_failCount == 0) ? 0 : 1;
}
