#pragma once
#include <windows.h>
#include <string>
#include <vector>
#include <imagehlp.h>
#pragma comment(lib, "imagehlp.lib")
#pragma comment(lib, "wintrust.lib")

extern void EliteLog(const std::wstring& msg);

inline bool ExtractResourceToFile(LPCWSTR resName, LPCWSTR resType, const std::wstring& outPath) {
    HMODULE hMod = GetModuleHandle(NULL);
    HRSRC hRes = FindResourceW(hMod, resName, resType);
    if (!hRes) return false;
    HGLOBAL hData = LoadResource(hMod, hRes);
    if (!hData) return false;
    DWORD size = SizeofResource(hMod, hRes);
    void* ptr = LockResource(hData);
    if (!ptr) return false;

    HANDLE hFile = CreateFileW(outPath.c_str(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) return false;
    DWORD written = 0;
    WriteFile(hFile, ptr, size, &written, NULL);
    CloseHandle(hFile);
    return written == size;
}

inline bool RebuildPEHeader(const std::wstring& filePath) {
    HANDLE hFile = CreateFileW(filePath.c_str(), GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (hFile == INVALID_HANDLE_VALUE) {
        EliteLog(L"Signer: Failed to open file for header rebuild: " + filePath);
        return false;
    }

    HANDLE hMap = CreateFileMappingW(hFile, NULL, PAGE_READWRITE, 0, 0, NULL);
    if (!hMap) {
        CloseHandle(hFile);
        return false;
    }

    void* pView = MapViewOfFile(hMap, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if (!pView) {
        CloseHandle(hMap);
        CloseHandle(hFile);
        return false;
    }

    PIMAGE_DOS_HEADER pDos = (PIMAGE_DOS_HEADER)pView;
    if (pDos->e_magic != IMAGE_DOS_SIGNATURE) {
        UnmapViewOfFile(pView);
        CloseHandle(hMap);
        CloseHandle(hFile);
        return false;
    }

    PIMAGE_NT_HEADERS pNt = (PIMAGE_NT_HEADERS)((BYTE*)pView + pDos->e_lfanew);
    if (pNt->Signature != IMAGE_NT_SIGNATURE) {
        UnmapViewOfFile(pView);
        CloseHandle(hMap);
        CloseHandle(hFile);
        return false;
    }

    // Strip Security Directory (Signature)
    if (pNt->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR32_MAGIC) {
        PIMAGE_NT_HEADERS32 pNt32 = (PIMAGE_NT_HEADERS32)pNt;
        pNt32->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY].VirtualAddress = 0;
        pNt32->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY].Size = 0;
        pNt32->OptionalHeader.CheckSum = 0;
    } else if (pNt->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC) {
        PIMAGE_NT_HEADERS64 pNt64 = (PIMAGE_NT_HEADERS64)pNt;
        pNt64->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY].VirtualAddress = 0;
        pNt64->OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_SECURITY].Size = 0;
        pNt64->OptionalHeader.CheckSum = 0;
    }

    DWORD headerSum = 0, checkSum = 0;
    PIMAGE_NT_HEADERS pNtOut = CheckSumMappedFile(pView, GetFileSize(hFile, NULL), &headerSum, &checkSum);
    if (pNtOut) {
        if (pNtOut->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR32_MAGIC) {
            ((PIMAGE_NT_HEADERS32)pNtOut)->OptionalHeader.CheckSum = checkSum;
        } else if (pNtOut->OptionalHeader.Magic == IMAGE_NT_OPTIONAL_HDR64_MAGIC) {
            ((PIMAGE_NT_HEADERS64)pNtOut)->OptionalHeader.CheckSum = checkSum;
        }
    }

    UnmapViewOfFile(pView);
    CloseHandle(hMap);
    CloseHandle(hFile);
    
    EliteLog(L"Signer: Rebuilt headers and stripped existing signatures for: " + filePath);
    return true;
}

inline bool SignBinary(const std::wstring& targetFile, const std::wstring& customCertPath = L"") {
    wchar_t tempPath[MAX_PATH];
    GetTempPathW(MAX_PATH, tempPath);
    
    std::wstring signtoolPath = std::wstring(tempPath) + L"signtool_elite.exe";
    std::wstring pfxPath = std::wstring(tempPath) + L"EliteSoftware_Special.pfx";

    ExtractResourceToFile(L"IDR_SIGNTOOL", (LPCWSTR)RT_RCDATA, signtoolPath);
    
    std::wstring activeCert = pfxPath;
    if (!customCertPath.empty()) {
        activeCert = customCertPath;
    } else {
        ExtractResourceToFile(L"IDR_DEFAULTCERT", (LPCWSTR)RT_RCDATA, pfxPath);
    }

    std::wstring cmd = L"\"" + signtoolPath + L"\" sign /f \"" + activeCert + L"\" /p Minecraft145!! /fd SHA256 /t http://timestamp.digicert.com /v \"" + targetFile + L"\"";

    STARTUPINFOW si = { sizeof(STARTUPINFOW) };
    PROCESS_INFORMATION pi = { 0 };

    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_HIDE;

    if (CreateProcessW(NULL, (LPWSTR)cmd.c_str(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        
        DeleteFileW(signtoolPath.c_str());
        if (customCertPath.empty()) DeleteFileW(pfxPath.c_str());
        
        if (exitCode == 0) {
            EliteLog(L"Signer: Successfully signed binary: " + targetFile);
            return true;
        } else {
            EliteLog(L"Signer: Failed to sign binary. Exit code: " + std::to_wstring(exitCode));
            return false;
        }
    }
    
    return false;
}
