#include "..\EliteLogger.h"
#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>
#include <vector>
#include <algorithm>

using namespace std;



void KillProcessByName(const string& processName) {
    HANDLE hSnapShot = CreateToolhelp32Snapshot(TH32CS_SNAPALL, NULL);
    PROCESSENTRY32 pEntry;
    pEntry.dwSize = sizeof(pEntry);
    BOOL hRes = Process32First(hSnapShot, &pEntry);

    string targetName = processName;
    transform(targetName.begin(), targetName.end(), targetName.begin(), ::tolower);

    while (hRes) {
        string exeFile = pEntry.szExeFile;
        transform(exeFile.begin(), exeFile.end(), exeFile.begin(), ::tolower);

        if (exeFile == targetName) {
            HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, 0, pEntry.th32ProcessID);
            if (hProcess != NULL) {
                TerminateProcess(hProcess, 9);
                CloseHandle(hProcess);
                cout << "Terminated process: " << pEntry.szExeFile << " (PID: " << pEntry.th32ProcessID << ")\n";
            } else {
                cerr << "Failed to terminate: " << pEntry.szExeFile << " (Access Denied)\n";
            }
        }
        hRes = Process32Next(hSnapShot, &pEntry);
    }
    CloseHandle(hSnapShot);
}

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-TaskAssassin", argc, argv);

    string targetsStr = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--targets" && i + 1 < argc) targetsStr = argv[++i];
    }

    if (targetsStr.empty() && !IsAiMode()) {
        cout << "Enter target executables to kill (semicolon delimited, e.g. notepad.exe;calc.exe): ";
        getline(cin, targetsStr);
    }

    if (targetsStr.empty()) {
        cerr << "Target executables string required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    size_t pos = 0;
    while ((pos = targetsStr.find(';')) != string::npos) {
        string target = targetsStr.substr(0, pos);
        if (!target.empty()) KillProcessByName(target);
        targetsStr.erase(0, pos + 1);
    }
    if (!targetsStr.empty()) KillProcessByName(targetsStr);

    cout << "\nTask Assassin execution complete.\n";

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
