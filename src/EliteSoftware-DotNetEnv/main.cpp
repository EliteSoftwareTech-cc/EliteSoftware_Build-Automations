#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <string>

using namespace std;



void CheckDotNetVersion(HKEY hKey, const char* version) {
    HKEY hSubKey;
    if (RegOpenKeyExA(hKey, version, 0, KEY_READ, &hSubKey) == ERROR_SUCCESS) {
        DWORD install = 0, size = sizeof(install);
        if (RegQueryValueExA(hSubKey, "Install", NULL, NULL, (LPBYTE)&install, &size) == ERROR_SUCCESS) {
            if (install == 1) {
                char sp[256];
                DWORD spSize = sizeof(sp);
                if (RegQueryValueExA(hSubKey, "Version", NULL, NULL, (LPBYTE)sp, &spSize) == ERROR_SUCCESS) {
                    cout << "[FOUND] .NET Framework " << version << " (Version: " << sp << ")\n";
                } else {
                    cout << "[FOUND] .NET Framework " << version << "\n";
                }
            }
        }
        RegCloseKey(hSubKey);
    }
}

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-DotNetEnv", argc, argv);

    cout << "EliteSoftware .NET Environment Analyzer\n";
    cout << "Scanning HKLM for installed Frameworks...\n\n";

    HKEY hKey;
    if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, "SOFTWARE\\Microsoft\\NET Framework Setup\\NDP", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        CheckDotNetVersion(hKey, "v2.0.50727");
        CheckDotNetVersion(hKey, "v3.0");
        CheckDotNetVersion(hKey, "v3.5");
        
        HKEY hV4;
        if (RegOpenKeyExA(hKey, "v4\\Full", 0, KEY_READ, &hV4) == ERROR_SUCCESS) {
            DWORD release = 0, size = sizeof(release);
            if (RegQueryValueExA(hV4, "Release", NULL, NULL, (LPBYTE)&release, &size) == ERROR_SUCCESS) {
                cout << "[FOUND] .NET Framework v4 (Release: " << release << ")\n";
            }
            RegCloseKey(hV4);
        }
        RegCloseKey(hKey);
    } else {
        cerr << "[ERROR] Could not open .NET Framework registry keys.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
