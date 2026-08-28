#pragma once
#include <windows.h>
#include <fstream>
#include <iostream>
#include <string>

__declspec(selectany) bool g_IsRootProcess = false;

inline void InitEliteLogger() {
    if (getenv("ELITE_IS_CHILD") == nullptr) {
        g_IsRootProcess = true;
        std::ofstream initLog("EliteBuild.log", std::ios_base::out | std::ios_base::trunc);
        if (initLog.is_open()) {
            initLog << "=== EliteSoftware Build Pipeline Log ===\n";
            initLog.close();
        }
        _putenv_s("ELITE_IS_CHILD", "1");
    } else {
        g_IsRootProcess = false;
    }
}

inline void AppendToLog(const std::string& text) {
    if (g_IsRootProcess) {
        std::ofstream logFile("EliteBuild.log", std::ios_base::app);
        if (logFile.is_open()) {
            logFile << text;
        }
    }
}

inline int ExecuteCommand(const std::string& cmd) {
    std::string prefix = "Executing";
    std::string logMsg = "\n[" + prefix + "] Executing: " + cmd + "\n";
    std::cout << logMsg;
    AppendToLog(logMsg);

    SECURITY_ATTRIBUTES saAttr; 
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES); 
    saAttr.bInheritHandle = TRUE; 
    saAttr.lpSecurityDescriptor = NULL; 

    HANDLE hChildStd_OUT_Rd = NULL;
    HANDLE hChildStd_OUT_Wr = NULL;

    if (!CreatePipe(&hChildStd_OUT_Rd, &hChildStd_OUT_Wr, &saAttr, 0)) {
        std::string err = "[" + prefix + "] ERROR: Failed to create pipe for command execution.\n";
        std::cerr << err;
        AppendToLog(err);
        return 1;
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
        std::string err = "[" + prefix + "] ERROR: Failed to execute. Error: " + std::to_string(GetLastError()) + "\n";
        std::cerr << err;
        AppendToLog(err);
        CloseHandle(hChildStd_OUT_Wr);
        CloseHandle(hChildStd_OUT_Rd);
        return 1;
    }

    CloseHandle(hChildStd_OUT_Wr);

    DWORD dwRead;
    CHAR chBuf[4096];
    bool success = FALSE;

    while (true) {
        success = ReadFile(hChildStd_OUT_Rd, chBuf, 4095, &dwRead, NULL);
        if (!success || dwRead == 0) break;
        chBuf[dwRead] = '\0';
        std::cout << chBuf;
        AppendToLog(chBuf);
    }
    CloseHandle(hChildStd_OUT_Rd);

    WaitForSingleObject(piProcInfo.hProcess, INFINITE);
    DWORD exitCode;
    GetExitCodeProcess(piProcInfo.hProcess, &exitCode);
    CloseHandle(piProcInfo.hProcess);
    CloseHandle(piProcInfo.hThread);

    return exitCode;
}
