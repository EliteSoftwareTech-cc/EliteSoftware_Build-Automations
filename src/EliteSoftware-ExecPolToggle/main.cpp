#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-ExecPolToggle", argc, argv);

    string level = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--level" && i + 1 < argc) level = argv[++i];
    }

    if (level.empty() && !IsAiMode()) {
        cout << "Select Execution Policy (Bypass, RemoteSigned, Restricted): ";
        getline(cin, level);
    }

    if (level.empty()) level = "Bypass";

    HKEY hKey;
    LPCSTR subKey = "SOFTWARE\\Microsoft\\PowerShell\\1\\ShellIds\\Microsoft.PowerShell";

    if (RegCreateKeyExA(HKEY_LOCAL_MACHINE, subKey, 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
        RegSetValueExA(hKey, "ExecutionPolicy", 0, REG_SZ, (const BYTE*)level.c_str(), level.length() + 1);
        RegCloseKey(hKey);
        cout << "Successfully set HKLM ExecutionPolicy to " << level << ".\n";
    } else {
        cerr << "Failed to set HKLM ExecutionPolicy. (Run as Administrator)\n";
        // Fallback to CurrentUser
        if (RegCreateKeyExA(HKEY_CURRENT_USER, subKey, 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
            RegSetValueExA(hKey, "ExecutionPolicy", 0, REG_SZ, (const BYTE*)level.c_str(), level.length() + 1);
            RegCloseKey(hKey);
            cout << "Successfully set HKCU ExecutionPolicy to " << level << " as fallback.\n";
        } else {
            cerr << "Failed to set HKCU ExecutionPolicy.\n";
        }
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
