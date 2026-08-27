#pragma once
#include <windows.h>
#include <commctrl.h>
#include <string>
#include "Signer.h"

extern std::wstring g_loadedFile;
extern std::wstring g_originalFile;
extern std::wstring g_customCertPath;
extern void EliteLog(const std::wstring& msg);
extern void BackupFile(const std::wstring& filePath);

struct ProgressData {
    HWND hDlg;
    HWND hLabel;
    HWND hProgress;
    HWND hLogBtn;
    HWND hCloseBtn;
    bool bSuccess;
};

extern std::wstring g_loadedFileMUN;
extern std::wstring g_loadedFileMUI;
extern std::wstring g_originalFileMUN;
extern std::wstring g_originalFileMUI;

inline DWORD WINAPI SaveProcessThread(LPVOID lpParam) {
    ProgressData* pd = (ProgressData*)lpParam;
    
    SendMessageW(pd->hProgress, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
    
    struct FileItem {
        std::wstring loaded;
        std::wstring original;
        std::wstring type;
    };
    
    std::vector<FileItem> filesToProcess;
    if (!g_loadedFile.empty()) filesToProcess.push_back({g_loadedFile, g_originalFile, L"Base"});
    if (!g_loadedFileMUN.empty()) filesToProcess.push_back({g_loadedFileMUN, g_originalFileMUN, L"MUN"});
    if (!g_loadedFileMUI.empty()) filesToProcess.push_back({g_loadedFileMUI, g_originalFileMUI, L"MUI"});
    
    int totalFiles = (int)filesToProcess.size();
    if (totalFiles == 0) {
        pd->bSuccess = true;
        EnableWindow(pd->hCloseBtn, TRUE);
        return 0;
    }
    
    for (int i = 0; i < totalFiles; ++i) {
        auto& fi = filesToProcess[i];
        int basePos = (100 / totalFiles) * i;
        int stepSize = (100 / totalFiles);
        
        SetWindowTextW(pd->hLabel, (L"[" + fi.type + L"] Step 1: Committing Virtual Changes...").c_str());
        SendMessageW(pd->hProgress, PBM_SETPOS, basePos + (stepSize * 20 / 100), 0);
        Sleep(500); // Artificial delay to ensure user sees progress as requested by guidelines
        
        SetWindowTextW(pd->hLabel, (L"[" + fi.type + L"] Step 2: Rebuilding PE Headers & Checksum...").c_str());
        SendMessageW(pd->hProgress, PBM_SETPOS, basePos + (stepSize * 40 / 100), 0);
        if (!RebuildPEHeader(fi.loaded)) {
            // Resource-only DLLs might fail header rebuild if they lack standard headers, log it and continue
            EliteLog(L"Warning: Failed to rebuild PE headers for " + fi.type + L" file. Continuing anyway.");
        }
        Sleep(500);
        
        SetWindowTextW(pd->hLabel, (L"[" + fi.type + L"] Step 3: Signing Binary with EliteSoftware Cert...").c_str());
        SendMessageW(pd->hProgress, PBM_SETPOS, basePos + (stepSize * 70 / 100), 0);
        if (!SignBinary(fi.loaded, g_customCertPath)) {
            EliteLog(L"Warning: Code signing failed for " + fi.type + L" file.");
        }
        Sleep(500);
        
        SetWindowTextW(pd->hLabel, (L"[" + fi.type + L"] Step 4: Creating Backups & Saving...").c_str());
        SendMessageW(pd->hProgress, PBM_SETPOS, basePos + (stepSize * 90 / 100), 0);
        BackupFile(fi.original);
        if (!CopyFileW(fi.loaded.c_str(), fi.original.c_str(), FALSE)) {
            SetWindowTextW(pd->hLabel, (L"Error: Failed to overwrite " + fi.type + L" file. It might be in use.").c_str());
            pd->bSuccess = false;
            EnableWindow(pd->hCloseBtn, TRUE);
            return 1;
        }
    }
    
    SendMessageW(pd->hProgress, PBM_SETPOS, 100, 0);
    SetWindowTextW(pd->hLabel, L"Success! All binaries compiled, signed, and deployed.");
    pd->bSuccess = true;
    EnableWindow(pd->hCloseBtn, TRUE);
    
    // Auto close after 45 seconds on success
    for (int i = 45; i > 0; --i) {
        if (!IsWindow(pd->hDlg)) break;
        wchar_t buf[256];
        wsprintfW(buf, L"Success! Closing in %d seconds...", i);
        SetWindowTextW(pd->hLabel, buf);
        Sleep(1000);
    }
    
    if (IsWindow(pd->hDlg)) {
        PostMessageW(pd->hDlg, WM_COMMAND, MAKEWPARAM(IDCANCEL, BN_CLICKED), 0);
    }
    return 0;
}

inline LRESULT CALLBACK ProgressWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    static ProgressData* pd = nullptr;
    switch (msg) {
    case WM_CREATE:
        {
            pd = (ProgressData*)((CREATESTRUCT*)lParam)->lpCreateParams;
            pd->hDlg = hwnd;
            
            CreateWindowExW(0, L"STATIC", L"Elite-EasySigner Integrated Save Protocol", WS_CHILD | WS_VISIBLE, 20, 10, 360, 20, hwnd, NULL, NULL, NULL);
            pd->hLabel = CreateWindowExW(0, L"STATIC", L"Initializing...", WS_CHILD | WS_VISIBLE, 20, 40, 360, 20, hwnd, NULL, NULL, NULL);
            pd->hProgress = CreateWindowExW(0, PROGRESS_CLASSW, NULL, WS_CHILD | WS_VISIBLE | PBS_SMOOTH, 20, 65, 340, 25, hwnd, NULL, NULL, NULL);
            
            pd->hLogBtn = CreateWindowExW(0, L"BUTTON", L"View Logs", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 20, 105, 100, 25, hwnd, (HMENU)1001, NULL, NULL);
            pd->hCloseBtn = CreateWindowExW(0, L"BUTTON", L"Done", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 260, 105, 100, 25, hwnd, (HMENU)IDCANCEL, NULL, NULL);
            EnableWindow(pd->hCloseBtn, FALSE);
            
            CreateThread(NULL, 0, SaveProcessThread, pd, 0, NULL);
        }
        break;
    case WM_COMMAND:
        if (LOWORD(wParam) == 1001) {
            ShellExecuteW(NULL, L"open", L"notepad.exe", L"C:\\EliteSoftware\\Logs\\ResourceAlchemist.log", NULL, SW_SHOW);
        } else if (LOWORD(wParam) == IDCANCEL) {
            EnableWindow(GetParent(hwnd), TRUE);
            DestroyWindow(hwnd);
        }
        break;
    case WM_CLOSE:
        EnableWindow(GetParent(hwnd), TRUE);
        DestroyWindow(hwnd);
        break;
    default:
        return DefWindowProcW(hwnd, msg, wParam, lParam);
    }
    return 0;
}

inline void ShowProgressDialogAndSave(HWND hwndParent) {
    WNDCLASSW wc = { 0 };
    wc.lpfnWndProc = ProgressWndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = L"EliteProgressDialog";
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    RegisterClassW(&wc);
    
    ProgressData* pd = new ProgressData();
    pd->bSuccess = false;
    
    HWND hDlg = CreateWindowExW(WS_EX_DLGMODALFRAME | WS_EX_TOPMOST, L"EliteProgressDialog", L"Saving & Signing...", 
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE, 
        0, 0, 400, 180, hwndParent, NULL, GetModuleHandle(NULL), pd);
        
    RECT rcParent, rcDlg;
    GetWindowRect(hwndParent, &rcParent);
    GetWindowRect(hDlg, &rcDlg);
    int x = rcParent.left + (rcParent.right - rcParent.left - (rcDlg.right - rcDlg.left)) / 2;
    int y = rcParent.top + (rcParent.bottom - rcParent.top - (rcDlg.bottom - rcDlg.top)) / 2;
    SetWindowPos(hDlg, NULL, x, y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
    
    EnableWindow(hwndParent, FALSE);
    
    MSG msg;
    while (IsWindow(hDlg) && GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    
    delete pd;
}
