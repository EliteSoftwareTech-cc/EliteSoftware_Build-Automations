#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-EnvManager", argc, argv);

    string varName = "";
    string varValue = "";
    string action = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--var" && i + 1 < argc) varName = argv[++i];
        else if (arg == "--set" && i + 1 < argc) { varValue = argv[++i]; action = "set"; }
        else if (arg == "--append" && i + 1 < argc) { varValue = argv[++i]; action = "append"; }
        else if (arg == "--remove") { action = "remove"; }
    }

    if (varName.empty() && !IsAiMode()) {
        cout << "Enter Environment Variable Name (e.g. ELITE_BUILD_X64): ";
        getline(cin, varName);
        cout << "Enter Action (set, append, remove): ";
        getline(cin, action);
        if (action != "remove") {
            cout << "Enter Value: ";
            getline(cin, varValue);
        }
    }

    if (varName.empty() || action.empty()) {
        cerr << "Missing required arguments.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    HKEY hKey;
    if (RegOpenKeyExA(HKEY_CURRENT_USER, "Environment", 0, KEY_READ | KEY_WRITE, &hKey) == ERROR_SUCCESS) {
        if (action == "remove") {
            RegDeleteValueA(hKey, varName.c_str());
            cout << "Removed variable: " << varName << "\n";
        } else if (action == "set") {
            RegSetValueExA(hKey, varName.c_str(), 0, REG_SZ, (const BYTE*)varValue.c_str(), varValue.length() + 1);
            cout << "Set variable: " << varName << " = " << varValue << "\n";
        } else if (action == "append") {
            char buffer[4096] = {0};
            DWORD bufSize = sizeof(buffer);
            if (RegQueryValueExA(hKey, varName.c_str(), NULL, NULL, (LPBYTE)buffer, &bufSize) == ERROR_SUCCESS) {
                string current = buffer;
                if (!current.empty() && current.back() != ';') current += ";";
                current += varValue;
                RegSetValueExA(hKey, varName.c_str(), 0, REG_SZ, (const BYTE*)current.c_str(), current.length() + 1);
                cout << "Appended to variable: " << varName << "\n";
            } else {
                RegSetValueExA(hKey, varName.c_str(), 0, REG_SZ, (const BYTE*)varValue.c_str(), varValue.length() + 1);
                cout << "Created and set variable: " << varName << " = " << varValue << "\n";
            }
        }
        RegCloseKey(hKey);
        
        // Broadcast WM_SETTINGCHANGE to notify explorer
        SendMessageTimeoutA(HWND_BROADCAST, WM_SETTINGCHANGE, 0, (LPARAM)"Environment", SMTO_ABORTIFHUNG, 5000, NULL);
    } else {
        cerr << "Failed to open Environment registry key.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
