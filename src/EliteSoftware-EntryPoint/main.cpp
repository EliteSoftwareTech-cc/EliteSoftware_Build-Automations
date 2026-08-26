#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <windows.h>
#include <sstream>

using namespace std;

void PrintHelp() {
    cout << "========================================" << endl;
    cout << " EliteBuild EntryPoint (Native C++ Tool)" << endl;
    cout << "========================================" << endl;
    cout << "Usage: EliteBuild.exe [OPTIONS]" << endl;
    cout << "Options:" << endl;
    cout << "  /help, -help, -?    Show this help message." << endl;
    cout << endl;
    cout << "Description:" << endl;
    cout << "  Reads EliteBuild.config, locates global build tools in ELITE_BUILD_X64, and" << endl;
    cout << "  orchestrates the compiler, signer, packager, and publisher." << endl;
}

int ExecuteCommand(const string& cmd) {
    cout << "[EliteBuild] Executing: " << cmd << endl;
    
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcess(NULL, (LPSTR)cmd.c_str(), NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        cerr << "[EliteBuild] ERROR: Failed to execute command. Error code: " << GetLastError() << endl;
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    
    DWORD exitCode;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    
    return exitCode;
}

int main(int argc, char* argv[]) {
    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "/help" || arg == "-help" || arg == "--help" || arg == "-?" || arg == "--?" || arg == "//help") {
            PrintHelp();
            return 0;
        }
    }

    char* globalPath = nullptr;
    size_t len = 0;
    _dupenv_s(&globalPath, &len, "ELITE_BUILD_X64");
    if (!globalPath) {
        cerr << "[EliteBuild] FATAL ERROR: ELITE_BUILD_X64 environment variable not found." << endl;
        cerr << "Please run the EliteSoftware Environment Manager to configure the toolchain." << endl;
        return 1;
    }
    
    string toolchainPath(globalPath);
    free(globalPath);

    string compilerExe = toolchainPath + "\\EliteBuild_Compiler.exe";
    string signerExe = toolchainPath + "\\EliteEasySigner.exe";
    string packagerExe = toolchainPath + "\\EliteBuild_Packager.exe";
    string publisherExe = toolchainPath + "\\EliteGitHubAutomator.exe";

    cout << "========================================" << endl;
    cout << " EliteBuild Master Orchestrator" << endl;
    cout << "========================================" << endl;
    
    // Step 1: Compiler
    if (ExecuteCommand(compilerExe) != 0) {
        cerr << "[EliteBuild] Compilation failed. Aborting." << endl;
        return 1;
    }
    
    // Step 2: Signer
    ExecuteCommand(signerExe); // If it fails, that's okay, maybe no cert or missing targets
    
    // Step 3: Packager
    if (ExecuteCommand(packagerExe) != 0) {
        cerr << "[EliteBuild] Packaging failed. Aborting." << endl;
        return 1;
    }
    
    // Step 4: Publisher
    if (ExecuteCommand(publisherExe + " commit --msg \"Auto-commit via EliteBuild\"") != 0) {
        cerr << "[EliteBuild] Publishing failed." << endl;
        return 1;
    }
    ExecuteCommand(publisherExe + " release --version auto");

    cout << "[EliteBuild] Master Pipeline Completed Successfully!" << endl;
    return 0;
}
