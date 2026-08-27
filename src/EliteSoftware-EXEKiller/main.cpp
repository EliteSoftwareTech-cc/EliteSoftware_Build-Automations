#include <windows.h>
#include <tlhelp32.h>
#include <iostream>
#include <string>
#include <algorithm>

using namespace std;

int main(int argc, char* argv[]) {
    string exeName = "";
    if (argc > 1) {
        exeName = argv[1];
    } else {
        cout << "Enter Filename.exe to kill: ";
        getline(cin, exeName);
    }

    if (exeName.empty()) return 1;
    transform(exeName.begin(), exeName.end(), exeName.begin(), ::tolower);

    HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (hSnap == INVALID_HANDLE_VALUE) return 1;

    PROCESSENTRY32 pe;
    pe.dwSize = sizeof(PROCESSENTRY32);

    bool killedAny = false;
    if (Process32First(hSnap, &pe)) {
        do {
            string procName = pe.szExeFile;
            string procNameLower = procName;
            transform(procNameLower.begin(), procNameLower.end(), procNameLower.begin(), ::tolower);

            if (procNameLower == exeName) {
                HANDLE hProc = OpenProcess(PROCESS_TERMINATE, FALSE, pe.th32ProcessID);
                if (hProc) {
                    if (TerminateProcess(hProc, 1)) {
                        cout << "Killed: " << procName << " (PID: " << pe.th32ProcessID << ")\n";
                        killedAny = true;
                    }
                    CloseHandle(hProc);
                }
            }
        } while (Process32Next(hSnap, &pe));
    }
    CloseHandle(hSnap);

    if (!killedAny) {
        cout << "No process matching '" << exeName << "' was found or could be killed.\n";
    }

    return 0;
}
