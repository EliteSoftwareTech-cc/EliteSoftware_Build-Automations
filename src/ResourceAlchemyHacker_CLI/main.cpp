#include "..\EliteLogger.h"
#include <windows.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <iomanip>

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

// EliteLog(const wstring&) handled by EliteLogger.h


void LogWin32Error(const wstring& context, DWORD errCode = GetLastError()) {
    wstring witty;
    switch (errCode) {
        case ERROR_ACCESS_DENIED: witty = L"Windows slammed the door in our face. Are you running as Admin, or just pretending?"; break;
        case ERROR_SHARING_VIOLATION: witty = L"The file is currently being held hostage by another process. Kill it and try again."; break;
        case ERROR_FILE_NOT_FOUND: witty = L"File not found. Did it vanish into the void, or did you make a typo?"; break;
        case ERROR_RESOURCE_DATA_NOT_FOUND: witty = L"Resource not found. You're hunting ghosts in this binary."; break;
        case ERROR_NOT_SUPPORTED: witty = L"Windows API blocked the update (Error 50). This usually happens when editing MUI/MUN separated files like imageres.dll. Try targeting the .mun file directly!"; break;
        default: witty = L"A technical anomaly occurred. Blame the gremlins."; break;
    }
    
    wstringstream ss;
    ss << context << L" - Error " << errCode << L": " << witty;
    EliteLog(ss.str());
}

wstring GetResIdOrName(LPCWSTR val) {
    if (IS_INTRESOURCE(val)) {
        return to_wstring((USHORT)(ULONG_PTR)val);
    }
    return wstring(val);
}

struct EnumCtx {
    HMODULE hMod;
    wstring typeName;
    wstring resName;
};

BOOL CALLBACK EnumResLangProc(HMODULE hModule, LPCWSTR lpszType, LPCWSTR lpszName, WORD wIDLanguage, LONG_PTR lParam) {
    EnumCtx* ctx = (EnumCtx*)lParam;
    HRSRC hRes = FindResourceExW(hModule, lpszType, lpszName, wIDLanguage);
    DWORD size = hRes ? SizeofResource(hModule, hRes) : 0;
    
    wcout << L"TYPE:" << ctx->typeName << L" | RES:" << ctx->resName << L" | LANG:" << wIDLanguage << L" | SIZE:" << size << endl << flush;
    return TRUE;
}

BOOL CALLBACK EnumResNameProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    EnumCtx* ctx = (EnumCtx*)lParam;
    ctx->resName = GetResIdOrName(lpszName);
    EnumResourceLanguagesW(hModule, lpszType, lpszName, EnumResLangProc, lParam);
    return TRUE;
}

BOOL CALLBACK EnumResTypeProc(HMODULE hModule, LPWSTR lpszType, LONG_PTR lParam) {
    EnumCtx ctx;
    ctx.hMod = hModule;
    ctx.typeName = GetResIdOrName(lpszType);
    EnumResourceNamesW(hModule, lpszType, EnumResNameProc, (LONG_PTR)&ctx);
    return TRUE;
}

void DoList(const wstring& target) {
    EliteLog(L"Starting enumeration scan on " + target);
    HMODULE hMod = LoadLibraryExW(target.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
    if (!hMod) {
        LogWin32Error(L"Failed to load target for enumeration");
        return;
    }
    EnumResourceTypesW(hMod, EnumResTypeProc, 0);
    FreeLibrary(hMod);
    EliteLog(L"Enumeration completed.");
}

bool ExtractIconGroup(HMODULE hMod, LPCWSTR resName, WORD lang, const wstring& outPath) {
    HRSRC hResGroup = FindResourceExW(hMod, (LPCWSTR)RT_GROUP_ICON, resName, lang);
    if (!hResGroup) return false;
    HGLOBAL hMemGroup = LoadResource(hMod, hResGroup);
    void* pGroup = LockResource(hMemGroup);
    if (!pGroup) return false;

    ICONDIR* pGrpDir = (ICONDIR*)pGroup;
    GRPICONDIRENTRY* pGrpEntries = (GRPICONDIRENTRY*)((BYTE*)pGroup + sizeof(ICONDIR));

    ofstream out(std::filesystem::path(outPath), ios::binary);
    if (!out) return false;

    // Write file header
    out.write((char*)pGrpDir, sizeof(ICONDIR));

    DWORD imageOffset = sizeof(ICONDIR) + (pGrpDir->idCount * sizeof(ICONDIRENTRY));
    vector<void*> iconData(pGrpDir->idCount);
    vector<DWORD> iconSizes(pGrpDir->idCount);

    // Write entries
    for (int i = 0; i < pGrpDir->idCount; ++i) {
        ICONDIRENTRY entry;
        entry.bWidth = pGrpEntries[i].bWidth;
        entry.bHeight = pGrpEntries[i].bHeight;
        entry.bColorCount = pGrpEntries[i].bColorCount;
        entry.bReserved = pGrpEntries[i].bReserved;
        entry.wPlanes = pGrpEntries[i].wPlanes;
        entry.wBitCount = pGrpEntries[i].wBitCount;
        entry.dwBytesInRes = pGrpEntries[i].dwBytesInRes;
        entry.dwImageOffset = imageOffset;

        out.write((char*)&entry, sizeof(ICONDIRENTRY));

        HRSRC hIconRes = FindResourceExW(hMod, (LPCWSTR)RT_ICON, MAKEINTRESOURCEW(pGrpEntries[i].nId), lang);
        HGLOBAL hIconMem = LoadResource(hMod, hIconRes);
        iconData[i] = LockResource(hIconMem);
        iconSizes[i] = SizeofResource(hMod, hIconRes);
        imageOffset += iconSizes[i];
    }

    // Write pixel data
    for (int i = 0; i < pGrpDir->idCount; ++i) {
        if (iconData[i]) {
            out.write((char*)iconData[i], iconSizes[i]);
        }
    }

    out.close();
    return true;
}

void DoExtract(const wstring& target, const wstring& typeStr, const wstring& nameStr, WORD lang, const wstring& outPath) {
    EliteLog(L"Extracting resource " + typeStr + L"/" + nameStr + L" from " + target);
    HMODULE hMod = LoadLibraryExW(target.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
    if (!hMod) {
        LogWin32Error(L"Failed to load target for extraction");
        return;
    }

    LPCWSTR type = typeStr.c_str();
    if (typeStr == L"14" || typeStr.find(L"RT_GROUP_ICON") != wstring::npos) {
        if (ExtractIconGroup(hMod, MAKEINTRESOURCEW(_wtoi(nameStr.c_str())), lang, outPath)) {
            EliteLog(L"Successfully reconstructed and extracted RT_GROUP_ICON to " + outPath);
            FreeLibrary(hMod);
            return;
        }
    }

    if (typeStr.find(L"#") == 0) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str() + 1));
    else if (!typeStr.empty() && typeStr.find_first_not_of(L"0123456789") == std::wstring::npos) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str()));

    LPCWSTR name = nameStr.c_str();
    if (nameStr.find(L"#") == 0) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str() + 1));
    else if (!nameStr.empty() && nameStr.find_first_not_of(L"0123456789") == std::wstring::npos) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str()));

    HRSRC hRes = FindResourceExW(hMod, type, name, lang);
    if (!hRes) {
        LogWin32Error(L"FindResourceExW failed");
        FreeLibrary(hMod);
        return;
    }

    HGLOBAL hMem = LoadResource(hMod, hRes);
    void* pData = LockResource(hMem);
    DWORD dwSize = SizeofResource(hMod, hRes);

    if (pData && dwSize > 0) {
        ofstream out(std::filesystem::path(outPath), ios::binary);
        if (out) {
            out.write((char*)pData, dwSize);
            EliteLog(L"Successfully dumped raw resource to " + outPath);
        } else {
            LogWin32Error(L"Failed to open output file");
        }
    } else {
        LogWin32Error(L"Failed to lock resource data");
    }
    FreeLibrary(hMod);
}

void BackupFile(const wstring& target) {
    wstring base = target;
    size_t extPos = base.find_last_of(L".");
    if (extPos != wstring::npos) base = base.substr(0, extPos);
    
    int index = 1;
    while (true) {
        wstring backupPath = base + L"_" + to_wstring(index) + L".bak";
        if (GetFileAttributesW(backupPath.c_str()) == INVALID_FILE_ATTRIBUTES) {
            if (CopyFileW(target.c_str(), backupPath.c_str(), TRUE)) {
                EliteLog(L"EliteSoftware Safety Backup Protocol: Created " + backupPath);
                return;
            } else {
                LogWin32Error(L"Safety Backup failed on CopyFileW");
                exit(3); // Abort
            }
        }
        index++;
    }
}

struct EnumGroupCtx {
    LPCWSTR targetName;
    WORD lang;
    vector<WORD> oldSubIconIds;
    vector<WORD> otherSubIconIds;
};

BOOL CALLBACK EnumGroupIconsProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    EnumGroupCtx* ctx = (EnumGroupCtx*)lParam;
    HRSRC hResGroup = FindResourceExW(hModule, (LPCWSTR)RT_GROUP_ICON, lpszName, ctx->lang);
    if (!hResGroup) {
        hResGroup = FindResourceW(hModule, lpszName, (LPCWSTR)RT_GROUP_ICON);
    }
    if (hResGroup) {
        HGLOBAL hMem = LoadResource(hModule, hResGroup);
        void* pGroup = LockResource(hMem);
        if (pGroup) {
            ICONDIR* pGrpDir = (ICONDIR*)pGroup;
            GRPICONDIRENTRY* pGrpEntries = (GRPICONDIRENTRY*)((BYTE*)pGroup + sizeof(ICONDIR));
            
            bool isTarget = false;
            if (IS_INTRESOURCE(lpszName) && IS_INTRESOURCE(ctx->targetName)) {
                isTarget = ((USHORT)(ULONG_PTR)lpszName == (USHORT)(ULONG_PTR)ctx->targetName);
            } else if (!IS_INTRESOURCE(lpszName) && !IS_INTRESOURCE(ctx->targetName)) {
                isTarget = (_wcsicmp(lpszName, ctx->targetName) == 0);
            }
            
            for (int i = 0; i < pGrpDir->idCount; ++i) {
                if (isTarget) {
                    ctx->oldSubIconIds.push_back(pGrpEntries[i].nId);
                } else {
                    ctx->otherSubIconIds.push_back(pGrpEntries[i].nId);
                }
            }
        }
    }
    return TRUE;
}

bool ReplaceIconGroup(const wstring& target, LPCWSTR name, WORD lang, const wstring& icoPath) {
    EnumGroupCtx ctx;
    ctx.targetName = name;
    ctx.lang = lang;
    
    HMODULE hMod = LoadLibraryExW(target.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
    if (hMod) {
        EnumResourceNamesW(hMod, (LPCWSTR)RT_GROUP_ICON, EnumGroupIconsProc, (LONG_PTR)&ctx);
        FreeLibrary(hMod);
    }
    
    ifstream icoFile(std::filesystem::path(icoPath), ios::binary);
    if (!icoFile) {
        EliteLog(L"ReplaceIconGroup: Failed to open ICO file " + icoPath);
        return false;
    }
    
    ICONDIR header;
    if (!icoFile.read((char*)&header, sizeof(ICONDIR))) {
        EliteLog(L"ReplaceIconGroup: Failed to read ICO header");
        return false;
    }
    
    if (header.idType != 1) {
        EliteLog(L"ReplaceIconGroup: Invalid ICO type");
        return false;
    }
    
    vector<ICONDIRENTRY> entries(header.idCount);
    if (!icoFile.read((char*)entries.data(), header.idCount * sizeof(ICONDIRENTRY))) {
        EliteLog(L"ReplaceIconGroup: Failed to read ICO entries");
        return false;
    }
    
    vector<vector<char>> iconImages(header.idCount);
    for (int i = 0; i < header.idCount; ++i) {
        icoFile.seekg(entries[i].dwImageOffset, ios::beg);
        iconImages[i].resize(entries[i].dwBytesInRes);
        if (!icoFile.read(iconImages[i].data(), entries[i].dwBytesInRes)) {
            EliteLog(L"ReplaceIconGroup: Failed to read icon image data for entry " + to_wstring(i));
            return false;
        }
    }
    icoFile.close();
    
    vector<WORD> newSubIconIds;
    WORD candidateId = 1;
    for (int i = 0; i < header.idCount; ++i) {
        while (true) {
            bool clash = false;
            for (WORD otherId : ctx.otherSubIconIds) {
                if (otherId == candidateId) {
                    clash = true;
                    break;
                }
            }
            if (!clash) {
                newSubIconIds.push_back(candidateId);
                ctx.otherSubIconIds.push_back(candidateId);
                candidateId++;
                break;
            }
            candidateId++;
        }
    }
    
    HANDLE hUpdate = BeginUpdateResourceW(target.c_str(), FALSE);
    if (!hUpdate) {
        LogWin32Error(L"ReplaceIconGroup: BeginUpdateResourceW failed");
        return false;
    }
    
    for (WORD oldId : ctx.oldSubIconIds) {
        UpdateResourceW(hUpdate, (LPCWSTR)RT_ICON, MAKEINTRESOURCEW(oldId), lang, NULL, 0);
    }
    
    for (int i = 0; i < header.idCount; ++i) {
        WORD newId = newSubIconIds[i];
        if (!UpdateResourceW(hUpdate, (LPCWSTR)RT_ICON, MAKEINTRESOURCEW(newId), lang, iconImages[i].data(), (DWORD)iconImages[i].size())) {
            LogWin32Error(L"ReplaceIconGroup: Failed to write new sub-icon ID " + to_wstring(newId));
            EndUpdateResourceW(hUpdate, TRUE);
            return false;
        }
    }
    
    vector<char> groupDirectoryBuffer(sizeof(ICONDIR) + header.idCount * sizeof(GRPICONDIRENTRY));
    ICONDIR* pOutDir = (ICONDIR*)groupDirectoryBuffer.data();
    pOutDir->idReserved = header.idReserved;
    pOutDir->idType = header.idType;
    pOutDir->idCount = header.idCount;
    
    GRPICONDIRENTRY* pOutEntries = (GRPICONDIRENTRY*)(groupDirectoryBuffer.data() + sizeof(ICONDIR));
    for (int i = 0; i < header.idCount; ++i) {
        pOutEntries[i].bWidth = entries[i].bWidth;
        pOutEntries[i].bHeight = entries[i].bHeight;
        pOutEntries[i].bColorCount = entries[i].bColorCount;
        pOutEntries[i].bReserved = entries[i].bReserved;
        pOutEntries[i].wPlanes = entries[i].wPlanes;
        pOutEntries[i].wBitCount = entries[i].wBitCount;
        pOutEntries[i].dwBytesInRes = entries[i].dwBytesInRes;
        pOutEntries[i].nId = newSubIconIds[i];
    }
    
    if (!UpdateResourceW(hUpdate, (LPCWSTR)RT_GROUP_ICON, name, lang, groupDirectoryBuffer.data(), (DWORD)groupDirectoryBuffer.size())) {
        LogWin32Error(L"ReplaceIconGroup: Failed to write new RT_GROUP_ICON directory");
        EndUpdateResourceW(hUpdate, TRUE);
        return false;
    }
    
    if (!EndUpdateResourceW(hUpdate, FALSE)) {
        LogWin32Error(L"ReplaceIconGroup: EndUpdateResourceW failed to commit changes");
        return false;
    }
    
    EliteLog(L"ReplaceIconGroup: Successfully replaced icon group with " + to_wstring(header.idCount) + L" sub-icons.");
    return true;
}

void DoReplace(const wstring& target, const wstring& typeStr, const wstring& nameStr, WORD lang, const wstring& inPath) {
    EliteLog(L"Replacing resource in " + target);
    BackupFile(target);

    if (typeStr == L"14" || typeStr.find(L"RT_GROUP_ICON") != wstring::npos) {
        LPCWSTR name = nameStr.c_str();
        if (nameStr.find(L"#") == 0) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str() + 1));
        else if (!nameStr.empty() && nameStr.find_first_not_of(L"0123456789") == std::wstring::npos) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str()));
        
        if (ReplaceIconGroup(target, name, lang, inPath)) {
            return;
        } else {
            EliteLog(L"Icon replacement failed. Falling back to default resource replacement.");
        }
    }

    HANDLE hUpdate = BeginUpdateResourceW(target.c_str(), FALSE);
    if (!hUpdate) {
        LogWin32Error(L"BeginUpdateResourceW failed");
        return;
    }

    ifstream in(std::filesystem::path(inPath), ios::binary | ios::ate);
    if (!in) {
        EliteLog(L"Failed to read input file: " + inPath);
        EndUpdateResourceW(hUpdate, TRUE);
        return;
    }
    streamsize size = in.tellg();
    in.seekg(0, ios::beg);
    vector<char> buffer(size);
    in.read(buffer.data(), size);

    LPCWSTR type = typeStr.c_str();
    if (typeStr.find(L"#") == 0) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str() + 1));
    else if (!typeStr.empty() && typeStr.find_first_not_of(L"0123456789") == std::wstring::npos) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str()));

    LPCWSTR name = nameStr.c_str();
    if (nameStr.find(L"#") == 0) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str() + 1));
    else if (!nameStr.empty() && nameStr.find_first_not_of(L"0123456789") == std::wstring::npos) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str()));

    if (!UpdateResourceW(hUpdate, type, name, lang, buffer.data(), (DWORD)size)) {
        LogWin32Error(L"UpdateResourceW failed");
        EndUpdateResourceW(hUpdate, TRUE);
        return;
    }

    if (!EndUpdateResourceW(hUpdate, FALSE)) {
        LogWin32Error(L"EndUpdateResourceW failed to commit changes");
        return;
    }
    EliteLog(L"Successfully replaced resource.");
}

void DoDelete(const wstring& target, const wstring& typeStr, const wstring& nameStr, WORD lang) {
    EliteLog(L"Deleting resource in " + target);
    BackupFile(target);

    HANDLE hUpdate = BeginUpdateResourceW(target.c_str(), FALSE);
    if (!hUpdate) {
        LogWin32Error(L"BeginUpdateResourceW failed");
        return;
    }

    LPCWSTR type = typeStr.c_str();
    if (typeStr.find(L"#") == 0) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str() + 1));
    else if (!typeStr.empty() && typeStr.find_first_not_of(L"0123456789") == std::wstring::npos) type = MAKEINTRESOURCEW(_wtoi(typeStr.c_str()));

    LPCWSTR name = nameStr.c_str();
    if (nameStr.find(L"#") == 0) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str() + 1));
    else if (!nameStr.empty() && nameStr.find_first_not_of(L"0123456789") == std::wstring::npos) name = MAKEINTRESOURCEW(_wtoi(nameStr.c_str()));

    if (!UpdateResourceW(hUpdate, type, name, lang, NULL, 0)) {
        LogWin32Error(L"UpdateResourceW failed to delete");
        EndUpdateResourceW(hUpdate, TRUE);
        return;
    }

    if (!EndUpdateResourceW(hUpdate, FALSE)) {
        LogWin32Error(L"EndUpdateResourceW failed to commit changes");
        return;
    }
    EliteLog(L"Successfully deleted resource.");
}

BOOL CALLBACK FlattenEnumLangProc(HMODULE hMod, LPCWSTR lpszType, LPCWSTR lpszName, WORD wIDLanguage, LONG_PTR lParam) {
    HANDLE hUpdate = (HANDLE)lParam;
    HRSRC hRes = FindResourceExW(hMod, lpszType, lpszName, wIDLanguage);
    if (hRes) {
        HGLOBAL hGlob = LoadResource(hMod, hRes);
        if (hGlob) {
            void* data = LockResource(hGlob);
            DWORD size = SizeofResource(hMod, hRes);
            if (data && size > 0) {
                UpdateResourceW(hUpdate, lpszType, lpszName, wIDLanguage, data, size);
            }
        }
    }
    return TRUE;
}

BOOL CALLBACK FlattenEnumNameProc(HMODULE hMod, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    EnumResourceLanguagesW(hMod, lpszType, lpszName, FlattenEnumLangProc, lParam);
    return TRUE;
}

BOOL CALLBACK FlattenEnumTypeProc(HMODULE hMod, LPWSTR lpszType, LONG_PTR lParam) {
    EnumResourceNamesW(hMod, lpszType, FlattenEnumNameProc, lParam);
    return TRUE;
}

void DoFlatten(const wstring& target_base, const wstring& target_mun, const wstring& target_mui) {
    EliteLog(L"Flattening resources from MUN and MUI into " + target_base);
    HANDLE hUpdate = BeginUpdateResourceW(target_base.c_str(), FALSE);
    if (!hUpdate) {
        LogWin32Error(L"BeginUpdateResourceW failed in DoFlatten");
        return;
    }
    
    auto copyResources = [&](const wstring& src) {
        if (src == L"NONE" || src.empty()) return;
        HMODULE hMod = LoadLibraryExW(src.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
        if (hMod) {
            EnumResourceTypesW(hMod, FlattenEnumTypeProc, (LONG_PTR)hUpdate);
            FreeLibrary(hMod);
        }
    };
    
    copyResources(target_mun);
    copyResources(target_mui);
    
    if (!EndUpdateResourceW(hUpdate, FALSE)) {
        LogWin32Error(L"EndUpdateResourceW failed in DoFlatten");
    } else {
        EliteLog(L"Successfully flattened resources into monolithic binary.");
    }
}

int main(int argc, char* argv[]) {
    EliteInit("ResourceAlchemyHacker_CLI", argc, argv);
    int wargc = 0;
    LPWSTR* wargv = CommandLineToArgvW(GetCommandLineW(), &wargc);
    if (!wargv || wargc < 3) {
        std::cout << "Syntax: ResourceAlchemistCLI.exe [ACTION] [TARGET_EXE] [OPTIONS]\n";
        std::cout << "Actions: /list, /extract, /replace, /delete, /flatten\n";
        if (wargv) LocalFree(wargv);
        return 1;
    }

    wstring action = wargv[1];
    wstring target = wargv[2];

    if (action == L"/list") {
        DoList(target);
    } else if (action == L"/extract" && wargc >= 7) {
        DoExtract(target, wargv[3], wargv[4], (WORD)_wtoi(wargv[5]), wargv[6]);
    } else if ((action == L"/replace" || action == L"/add") && wargc >= 7) {
        DoReplace(target, wargv[3], wargv[4], (WORD)_wtoi(wargv[5]), wargv[6]);
    } else if (action == L"/delete" && wargc >= 6) {
        DoDelete(target, wargv[3], wargv[4], (WORD)_wtoi(wargv[5]));
    } else if (action == L"/flatten" && wargc >= 5) {
        DoFlatten(target, wargv[3], wargv[4]);
    } else {
        EliteLog(L"Invalid arguments provided.");
        LocalFree(wargv);
        return 2;
    }

    LocalFree(wargv);
    return 0;
}


