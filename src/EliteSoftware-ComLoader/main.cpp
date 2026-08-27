#include <windows.h>
#include <iostream>
#include <string>

using namespace std;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string dllPath = "";
    bool unregister = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--dll" && i + 1 < argc) dllPath = argv[++i];
        else if (arg == "--unregister") unregister = true;
    }

    if (dllPath.empty() && !IsAiMode()) {
        cout << "Enter path to DLL/OCX: ";
        getline(cin, dllPath);
        cout << "Unregister? (y/n): ";
        string unreg; getline(cin, unreg);
        if (unreg == "y" || unreg == "Y") unregister = true;
    }

    if (dllPath.empty()) {
        cerr << "DLL path required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    HMODULE hMod = LoadLibraryExA(dllPath.c_str(), NULL, LOAD_WITH_ALTERED_SEARCH_PATH);
    if (!hMod) {
        cerr << "Failed to load module. Error: " << GetLastError() << "\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    FARPROC pFunc = GetProcAddress(hMod, unregister ? "DllUnregisterServer" : "DllRegisterServer");
    if (!pFunc) {
        cerr << "DLL does not export required registration functions.\n";
        FreeLibrary(hMod);
        if (!IsAiMode()) system("pause");
        return 1;
    }

    HRESULT hr = ((HRESULT(WINAPI*)())pFunc)();
    FreeLibrary(hMod);

    if (SUCCEEDED(hr)) {
        cout << "Successfully " << (unregister ? "unregistered " : "registered ") << dllPath << "\n";
    } else {
        cerr << "Registration function failed with HRESULT: 0x" << hex << hr << dec << "\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return SUCCEEDED(hr) ? 0 : 1;
}
