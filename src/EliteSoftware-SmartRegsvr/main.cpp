#include <iostream>
#include <windows.h>
#include <string>

using namespace std;

bool IsAiMode() {
    return strstr(GetCommandLineA(), "--ai-mode") != nullptr;
}

int GetPEArchitecture(const string& path) {
    HANDLE hFile = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return 0;
    HANDLE hMap = CreateFileMappingA(hFile, NULL, PAGE_READONLY, 0, 0, NULL);
    if (!hMap) { CloseHandle(hFile); return 0; }
    LPVOID pBase = MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
    if (!pBase) { CloseHandle(hMap); CloseHandle(hFile); return 0; }

    int arch = 0;
    PIMAGE_DOS_HEADER pDosHeader = (PIMAGE_DOS_HEADER)pBase;
    if (pDosHeader->e_magic == IMAGE_DOS_SIGNATURE) {
        PIMAGE_NT_HEADERS pNtHeaders = (PIMAGE_NT_HEADERS)((BYTE*)pBase + pDosHeader->e_lfanew);
        if (pNtHeaders->Signature == IMAGE_NT_SIGNATURE) {
            if (pNtHeaders->FileHeader.Machine == IMAGE_FILE_MACHINE_I386) arch = 32;
            else if (pNtHeaders->FileHeader.Machine == IMAGE_FILE_MACHINE_AMD64) arch = 64;
        }
    }
    UnmapViewOfFile(pBase); CloseHandle(hMap); CloseHandle(hFile);
    return arch;
}

int main(int argc, char* argv[]) {
    string filePath = "";
    if (argc > 1) {
        for (int i = 1; i < argc; ++i) {
            if (string(argv[i]) == "--file" && i + 1 < argc) filePath = argv[++i];
            else if (string(argv[i]) != "--ai-mode") filePath = argv[i];
        }
    }

    if (filePath.empty() && !IsAiMode()) {
        cout << "Enter the path to the DLL/PE file to register: ";
        getline(cin, filePath);
    }

    if (filePath.empty()) {
        cerr << "File path is required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    // Remove quotes if present
    if(filePath.front() == '"' && filePath.back() == '"') filePath = filePath.substr(1, filePath.length() - 2);

    int arch = GetPEArchitecture(filePath);
    if (arch == 0) {
        cerr << "Could not determine architecture or file is not a valid PE.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    cout << "Detected " << arch << "-bit DLL.\n";
    
    char sysDir[MAX_PATH];
    if (arch == 32) {
        GetSystemWow64DirectoryA(sysDir, MAX_PATH);
    } else {
        GetSystemDirectoryA(sysDir, MAX_PATH);
    }

    string regsvrPath = string(sysDir) + "\\regsvr32.exe";
    string cmd = "\"" + regsvrPath + "\" \"" + filePath + "\"";

    cout << "Executing: " << cmd << "\n";
    system(cmd.c_str());

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
