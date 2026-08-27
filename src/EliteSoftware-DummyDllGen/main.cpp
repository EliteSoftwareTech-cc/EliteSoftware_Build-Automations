#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>

using namespace std;
namespace fs = std::filesystem;

bool IsAiMode() { return strstr(GetCommandLineA(), "--ai-mode") != nullptr; }

int main(int argc, char* argv[]) {
    string dllName = "";
    string exportsStr = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--name" && i + 1 < argc) dllName = argv[++i];
        else if (arg == "--exports" && i + 1 < argc) exportsStr = argv[++i];
    }

    if (dllName.empty() && !IsAiMode()) {
        cout << "Enter Output DLL Name (e.g. test.dll): ";
        getline(cin, dllName);
        cout << "Enter comma separated exports (e.g. DllRegisterServer,DllUnregisterServer): ";
        getline(cin, exportsStr);
    }

    if (dllName.empty()) {
        cerr << "DLL Name required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    string cppFile = dllName + "_stub.cpp";
    ofstream out(cppFile);
    if (!out.is_open()) {
        cerr << "Failed to write stub C++ file.\n";
        return 1;
    }

    out << "#include <windows.h>\n\n";
    out << "BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {\n";
    out << "    switch (ul_reason_for_call) {\n";
    out << "    case DLL_PROCESS_ATTACH:\n";
    out << "    case DLL_THREAD_ATTACH:\n";
    out << "    case DLL_THREAD_DETACH:\n";
    out << "    case DLL_PROCESS_DETACH:\n";
    out << "        break;\n";
    out << "    }\n";
    out << "    return TRUE;\n";
    out << "}\n\n";

    size_t pos = 0;
    while ((pos = exportsStr.find(',')) != string::npos) {
        string exp = exportsStr.substr(0, pos);
        if (!exp.empty()) {
            out << "extern \"C\" __declspec(dllexport) HRESULT " << exp << "() { return S_OK; }\n";
        }
        exportsStr.erase(0, pos + 1);
    }
    if (!exportsStr.empty()) {
        out << "extern \"C\" __declspec(dllexport) HRESULT " << exportsStr << "() { return S_OK; }\n";
    }

    out.close();

    string cmd = "g++ -shared -o \"" + dllName + "\" \"" + cppFile + "\" -Wl,--kill-at";
    cout << "Compiling Dummy DLL: " << cmd << "\n";
    
    int ret = system(cmd.c_str());
    if (ret == 0) {
        cout << "Successfully generated dummy DLL at " << dllName << "\n";
        fs::remove(cppFile); // Clean up the stub
    } else {
        cerr << "Compilation failed.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return ret;
}
