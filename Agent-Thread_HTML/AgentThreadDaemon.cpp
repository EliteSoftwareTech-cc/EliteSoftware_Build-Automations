#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

void StartDaemon() {
    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    string exePath = path;
    string dirPath = exePath.substr(0, exePath.find_last_of("\\/"));
    
    string psScript = dirPath + "\\Start-AgentThreadServer.ps1";
    string cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "" + psScript + """;

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;
    ZeroMemory(&pi, sizeof(pi));

    if (CreateProcessA(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, CREATE_NO_WINDOW | DETACHED_PROCESS, NULL, dirPath.c_str(), &si, &pi)) {
        cout << "[AgentThread] Server daemon launched successfully in the background." << endl;
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
    } else {
        cerr << "[AgentThread] Failed to launch server daemon." << endl;
    }
}

int main(int argc, char* argv[]) {
    string cmdLine = GetCommandLineA();
    
    if (cmdLine.find("--start") != string::npos || cmdLine.find("--daemon") != string::npos || argc == 1) {
        StartDaemon();
        return 0;
    }

    char path[MAX_PATH];
    GetModuleFileNameA(NULL, path, MAX_PATH);
    string exePath = path;
    string dirPath = exePath.substr(0, exePath.find_last_of("\\/"));
    string psScript = dirPath + "\\Start-AgentThreadServer.ps1";
    
    string args = "";
    for (int i = 1; i < argc; i++) {
        string arg = argv[i];
        if (arg.find(" ") != string::npos && arg.front() != '"') {
            args += " "" + arg + """;
        } else {
            args += " " + arg;
        }
    }

    string cmd = "powershell.exe -ExecutionPolicy Bypass -File "" + psScript + """ + args;
    
    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (CreateProcessA(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, 0, NULL, dirPath.c_str(), &si, &pi)) {
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return exitCode;
    } else {
        cerr << "[AgentThread] Failed to forward arguments to IPC handler." << endl;
        return 1;
    }
    return 0;
}
