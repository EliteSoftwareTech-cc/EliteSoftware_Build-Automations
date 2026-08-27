#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

int main(int argc, char* argv[]) {
    string pidStr = "";
    if (argc > 1) {
        pidStr = argv[1];
    } else {
        cout << "Enter PID to kill: ";
        getline(cin, pidStr);
    }

    if (pidStr.empty()) return 1;

    DWORD pid = (DWORD)stoul(pidStr);
    HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, pid);
    if (hProcess) {
        if (TerminateProcess(hProcess, 1)) {
            cout << "Successfully killed PID: " << pid << "\n";
        } else {
            cerr << "Failed to terminate PID: " << pid << "\n";
        }
        CloseHandle(hProcess);
    } else {
        cerr << "Could not open PID: " << pid << "\n";
    }

    return 0;
}
