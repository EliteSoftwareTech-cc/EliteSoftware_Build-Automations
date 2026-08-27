/**
 * @file Logger.cpp
 * @brief Implementation of system logging facility for File Splitter GUI.
 * @author EliteSoftwareTech Co.
 */

#include "Logger.h"
#include <shellapi.h>
#include <shlwapi.h>
#include <ctime>
#include <sstream>
#include <iomanip>

#pragma region Logger Implementation

namespace FileSplitter {

std::mutex Logger::s_logMutex;

std::wstring Logger::GetLogFilePath() {
    wchar_t szSysDrive[MAX_PATH] = L"C:";
    DWORD dwRet = GetEnvironmentVariableW(L"SystemDrive", szSysDrive, MAX_PATH);
    if (dwRet == 0 || dwRet >= MAX_PATH) {
        wcscpy_s(szSysDrive, MAX_PATH, L"C:");
    }
    
    std::wstring logDir = std::wstring(szSysDrive) + L"\\EliteSoftware\\Logs";
    
    // Ensure directory structure exists
    std::wstring parentDir = std::wstring(szSysDrive) + L"\\EliteSoftware";
    CreateDirectoryW(parentDir.c_str(), NULL);
    CreateDirectoryW(logDir.c_str(), NULL);
    
    return logDir + L"\\FileSplitter.log";
}

std::wstring Logger::GetCurrentTimestamp() {
    std::time_t now = std::time(nullptr);
    std::tm tm_buf{};
#if defined(_WIN32)
    localtime_s(&tm_buf, &now);
#else
    tm_buf = *std::localtime(&now);
#endif

    std::wostringstream wos;
    wos << std::put_time(&tm_buf, L"%Y-%m-%d %H:%M:%S");
    return wos.str();
}

void Logger::Initialize() {
    std::lock_guard<std::mutex> lock(s_logMutex);
    std::wstring logPath = GetLogFilePath();

    std::wofstream logFile(logPath.c_str(), std::ios::app);
    if (logFile.is_open()) {
        logFile << L"================================================================================\n";
        logFile << L"SESSION START: " << GetCurrentTimestamp() << L" | FileSplitter v1.2.0.0\n";
        logFile << L"================================================================================\n";
        logFile.close();
    }
}

void Logger::Log(LogLevel level, const std::wstring& message) {
    std::lock_guard<std::mutex> lock(s_logMutex);
    std::wstring logPath = GetLogFilePath();

    std::wofstream logFile(logPath.c_str(), std::ios::app);
    if (logFile.is_open()) {
        const wchar_t* levelStr = L"INFO";
        if (level == LogLevel::Warning) levelStr = L"WARN";
        else if (level == LogLevel::Error) levelStr = L"ERR ";

        logFile << L"[" << levelStr << L"] [" << GetCurrentTimestamp() << L"] " << message << L"\n";
        logFile.close();
    }
}

void Logger::LogInfo(const std::wstring& message) {
    Log(LogLevel::Info, message);
}

void Logger::LogWarning(const std::wstring& message) {
    Log(LogLevel::Warning, message);
}

void Logger::LogError(const std::wstring& message) {
    Log(LogLevel::Error, message);
}

void Logger::OpenLogFileInNotepad(HWND hWndParent) {
    std::wstring logPath = GetLogFilePath();

    // Make sure log file exists before opening Notepad
    {
        std::lock_guard<std::mutex> lock(s_logMutex);
        std::wofstream checkFile(logPath.c_str(), std::ios::app);
        if (checkFile.is_open()) {
            checkFile.close();
        }
    }

    HINSTANCE hInst = ShellExecuteW(hWndParent, L"open", L"notepad.exe", logPath.c_str(), NULL, SW_SHOWNORMAL);
    if ((INT_PTR)hInst <= 32) {
        MessageBoxW(hWndParent,
            L"Failed to launch Notepad for log viewing. Even Notepad is giving up today.",
            L"EliteSoftware Error", MB_OK | MB_ICONERROR);
    }
}

} // namespace FileSplitter

#pragma endregion
