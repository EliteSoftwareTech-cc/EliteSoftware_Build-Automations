#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <fstream>
#include <vector>
#include <imagehlp.h>
#include <string>

#pragma pack(push, 1)
struct ICONDIR {
    WORD idReserved;
    WORD idType;
    WORD idCount;
};
struct ICONDIRENTRY {
    BYTE bWidth;
    BYTE bHeight;
    BYTE bColorCount;
    BYTE bReserved;
    WORD wPlanes;
    WORD wBitCount;
    DWORD dwBytesInRes;
    DWORD dwImageOffset;
};
struct GRPICONDIRENTRY {
    BYTE bWidth;
    BYTE bHeight;
    BYTE bColorCount;
    BYTE bReserved;
    WORD wPlanes;
    WORD wBitCount;
    DWORD dwBytesInRes;
    WORD nId;
};
#pragma pack(pop)

using namespace std;



bool RebaseChecksum(const string& exePath) {
    DWORD headerSum, checkSum;
    if (MapFileAndCheckSumA(exePath.c_str(), &headerSum, &checkSum) != CHECKSUM_SUCCESS) {
        cerr << "Failed to calculate checksum for " << exePath << "\n";
        return false;
    }

    HANDLE hFile = CreateFileA(exePath.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return false;

    HANDLE hMap = CreateFileMappingA(hFile, NULL, PAGE_READWRITE, 0, 0, NULL);
    if (!hMap) { CloseHandle(hFile); return false; }

    LPVOID pBase = MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if (!pBase) { CloseHandle(hMap); CloseHandle(hFile); return false; }

    PIMAGE_DOS_HEADER pDosHeader = (PIMAGE_DOS_HEADER)pBase;
    PIMAGE_NT_HEADERS pNtHeaders = (PIMAGE_NT_HEADERS)((BYTE*)pBase + pDosHeader->e_lfanew);
    
    // Update the checksum
    pNtHeaders->OptionalHeader.CheckSum = checkSum;

    UnmapViewOfFile(pBase);
    CloseHandle(hMap);
    CloseHandle(hFile);

    cout << "PE Checksum successfully rebased to: 0x" << hex << checkSum << dec << "\n";
    return true;
}

int main(int argc, char* argv[]) {
    EliteInit("EliteSoftware-IconReplacer", argc, argv);

    string exePath = "";
    string iconPath = "";

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--exe" && i + 1 < argc) exePath = argv[++i];
        else if (arg == "--icon" && i + 1 < argc) iconPath = argv[++i];
    }

    if (exePath.empty() && !IsAiMode()) {
        cout << "Enter target EXE path: ";
        getline(cin, exePath);
    }
    if (iconPath.empty() && !IsAiMode()) {
        cout << "Enter source ICO path: ";
        getline(cin, iconPath);
    }

    if (exePath.empty() || iconPath.empty()) {
        cerr << "EXE and ICO paths are required.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    ifstream file(iconPath, ios::binary | ios::ate);
    if (!file.is_open()) {
        cerr << "Failed to open icon file.\n";
        if (!IsAiMode()) system("pause");
        return 1;
    }

    streamsize size = file.tellg();
    file.seekg(0, ios::beg);
    vector<BYTE> iconData(size);
    if (!file.read((char*)iconData.data(), size)) {
        cerr << "Failed to read icon file.\n";
        return 1;
    }

    ICONDIR* pIconDir = (ICONDIR*)iconData.data();
    if (pIconDir->idReserved != 0 || pIconDir->idType != 1) {
        cerr << "Invalid ICO file.\n";
        return 1;
    }

    HANDLE hUpdate = BeginUpdateResourceA(exePath.c_str(), FALSE);
    if (!hUpdate) {
        cerr << "Failed to open EXE for resource update.\n";
        return 1;
    }

    int groupSize = sizeof(ICONDIR) + (pIconDir->idCount * sizeof(GRPICONDIRENTRY));
    vector<BYTE> groupData(groupSize);
    memcpy(groupData.data(), pIconDir, sizeof(ICONDIR));

    ICONDIRENTRY* pEntries = (ICONDIRENTRY*)(iconData.data() + sizeof(ICONDIR));
    GRPICONDIRENTRY* pGrpEntries = (GRPICONDIRENTRY*)(groupData.data() + sizeof(ICONDIR));

    for (int i = 0; i < pIconDir->idCount; ++i) {
        pGrpEntries[i].bWidth = pEntries[i].bWidth;
        pGrpEntries[i].bHeight = pEntries[i].bHeight;
        pGrpEntries[i].bColorCount = pEntries[i].bColorCount;
        pGrpEntries[i].bReserved = pEntries[i].bReserved;
        pGrpEntries[i].wPlanes = pEntries[i].wPlanes;
        pGrpEntries[i].wBitCount = pEntries[i].wBitCount;
        pGrpEntries[i].dwBytesInRes = pEntries[i].dwBytesInRes;
        pGrpEntries[i].nId = i + 1; // ID starts at 1

        BYTE* pImage = iconData.data() + pEntries[i].dwImageOffset;
        UpdateResourceA(hUpdate, RT_ICON, MAKEINTRESOURCEA(i + 1), MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL), pImage, pEntries[i].dwBytesInRes);
    }

    UpdateResourceA(hUpdate, RT_GROUP_ICON, MAKEINTRESOURCEA(1), MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL), groupData.data(), groupSize);

    if (!EndUpdateResourceA(hUpdate, FALSE)) {
        cerr << "Failed to save resource update.\n";
        return 1;
    }

    cout << "Icon successfully injected!\n";
    cout << "Rebuilding PE Checksum...\n";
    
    if (!RebaseChecksum(exePath)) {
        cerr << "Warning: Failed to rebase checksum. Signing might fail.\n";
    }

    if (!IsAiMode()) {
        cout << "\nPress any key to exit...\n";
        system("pause");
    }
    return 0;
}
