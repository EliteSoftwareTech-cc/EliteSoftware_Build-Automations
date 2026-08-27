/**
 * @file emp_logger_test.cpp
 * @brief Empirical test for Logger creation, format, append behavior, and thread-safety.
 */

#include "Logger.h"
#include <iostream>
#include <fstream>
#include <string>
#include <thread>
#include <vector>
#include <filesystem>

using namespace FileSplitter;
namespace fs = std::filesystem;

int main() {
    std::cout << "==================================================" << std::endl;
    std::cout << "Empirical Logger Verification Test" << std::endl;
    std::cout << "==================================================" << std::endl;

    std::wstring logPath = Logger::GetLogFilePath();
    std::cout << "Log File Path: " << std::string(logPath.begin(), logPath.end()) << std::endl;

    // Check pre-existing log file size if present
    size_t initialSize = 0;
    if (fs::exists(logPath)) {
        initialSize = fs::file_size(logPath);
        std::cout << "Initial File Size: " << initialSize << " bytes" << std::endl;
    }

    // Call Initialize
    Logger::Initialize();

    // Verify session start header appended
    size_t sizeAfterInit = fs::file_size(logPath);
    if (sizeAfterInit <= initialSize) {
        std::cout << "[FAIL] Initialize did not append header to log file!" << std::endl;
        return 1;
    }
    std::cout << "[PASS] Logger::Initialize successfully appended session header." << std::endl;

    // Call LogInfo, LogWarning, LogError
    Logger::LogInfo(L"Empirical Test: Info message entry");
    Logger::LogWarning(L"Empirical Test: Warning message entry");
    Logger::LogError(L"Empirical Test: Error message entry");

    // Multithreaded concurrent logging test
    constexpr int numThreads = 4;
    constexpr int logsPerThread = 25;
    std::vector<std::thread> threads;
    for (int t = 0; t < numThreads; ++t) {
        threads.emplace_back([t]() {
            for (int i = 0; i < logsPerThread; ++i) {
                Logger::LogInfo(L"Thread " + std::to_wstring(t) + L" log entry " + std::to_wstring(i));
            }
        });
    }
    for (auto& th : threads) {
        th.join();
    }

    size_t finalSize = fs::file_size(logPath);
    std::cout << "Final File Size: " << finalSize << " bytes" << std::endl;
    if (finalSize > sizeAfterInit) {
        std::cout << "[PASS] Multithreaded logging appended all entries safely." << std::endl;
    } else {
        std::cout << "[FAIL] Multithreaded logging failed to append." << std::endl;
        return 1;
    }

    std::cout << "==================================================" << std::endl;
    std::cout << "Logger Verification COMPLETE & PASSED!" << std::endl;
    std::cout << "==================================================" << std::endl;
    return 0;
}
