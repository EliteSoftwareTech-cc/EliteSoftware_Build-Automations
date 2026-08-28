#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>

using namespace std;



int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-Win7Enabler", argc, argv);

    cout << "EliteSoftware Win7 ESU Enabler\n";
    cout << "Patching BypassESU variables in the registry...\n";

    HKEY hKey;
    LPCSTR subKey = "SYSTEM\\CurrentControlSet\\Control\\ProductOptions";

    if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, subKey, 0, KEY_WRITE, &hKey) == ERROR_SUCCESS) {
        // Just a dummy simulation of the bypass logic to enable ESU updates
        DWORD val = 1;
        RegSetValueExA(hKey, "BypassESU", 0, REG_DWORD, (const BYTE*)&val, sizeof(val));
        RegCloseKey(hKey);
        cout << "[SUCCESS] Kernel ProductOptions patched.\n";
    } else {
        cerr << "[ERROR] Failed to patch ProductOptions. Are you running as Administrator?\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
