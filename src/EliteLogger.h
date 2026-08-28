#pragma once
#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <chrono>
#include <filesystem>
#include <sstream>
#include <algorithm>

namespace fs = std::filesystem;

// ============================================================================
// EliteSoftware Unified Exit Code Taxonomy
// ============================================================================
enum EliteExitCode {
    ELITE_SUCCESS                   = 0,   // Execution succeeded without errors
    ELITE_ERROR_GENERAL             = 1,   // Unspecified runtime / execution failure
    ELITE_ERROR_CONFIG_MISSING      = 10,  // .config or JSON configuration file not found
    ELITE_ERROR_INVALID_ARGS        = 11,  // Invalid arguments, missing required flags, or schema violation
    ELITE_ERROR_FILE_NOT_FOUND      = 12,  // Target source file or binary not found
    ELITE_ERROR_TARGET_EXISTS       = 13,  // Target file/directory already exists and overwrite was not permitted
    ELITE_ERROR_HANDLE_LOCKED       = 20,  // Target file, folder, or process is locked
    ELITE_ERROR_ACCESS_DENIED       = 30,  // Operation requires Administrator / Elevated privileges
    ELITE_ERROR_DEPENDENCY_MISSING  = 40,  // Prerequisite binary or SDK (GCC, MSBuild, ISCC) missing
    ELITE_ERROR_ENV_MISSING         = 50,  // Required environment variable not found
    ELITE_ERROR_COMPILATION_FAILED  = 60,  // Source code compilation or resource compilation failed
    ELITE_ERROR_SIGNING_FAILED      = 70,  // Authenticode signing or certificate installation failed
    ELITE_ERROR_NETWORK_FAILED      = 80,  // HTTP / API / Network request failed
    ELITE_ERROR_GIT_FAILED          = 90,  // Git command or GitHub API interaction failed
    ELITE_ERROR_EULA_REJECTED       = 99   // Interactive EULA prompt was rejected
};

// ============================================================================
// Global State & Thread-Safe Logging Engine
// ============================================================================
__declspec(selectany) bool g_EliteAiMode = false;
__declspec(selectany) bool g_IsRootProcess = false;
__declspec(selectany) std::string g_EliteToolName = "EliteTool";
__declspec(selectany) std::string g_EliteLogPath = "";

inline std::string __EliteGetExePath() {
    char result[MAX_PATH];
    GetModuleFileNameA(NULL, result, MAX_PATH);
    return std::string(result);
}

inline std::string __EliteGetExeDir() {
    std::string path = __EliteGetExePath();
    size_t lastSlash = path.find_last_of("\\/");
    return (lastSlash != std::string::npos) ? path.substr(0, lastSlash) : ".";
}

inline std::string __EliteGetTimestamp() {
    auto now = std::chrono::system_clock::now();
    std::time_t now_time = std::chrono::system_clock::to_time_t(now);
    struct tm buf;
    localtime_s(&buf, &now_time);
    char timeStr[64];
    strftime(timeStr, sizeof(timeStr), "%Y-%m-%d %H:%M:%S", &buf);
    return std::string(timeStr);
}

inline void __EliteInitLogFile() {
    if (!g_EliteLogPath.empty()) return;

    // Standard log location: %SystemDrive%\EliteSoftware\Logs\<ToolName>.log
    char sysDrive[16] = "C:";
    char* envDrive = getenv("SystemDrive");
    if (envDrive) strcpy_s(sysDrive, envDrive);

    std::string primaryDir = std::string(sysDrive) + "\\EliteSoftware\\Logs";
    std::error_code ec;
    fs::create_directories(primaryDir, ec);

    if (!ec && fs::exists(primaryDir)) {
        g_EliteLogPath = primaryDir + "\\" + g_EliteToolName + ".log";
    } else {
        // Fallback to <ExeDir>\Logs\<ToolName>.log
        std::string fallbackDir = __EliteGetExeDir() + "\\Logs";
        fs::create_directories(fallbackDir, ec);
        g_EliteLogPath = fallbackDir + "\\" + g_EliteToolName + ".log";
    }
}

inline bool IsAiMode() {
    if (g_EliteAiMode) return true;
    if (strstr(GetCommandLineA(), "--ai-mode") != nullptr) {
        g_EliteAiMode = true;
        return true;
    }
    const char* envAi = getenv("ELITE_AI_MODE");
    if (envAi && (std::string(envAi) == "1" || std::string(envAi) == "true")) {
        g_EliteAiMode = true;
        return true;
    }
    return false;
}

inline void EliteInit(const std::string& toolName, int argc = 0, char* argv[] = nullptr) {
    g_EliteToolName = toolName;
    g_EliteAiMode = IsAiMode();

    if (getenv("ELITE_IS_CHILD") == nullptr) {
        g_IsRootProcess = true;
        _putenv_s("ELITE_IS_CHILD", "1");
    } else {
        g_IsRootProcess = false;
    }

    __EliteInitLogFile();

    // In AI Mode: Update console title, bypass EULA, suppress noise
    if (g_EliteAiMode) {
        char currentTitle[512];
        if (GetConsoleTitleA(currentTitle, 512) > 0) {
            std::string titleStr(currentTitle);
            if (titleStr.find("(Ai Mode)") == std::string::npos) {
                std::string newTitle = titleStr + " (Ai Mode)";
                SetConsoleTitleA(newTitle.c_str());
            }
        } else {
            SetConsoleTitleA((toolName + " (Ai Mode)").c_str());
        }
    }

    // Write session banner to log file
    std::ofstream logFile(g_EliteLogPath, std::ios_base::app);
    if (logFile.is_open()) {
        logFile << "\n======================================================\n";
        logFile << "[" << __EliteGetTimestamp() << "] Starting " << toolName 
                << " (Mode: " << (g_EliteAiMode ? "AI/Headless" : "User/Interactive") << ")\n";
        logFile << "Command Line: " << GetCommandLineA() << "\n";
        logFile << "======================================================\n";
        logFile.close();
    }
}

// User-Mode EULA Check (skipped in AI mode)
inline void CheckEULA() {
    if (IsAiMode()) return;

    HKEY hKey;
    LSTATUS status = RegOpenKeyExA(HKEY_CURRENT_USER, "Software\\EliteSoftware\\EULA", 0, KEY_READ, &hKey);
    if (status != ERROR_SUCCESS) {
        std::cout << "\n======================================================\n";
        std::cout << " EliteSoftwareTech Co. End User License Agreement\n";
        std::cout << "======================================================\n";
        std::cout << "By using this tool, you agree to absolute system purity.\n";
        std::cout << "Do you accept? (Y/N): ";
        std::string resp;
        std::getline(std::cin, resp);
        if (resp == "Y" || resp == "y" || resp == "yes") {
            RegCreateKeyExA(HKEY_CURRENT_USER, "Software\\EliteSoftware\\EULA", 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &hKey, NULL);
            DWORD val = 1;
            RegSetValueExA(hKey, "Accepted", 0, REG_DWORD, (const BYTE*)&val, sizeof(val));
            RegCloseKey(hKey);
        } else {
            std::cerr << "EULA Rejected. Exiting.\n";
            exit(ELITE_ERROR_EULA_REJECTED);
        }
    } else {
        RegCloseKey(hKey);
    }
}

// Unified Log Function: Always logs to file. In User Mode, prints to console. In AI Mode, console is silent.
inline void EliteLog(const std::string& message, const std::string& type = "INFO") {
    __EliteInitLogFile();
    std::string timestamp = __EliteGetTimestamp();

    // 1. Write to Log File
    std::ofstream logFile(g_EliteLogPath, std::ios_base::app);
    if (logFile.is_open()) {
        logFile << "[" << timestamp << "] [" << type << "] " << message << "\n";
        logFile.close();
    }

    // 2. Output to Console ONLY for User Mode (AI Mode is silent on stdout)
    if (!IsAiMode()) {
        if (type == "ERROR" || type == "CRITICAL") {
            std::cerr << "[" << type << "] " << message << "\n";
        } else if (type == "WARN" || type == "WARNING") {
            std::cout << "[WARN] " << message << "\n";
        } else {
            std::cout << "[" << type << "] " << message << "\n";
        }
    }
}

// Backward compatibility alias for WriteEliteLog

inline void EliteLog(const std::wstring& wmsg) {
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wmsg.c_str(), (int)wmsg.length(), NULL, 0, NULL, NULL);
    std::string strTo(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wmsg.c_str(), (int)wmsg.length(), &strTo[0], size_needed, NULL, NULL);
    EliteLog(strTo);
}

inline void WriteEliteLog(const std::string& message, const std::string& type = "INFO") {
    EliteLog(message, type);
}

// Unified Error Function: Logs error, formats output based on mode, and returns exit code
inline int EliteError(EliteExitCode code, const std::string& errorType, const std::string& message, 
                       const std::string& paramFault = "", const std::string& remediation = "") {
    __EliteInitLogFile();
    std::string timestamp = __EliteGetTimestamp();

    // 1. Log to File
    std::ofstream logFile(g_EliteLogPath, std::ios_base::app);
    if (logFile.is_open()) {
        logFile << "[" << timestamp << "] [ERROR:" << code << "] [" << errorType << "] " << message << "\n";
        if (!paramFault.empty()) logFile << "  -> Parameter Fault: " << paramFault << "\n";
        if (!remediation.empty()) logFile << "  -> Remediation: " << remediation << "\n";
        logFile.close();
    }

    // 2. Output based on Mode
    if (IsAiMode()) {
        // Output Machine-Readable JSON to stderr
        std::cerr << "{\"exit_code\":" << (int)code 
                  << ",\"error_type\":\"" << errorType << "\""
                  << ",\"message\":\"" << message << "\"";
        if (!paramFault.empty()) std::cerr << ",\"parameter_fault\":\"" << paramFault << "\"";
        if (!remediation.empty()) std::cerr << ",\"remediation\":\"" << remediation << "\"";
        std::cerr << "}\n";
    } else {
        // Output Human-Friendly Message to stderr
        std::cerr << "\n[ERROR " << (int)code << "] (" << errorType << "): " << message << "\n";
        if (!paramFault.empty()) std::cerr << "  Faulty Parameter: " << paramFault << "\n";
        if (!remediation.empty()) std::cerr << "  Suggested Fix:    " << remediation << "\n";
        std::cerr << "  Log File:         " << g_EliteLogPath << "\n\n";
    }

    return (int)code;
}

inline void EliteExit(int exitCode) {
    std::ofstream logFile(g_EliteLogPath, std::ios_base::app);
    if (logFile.is_open()) {
        logFile << "[" << __EliteGetTimestamp() << "] Finished " << g_EliteToolName 
                << " with Exit Code " << exitCode << "\n\n";
        logFile.close();
    }
    if (!IsAiMode() && exitCode != 0) {
        std::cout << "\nPress any key to exit...\n";
        system("pause >nul");
    }
    exit(exitCode);
}

// Child Process Execution Engine
inline int ExecuteCommand(const std::string& cmd) {
    EliteLog("Executing: " + cmd, "EXEC");

    SECURITY_ATTRIBUTES saAttr; 
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES); 
    saAttr.bInheritHandle = TRUE; 
    saAttr.lpSecurityDescriptor = NULL; 

    HANDLE hChildStd_OUT_Rd = NULL;
    HANDLE hChildStd_OUT_Wr = NULL;

    if (!CreatePipe(&hChildStd_OUT_Rd, &hChildStd_OUT_Wr, &saAttr, 0)) {
        return EliteError(ELITE_ERROR_GENERAL, "PIPE_CREATION_FAILED", 
                          "Failed to create anonymous pipe for child process.", "", "Check Windows process handles.");
    }
    SetHandleInformation(hChildStd_OUT_Rd, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOA siStartInfo;
    ZeroMemory(&siStartInfo, sizeof(STARTUPINFOA));
    siStartInfo.cb = sizeof(STARTUPINFOA); 
    siStartInfo.hStdError = hChildStd_OUT_Wr;
    siStartInfo.hStdOutput = hChildStd_OUT_Wr;
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

    PROCESS_INFORMATION piProcInfo; 
    ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));

    if (!CreateProcessA(NULL, (LPSTR)cmd.c_str(), NULL, NULL, TRUE, 0, NULL, NULL, &siStartInfo, &piProcInfo)) {
        CloseHandle(hChildStd_OUT_Wr);
        CloseHandle(hChildStd_OUT_Rd);
        return EliteError(ELITE_ERROR_GENERAL, "PROCESS_SPAWN_FAILED", 
                          "Failed to spawn process: " + cmd + " (Win32 Error: " + std::to_string(GetLastError()) + ")", 
                          cmd, "Ensure executable exists and is in system PATH.");
    }

    CloseHandle(hChildStd_OUT_Wr);

    DWORD dwRead;
    CHAR chBuf[4096];
    bool success = FALSE;

    std::ofstream logFile(g_EliteLogPath, std::ios_base::app);

    while (true) {
        success = ReadFile(hChildStd_OUT_Rd, chBuf, 4095, &dwRead, NULL);
        if (!success || dwRead == 0) break;
        chBuf[dwRead] = '\0';
        
        // Log to file
        if (logFile.is_open()) {
            logFile << chBuf;
        }

        // Print to console ONLY in User Mode
        if (!IsAiMode()) {
            std::cout << chBuf;
        }
    }
    if (logFile.is_open()) logFile.close();
    CloseHandle(hChildStd_OUT_Rd);

    WaitForSingleObject(piProcInfo.hProcess, INFINITE);
    DWORD exitCode;
    GetExitCodeProcess(piProcInfo.hProcess, &exitCode);
    CloseHandle(piProcInfo.hProcess);
    CloseHandle(piProcInfo.hThread);

    if (exitCode != 0) {
        EliteLog("Process exited with non-zero code: " + std::to_string(exitCode), "WARN");
    }
    return exitCode;
}

inline void InitEliteLogger() {
    EliteInit("EliteBuildChain");
}

inline void AppendToLog(const std::string& text) {
    EliteLog(text);
}
