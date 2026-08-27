#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string name = "";
    string display = "";
    string binPath = "";
    bool remove = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--name" && i + 1 < argc) name = argv[++i];
        else if (arg == "--display" && i + 1 < argc) display = argv[++i];
        else if (arg == "--bin" && i + 1 < argc) binPath = argv[++i];
        else if (arg == "--remove") remove = true;
    }

    if (name.empty() && !IsAiMode()) {
        cout << "Enter Service Name (e.g. EliteAppSvc): ";
        getline(cin, name);
        cout << "Remove this service? (y/n): ";
        string r; getline(cin, r);
        if (r == "y" || r == "Y") {
            remove = true;
        } else {
            cout << "Enter Display Name: ";
            getline(cin, display);
            cout << "Enter Binary Path: ";
            getline(cin, binPath);
        }
    }

    if (name.empty()) {
        cerr << "Service name required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    SC_HANDLE hSCM = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
    if (!hSCM) {
        cerr << "Failed to open Service Control Manager. (Run as Administrator)\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    bool success = false;
    if (remove) {
        SC_HANDLE hService = OpenServiceA(hSCM, name.c_str(), DELETE);
        if (hService) {
            if (DeleteService(hService)) {
                cout << "Successfully deleted service: " << name << "\n";
                success = true;
            } else {
                cerr << "Failed to delete service. Error: " << GetLastError() << "\n";
            }
            CloseServiceHandle(hService);
        } else {
            cerr << "Failed to open service for deletion. Error: " << GetLastError() << "\n";
        }
    } else {
        if (display.empty()) display = name;
        if (binPath.empty()) {
            cerr << "Binary path required for creation.\n";
            CloseServiceHandle(hSCM);
            if (!IsAiMode()) system("pause");
            return 1;
        }

        SC_HANDLE hService = CreateServiceA(
            hSCM, name.c_str(), display.c_str(),
            SERVICE_ALL_ACCESS, SERVICE_WIN32_OWN_PROCESS,
            SERVICE_AUTO_START, SERVICE_ERROR_NORMAL,
            binPath.c_str(), NULL, NULL, NULL, NULL, NULL);

        if (hService) {
            cout << "Successfully created service: " << name << "\n";
            success = true;
            CloseServiceHandle(hService);
        } else {
            cerr << "Failed to create service. Error: " << GetLastError() << "\n";
        }
    }

    CloseServiceHandle(hSCM);

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return success ? 0 : 1;
}
