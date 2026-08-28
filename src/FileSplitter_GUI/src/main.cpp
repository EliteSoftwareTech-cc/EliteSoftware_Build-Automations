#include "..\..\EliteLogger.h"
/**
 * @file main.cpp
 * @brief Application WinMain entry point for File Splitter GUI.
 * @author EliteSoftwareTech Co.
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <objbase.h>
#include <thread>
#include <chrono>
#include "AppWindow.h"
#include "Logger.h"

#pragma region WinMain Entry Point

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) {
    (void)hPrevInstance;
    (void)lpCmdLine;

    // 1. STA Mode Initialization (Mandatory for WinForms / Win32 clipboard & COM stability)
    HRESULT hrCom = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hrCom)) {
        OleInitialize(NULL);
    }

    // 2. High-DPI Awareness Initialization
    HMODULE hUser32 = GetModuleHandleW(L"user32.dll");
    if (hUser32) {
        typedef BOOL(WINAPI* SetProcessDPIAwareFunc)();
        SetProcessDPIAwareFunc pSetDpiAware = (SetProcessDPIAwareFunc)(void*)GetProcAddress(hUser32, "SetProcessDPIAware");
        if (pSetDpiAware) {
            pSetDpiAware();
        }
    }

    // 3. Visual Styles Invocation & Common Controls 6.0 Initialization
    INITCOMMONCONTROLSEX icex;
    ZeroMemory(&icex, sizeof(icex));
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC  = ICC_WIN95_CLASSES | ICC_STANDARD_CLASSES | ICC_PROGRESS_CLASS | ICC_COOL_CLASSES | ICC_BAR_CLASSES | ICC_LISTVIEW_CLASSES;
    InitCommonControlsEx(&icex);

    // 4. EliteSoftware "Premium Feel" Artificial Sleep Delay (100ms initialization phase)
    std::this_thread::sleep_for(std::chrono::milliseconds(100));

    // 5. Initialize Logger
    FileSplitter::Logger::Initialize();
    FileSplitter::Logger::LogInfo(L"FileSplitter.exe launched. Initializing GUI framework...");

    // 6. Create and Display Main Window
    FileSplitter::AppWindow mainApp;
    if (!mainApp.Create(hInstance, nCmdShow)) {
        MessageBoxW(NULL,
            L"Failed to initialize File Splitter main window architecture.",
            L"EliteSoftware Initialization Fatal Error", MB_OK | MB_ICONERROR);
        CoUninitialize();
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    // 7. Win32 Message Pump
    MSG msg;
    ZeroMemory(&msg, sizeof(msg));
    while (GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    FileSplitter::Logger::LogInfo(L"FileSplitter.exe exiting cleanly. Message loop terminated.");
    CoUninitialize();
    return (int)msg.wParam;
}

#pragma endregion

