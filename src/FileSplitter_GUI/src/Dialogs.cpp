/**
 * @file Dialogs.cpp
 * @brief Custom Win32 dialogs implementation adhering to EliteSoftware guidelines.
 * @author EliteSoftwareTech Co.
 */

#include "Dialogs.h"
#include "Resource.h"
#include "Logger.h"

#pragma region Custom Dialog Procedures & Utilities

namespace FileSplitter {

static const wchar_t* ABOUT_CLASS_NAME    = L"EliteFileSplitterAboutClass";
static const wchar_t* HELP_CLASS_NAME     = L"EliteFileSplitterHelpClass";
static const wchar_t* SETTINGS_CLASS_NAME = L"EliteFileSplitterSettingsClass";

static HFONT s_hFontTitle = NULL;
static HFONT s_hFontSub   = NULL;
static HFONT s_hFontBody  = NULL;

static void EnsureFontsCreated() {
    if (!s_hFontTitle) {
        s_hFontTitle = CreateFontW(-15, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    }
    if (!s_hFontSub) {
        s_hFontSub = CreateFontW(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    }
    if (!s_hFontBody) {
        s_hFontBody = CreateFontW(-13, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
            CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    }
}

// -----------------------------------------------------------------------------
// ABOUT DIALOG PROCEDURE
// -----------------------------------------------------------------------------
struct AboutData {
    bool isExpanded = false;
    HWND hBtnExpand = NULL;
    HWND hDetailsTxt = NULL;
};

LRESULT CALLBACK AboutWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    AboutData* pData = (AboutData*)GetWindowLongPtrW(hWnd, GWLP_USERDATA);

    switch (uMsg) {
    case WM_CREATE: {
        pData = new AboutData();
        SetWindowLongPtrW(hWnd, GWLP_USERDATA, (LONG_PTR)pData);
        EnsureFontsCreated();

        // Expander Button
        pData->hBtnExpand = CreateWindowExW(0, L"BUTTON", L"More Details >>",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            16, 155, 130, 26, hWnd, (HMENU)(INT_PTR)IDC_ABOUT_BTN_EXPAND,
            ((LPCREATESTRUCT)lParam)->hInstance, NULL);
        SendMessageW(pData->hBtnExpand, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Details Text Edit Box (Initially Hidden)
        std::wstring detailsText =
            L"Target Framework: Native Win32 / C++17 (MinGW-w64 g++)\r\n"
            L"Minimum OS Target: Windows Vista / Windows 7 / Windows 10 / 11\r\n"
            L"Process Architecture: x64 Desktop\r\n"
            L"Build Version: 1.2.0.0 (Four Place Values)\r\n"
            L"Build Timestamp: " __DATE__ L" " __TIME__ L"\r\n"
            L"System Drive Log Path: %SystemDrive%\\EliteSoftware\\Logs\\FileSplitter.log\r\n\r\n"
            L"Copyright (C) 2026 EliteSoftwareTech Co. All Rights Reserved.";

        pData->hDetailsTxt = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", detailsText.c_str(),
            WS_CHILD | ES_MULTILINE | ES_READONLY | WS_VSCROLL,
            16, 190, 472, 140, hWnd, (HMENU)(INT_PTR)IDC_ABOUT_DETAILS_TXT,
            ((LPCREATESTRUCT)lParam)->hInstance, NULL);
        SendMessageW(pData->hDetailsTxt, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);
        ShowWindow(pData->hDetailsTxt, SW_HIDE);

        // Okay Button in Chin
        HWND hBtnOkay = CreateWindowExW(0, L"BUTTON", L"Okay",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
            398, 218, 90, 26, hWnd, (HMENU)(INT_PTR)IDC_ABOUT_BTN_OKAY,
            ((LPCREATESTRUCT)lParam)->hInstance, NULL);
        SendMessageW(hBtnOkay, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);
        SetFocus(hBtnOkay);
        return 0;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        RECT rcClient;
        GetClientRect(hWnd, &rcClient);

        // 1. Draw Title Banner (Height: 56px)
        RECT rcBanner = { 0, 0, rcClient.right, 56 };
        FillRect(hdc, &rcBanner, (HBRUSH)(COLOR_WINDOW + 1));
        
        // Etched line under banner
        RECT rcBannerLine = { 0, 55, rcClient.right, 56 };
        DrawEdge(hdc, &rcBannerLine, EDGE_ETCHED, BF_BOTTOM);

        // Draw Information Icon (IDI_INFORMATION)
        HICON hInfoIcon = LoadIconW(NULL, MAKEINTRESOURCEW(32516));
        if (hInfoIcon) {
            DrawIconEx(hdc, 16, 12, hInfoIcon, 32, 32, 0, NULL, DI_NORMAL);
        }

        // Banner Title & Subtitle text
        SetBkMode(hdc, TRANSPARENT);
        SelectObject(hdc, s_hFontTitle);
        SetTextColor(hdc, RGB(20, 20, 20));
        RECT rcTitle = { 60, 10, rcClient.right - 10, 30 };
        DrawTextW(hdc, L"About File Splitter For AI Upload", -1, &rcTitle, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        SelectObject(hdc, s_hFontSub);
        SetTextColor(hdc, RGB(80, 80, 80));
        RECT rcSub = { 60, 30, rcClient.right - 10, 48 };
        DrawTextW(hdc, L"EliteSoftwareTech Co. AI Utility Suite v1.2.0.0", -1, &rcSub, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        // 2. Draw Body Information (y: 65 to 150)
        SelectObject(hdc, s_hFontTitle);
        SetTextColor(hdc, RGB(0, 51, 153)); // Elite Navy
        RECT rcAppName = { 16, 68, rcClient.right - 16, 88 };
        DrawTextW(hdc, L"File Splitter For AI Upload", -1, &rcAppName, DT_SINGLELINE | DT_LEFT);

        SelectObject(hdc, s_hFontBody);
        SetTextColor(hdc, RGB(40, 40, 40));
        RECT rcBody1 = { 16, 92, rcClient.right - 16, 110 };
        DrawTextW(hdc, L"Version: 1.2.0.0  |  Target Framework: Win32 / WinForms / Native", -1, &rcBody1, DT_SINGLELINE | DT_LEFT);

        RECT rcBody2 = { 16, 110, rcClient.right - 16, 128 };
        DrawTextW(hdc, L"Authors: Zachary Whiteman, Susan Gemm, TheShadyRainbow4", -1, &rcBody2, DT_SINGLELINE | DT_LEFT);

        RECT rcBody3 = { 16, 128, rcClient.right - 16, 146 };
        DrawTextW(hdc, L"Company: EliteSoftware / EliteSoftwareTech Co.", -1, &rcBody3, DT_SINGLELINE | DT_LEFT);

        // 3. Draw Chin Area (Height: 48px at bottom)
        int chinTop = rcClient.bottom - 48;
        RECT rcChin = { 0, chinTop, rcClient.right, rcClient.bottom };
        HBRUSH hChinBrush = CreateSolidBrush(RGB(224, 224, 224));
        FillRect(hdc, &rcChin, hChinBrush);
        DeleteObject(hChinBrush);

        RECT rcChinLine = { 0, chinTop, rcClient.right, chinTop + 1 };
        DrawEdge(hdc, &rcChinLine, EDGE_ETCHED, BF_TOP);

        EndPaint(hWnd, &ps);
        return 0;
    }

    case WM_CTLCOLORSTATIC: {
        HDC hdcStatic = (HDC)wParam;
        HWND hCtrl = (HWND)lParam;
        RECT rcCtrl, rcWindow;
        GetWindowRect(hCtrl, &rcCtrl);
        GetWindowRect(hWnd, &rcWindow);
        int ctrlRelY = rcCtrl.top - rcWindow.top;
        RECT rcClient;
        GetClientRect(hWnd, &rcClient);
        
        if (ctrlRelY >= rcClient.bottom - 48) {
            SetBkColor(hdcStatic, RGB(224, 224, 224));
            SetTextColor(hdcStatic, RGB(20, 20, 20));
            static HBRUSH hBrushChinStatic = CreateSolidBrush(RGB(224, 224, 224));
            return (INT_PTR)hBrushChinStatic;
        }
        SetBkMode(hdcStatic, TRANSPARENT);
        return (INT_PTR)GetStockObject(NULL_BRUSH);
    }

    case WM_COMMAND: {
        WORD wId = LOWORD(wParam);
        if (wId == IDC_ABOUT_BTN_OKAY || wId == IDCANCEL) {
            DestroyWindow(hWnd);
            return 0;
        }
        if (wId == IDC_ABOUT_BTN_EXPAND && pData) {
            pData->isExpanded = !pData->isExpanded;

            HWND hBtnOkay = GetDlgItem(hWnd, IDC_ABOUT_BTN_OKAY);

            if (pData->isExpanded) {
                SetWindowTextW(pData->hBtnExpand, L"<< Less Details");
                ShowWindow(pData->hDetailsTxt, SW_SHOW);
                SetWindowPos(hWnd, NULL, 0, 0, 520, 440, SWP_NOMOVE | SWP_NOZORDER);
                if (hBtnOkay) SetWindowPos(hBtnOkay, NULL, 398, 398, 90, 26, SWP_NOZORDER);
            } else {
                SetWindowTextW(pData->hBtnExpand, L"More Details >>");
                ShowWindow(pData->hDetailsTxt, SW_HIDE);
                SetWindowPos(hWnd, NULL, 0, 0, 520, 260, SWP_NOMOVE | SWP_NOZORDER);
                if (hBtnOkay) SetWindowPos(hBtnOkay, NULL, 398, 218, 90, 26, SWP_NOZORDER);
            }
            InvalidateRect(hWnd, NULL, TRUE);
            return 0;
        }
        break;
    }

    case WM_DESTROY: {
        if (pData) {
            delete pData;
            SetWindowLongPtrW(hWnd, GWLP_USERDATA, 0);
        }
        return 0;
    }
    }
    return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

// -----------------------------------------------------------------------------
// HELP DIALOG PROCEDURE
// -----------------------------------------------------------------------------
LRESULT CALLBACK HelpWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_CREATE: {
        EnsureFontsCreated();

        // Read-only Multiline Edit Box
        std::wstring helpText =
            L"FILE SPLITTER FOR AI UPLOAD - OPERATIONAL USER GUIDE\r\n"
            L"================================================================================\r\n\r\n"
            L"1. OVERVIEW:\r\n"
            L"   File Splitter slices large text files into smaller chunk files suitable for AI model\r\n"
            L"   context windows. Each output chunk is saved as a .txt file inside a subfolder named\r\n"
            L"   after the original file.\r\n\r\n"
            L"2. SINGLE FILE PROCESSING:\r\n"
            L"   - Click 'Browse...' or drag & drop a file into the target file box.\r\n"
            L"   - Select 'Split by Character Count' or 'Split by Line Count'.\r\n"
            L"   - Enter the maximum limit per chunk file (e.g. 3000 characters or 1000 lines).\r\n"
            L"   - Click 'Okay' to initiate splitting immediately.\r\n\r\n"
            L"3. BATCH PROCESSING:\r\n"
            L"   - Click 'Add Files...' or drag multiple files into the batch file queue.\r\n"
            L"   - Queued files will be processed sequentially according to the active split mode.\r\n"
            L"   - Click 'Clear Queue' or 'Remove Selected' to manage the queue.\r\n\r\n"
            L"4. LOGGING & DIAGNOSTICS:\r\n"
            L"   - Log events append automatically to %SystemDrive%\\EliteSoftware\\Logs\\FileSplitter.log.\r\n"
            L"   - Click 'View FileSplitter Logs' or select Tools -> View Log File to open in Notepad.\r\n\r\n"
            L"5. GUIDELINE COMPLIANCE:\r\n"
            L"   - Built strictly adhering to EliteSoftwareTech Co. GUI Guidelines v1.2.0.0.\r\n"
            L"   - Segoe UI fonts, 3D client edge, darker chin, and native Windows visual styles.";

        HWND hHelpTxt = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", helpText.c_str(),
            WS_CHILD | WS_VISIBLE | ES_MULTILINE | ES_READONLY | WS_VSCROLL,
            16, 68, 512, 310, hWnd, (HMENU)(INT_PTR)IDC_HELP_CONTENT_TXT,
            ((LPCREATESTRUCT)lParam)->hInstance, NULL);
        SendMessageW(hHelpTxt, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Chin Button: "Done"
        HWND hBtnDone = CreateWindowExW(0, L"BUTTON", L"Done",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
            438, 398, 90, 26, hWnd, (HMENU)(INT_PTR)IDC_HELP_BTN_DONE,
            ((LPCREATESTRUCT)lParam)->hInstance, NULL);
        SendMessageW(hBtnDone, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);
        SetFocus(hBtnDone);
        return 0;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        RECT rcClient;
        GetClientRect(hWnd, &rcClient);

        // Title Banner (Height: 56px)
        RECT rcBanner = { 0, 0, rcClient.right, 56 };
        FillRect(hdc, &rcBanner, (HBRUSH)(COLOR_WINDOW + 1));

        RECT rcBannerLine = { 0, 55, rcClient.right, 56 };
        DrawEdge(hdc, &rcBannerLine, EDGE_ETCHED, BF_BOTTOM);

        // Question Icon (IDI_QUESTION = 32514)
        HICON hHelpIcon = LoadIconW(NULL, MAKEINTRESOURCEW(32514));
        if (hHelpIcon) {
            DrawIconEx(hdc, 16, 12, hHelpIcon, 32, 32, 0, NULL, DI_NORMAL);
        }

        SetBkMode(hdc, TRANSPARENT);
        SelectObject(hdc, s_hFontTitle);
        SetTextColor(hdc, RGB(20, 20, 20));
        RECT rcTitle = { 60, 10, rcClient.right - 10, 30 };
        DrawTextW(hdc, L"File Splitter Help & Operational Guide", -1, &rcTitle, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        SelectObject(hdc, s_hFontSub);
        SetTextColor(hdc, RGB(80, 80, 80));
        RECT rcSub = { 60, 30, rcClient.right - 10, 48 };
        DrawTextW(hdc, L"User guidance and operational instructions for EliteSoftware tools.", -1, &rcSub, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        // Darker Chin Area (Height: 48px at bottom)
        int chinTop = rcClient.bottom - 48;
        RECT rcChin = { 0, chinTop, rcClient.right, rcClient.bottom };
        HBRUSH hChinBrush = CreateSolidBrush(RGB(224, 224, 224));
        FillRect(hdc, &rcChin, hChinBrush);
        DeleteObject(hChinBrush);

        RECT rcChinLine = { 0, chinTop, rcClient.right, chinTop + 1 };
        DrawEdge(hdc, &rcChinLine, EDGE_ETCHED, BF_TOP);

        EndPaint(hWnd, &ps);
        return 0;
    }

    case WM_COMMAND: {
        WORD wId = LOWORD(wParam);
        if (wId == IDC_HELP_BTN_DONE || wId == IDCANCEL) {
            DestroyWindow(hWnd);
            return 0;
        }
        break;
    }
    }
    return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

// -----------------------------------------------------------------------------
// SETTINGS DIALOG PROCEDURE
// -----------------------------------------------------------------------------
struct SettingsDialogContext {
    AppSettings currentSettings;
    AppSettings* pOutSettings = nullptr;
    bool isApplied = false;
};

LRESULT CALLBACK SettingsWndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    SettingsDialogContext* pCtx = (SettingsDialogContext*)GetWindowLongPtrW(hWnd, GWLP_USERDATA);

    switch (uMsg) {
    case WM_CREATE: {
        CREATESTRUCT* pcs = (CREATESTRUCT*)lParam;
        pCtx = (SettingsDialogContext*)pcs->lpCreateParams;
        SetWindowLongPtrW(hWnd, GWLP_USERDATA, (LONG_PTR)pCtx);
        EnsureFontsCreated();

        HINSTANCE hInst = pcs->hInstance;

        // Group Box 1: Default Splitting Options
        HWND hGrp1 = CreateWindowExW(0, L"BUTTON", L"Default Splitting Parameters",
            WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
            16, 68, 428, 125, hWnd, NULL, hInst, NULL);
        SendMessageW(hGrp1, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Radio: Split by Characters
        HWND hRadChars = CreateWindowExW(0, L"BUTTON", L"Default Split by Character Count",
            WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON | WS_GROUP,
            28, 92, 240, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_RAD_CHARS, hInst, NULL);
        SendMessageW(hRadChars, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Edit: Char Limit
        HWND hTxtCharLimit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT",
            std::to_wstring(pCtx->currentSettings.defaultCharLimit).c_str(),
            WS_CHILD | WS_VISIBLE | ES_NUMBER,
            280, 92, 145, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_TXT_CHARLIMIT, hInst, NULL);
        SendMessageW(hTxtCharLimit, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Radio: Split by Lines
        HWND hRadLines = CreateWindowExW(0, L"BUTTON", L"Default Split by Line Count",
            WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON,
            28, 122, 240, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_RAD_LINES, hInst, NULL);
        SendMessageW(hRadLines, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Edit: Line Limit
        HWND hTxtLineLimit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT",
            std::to_wstring(pCtx->currentSettings.defaultLineLimit).c_str(),
            WS_CHILD | WS_VISIBLE | ES_NUMBER,
            280, 122, 145, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_TXT_LINELIMIT, hInst, NULL);
        SendMessageW(hTxtLineLimit, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Checkbox: Auto open output folder
        HWND hChkAutoOpen = CreateWindowExW(0, L"BUTTON", L"Automatically open output subfolder upon completion",
            WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
            28, 155, 390, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_CHK_AUTOOPEN, hInst, NULL);
        SendMessageW(hChkAutoOpen, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Set radio and checkbox states
        if (pCtx->currentSettings.defaultMode == SplitMode::ByCharacters) {
            SendMessageW(hRadChars, BM_SETCHECK, BST_CHECKED, 0);
        } else {
            SendMessageW(hRadLines, BM_SETCHECK, BST_CHECKED, 0);
        }
        SendMessageW(hChkAutoOpen, BM_SETCHECK,
            pCtx->currentSettings.autoOpenFolder ? BST_CHECKED : BST_UNCHECKED, 0);

        // Group Box 2: System & Logging Preferences
        HWND hGrp2 = CreateWindowExW(0, L"BUTTON", L"System & Logging Preferences",
            WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
            16, 202, 428, 110, hWnd, NULL, hInst, NULL);
        SendMessageW(hGrp2, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Label: Log Level
        HWND hLblLogLevel = CreateWindowExW(0, L"STATIC", L"Logging Verbosity:",
            WS_CHILD | WS_VISIBLE, 28, 228, 140, 20, hWnd, NULL, hInst, NULL);
        SendMessageW(hLblLogLevel, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // ComboBox: Log Level
        HWND hCmbLogLevel = CreateWindowExW(0, L"COMBOBOX", L"",
            WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST | WS_VSCROLL,
            175, 225, 250, 100, hWnd, (HMENU)(INT_PTR)IDC_SETT_CMB_LOGLEVEL, hInst, NULL);
        SendMessageW(hCmbLogLevel, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);
        SendMessageW(hCmbLogLevel, CB_ADDSTRING, 0, (LPARAM)L"Verbose / Debug");
        SendMessageW(hCmbLogLevel, CB_ADDSTRING, 0, (LPARAM)L"Information");
        SendMessageW(hCmbLogLevel, CB_ADDSTRING, 0, (LPARAM)L"Errors Only");
        SendMessageW(hCmbLogLevel, CB_SETCURSEL, pCtx->currentSettings.logLevel, 0);

        // Label: Pattern
        HWND hLblPattern = CreateWindowExW(0, L"STATIC", L"Subfolder Pattern:",
            WS_CHILD | WS_VISIBLE, 28, 268, 140, 20, hWnd, NULL, hInst, NULL);
        SendMessageW(hLblPattern, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Edit: Subfolder Pattern
        HWND hTxtPattern = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT",
            pCtx->currentSettings.subfolderPattern.c_str(),
            WS_CHILD | WS_VISIBLE,
            175, 265, 250, 22, hWnd, (HMENU)(INT_PTR)IDC_SETT_TXT_PATTERNTXT, hInst, NULL);
        SendMessageW(hTxtPattern, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        // Chin Buttons: "Okay", "Apply", "Cancel"
        HWND hBtnOkay = CreateWindowExW(0, L"BUTTON", L"Okay",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
            218, 332, 70, 26, hWnd, (HMENU)(INT_PTR)IDC_SETT_BTN_OKAY, hInst, NULL);
        SendMessageW(hBtnOkay, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        HWND hBtnApply = CreateWindowExW(0, L"BUTTON", L"Apply",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            294, 332, 70, 26, hWnd, (HMENU)(INT_PTR)IDC_SETT_BTN_APPLY, hInst, NULL);
        SendMessageW(hBtnApply, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        HWND hBtnCancel = CreateWindowExW(0, L"BUTTON", L"Cancel",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            370, 332, 74, 26, hWnd, (HMENU)(INT_PTR)IDC_SETT_BTN_CANCEL, hInst, NULL);
        SendMessageW(hBtnCancel, WM_SETFONT, (WPARAM)s_hFontBody, TRUE);

        return 0;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hWnd, &ps);
        RECT rcClient;
        GetClientRect(hWnd, &rcClient);

        // Title Banner (Height: 56px)
        RECT rcBanner = { 0, 0, rcClient.right, 56 };
        FillRect(hdc, &rcBanner, (HBRUSH)(COLOR_WINDOW + 1));

        RECT rcBannerLine = { 0, 55, rcClient.right, 56 };
        DrawEdge(hdc, &rcBannerLine, EDGE_ETCHED, BF_BOTTOM);

        HICON hIcon = LoadIconW(NULL, MAKEINTRESOURCEW(32512));
        if (hIcon) {
            DrawIconEx(hdc, 16, 12, hIcon, 32, 32, 0, NULL, DI_NORMAL);
        }

        SetBkMode(hdc, TRANSPARENT);
        SelectObject(hdc, s_hFontTitle);
        SetTextColor(hdc, RGB(20, 20, 20));
        RECT rcTitle = { 60, 10, rcClient.right - 10, 30 };
        DrawTextW(hdc, L"Application Settings", -1, &rcTitle, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        SelectObject(hdc, s_hFontSub);
        SetTextColor(hdc, RGB(80, 80, 80));
        RECT rcSub = { 60, 30, rcClient.right - 10, 48 };
        DrawTextW(hdc, L"Configure default parameters, logging options, and output structure.", -1, &rcSub, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

        // Darker Chin Area (Height: 48px at bottom)
        int chinTop = rcClient.bottom - 48;
        RECT rcChin = { 0, chinTop, rcClient.right, rcClient.bottom };
        HBRUSH hChinBrush = CreateSolidBrush(RGB(224, 224, 224));
        FillRect(hdc, &rcChin, hChinBrush);
        DeleteObject(hChinBrush);

        RECT rcChinLine = { 0, chinTop, rcClient.right, chinTop + 1 };
        DrawEdge(hdc, &rcChinLine, EDGE_ETCHED, BF_TOP);

        EndPaint(hWnd, &ps);
        return 0;
    }

    case WM_CTLCOLORSTATIC: {
        HDC hdcStatic = (HDC)wParam;
        HWND hCtrl = (HWND)lParam;
        RECT rcCtrl, rcWindow;
        GetWindowRect(hCtrl, &rcCtrl);
        GetWindowRect(hWnd, &rcWindow);
        int ctrlRelY = rcCtrl.top - rcWindow.top;
        RECT rcClient;
        GetClientRect(hWnd, &rcClient);

        if (ctrlRelY >= rcClient.bottom - 48) {
            SetBkColor(hdcStatic, RGB(224, 224, 224));
            SetTextColor(hdcStatic, RGB(20, 20, 20));
            static HBRUSH hBrushChinStatic = CreateSolidBrush(RGB(224, 224, 224));
            return (INT_PTR)hBrushChinStatic;
        }
        SetBkMode(hdcStatic, TRANSPARENT);
        return (INT_PTR)GetStockObject(NULL_BRUSH);
    }

    case WM_COMMAND: {
        WORD wId = LOWORD(wParam);
        if (wId == IDC_SETT_BTN_CANCEL || wId == IDCANCEL) {
            DestroyWindow(hWnd);
            return 0;
        }

        if (wId == IDC_SETT_BTN_OKAY || wId == IDC_SETT_BTN_APPLY) {
            if (pCtx && pCtx->pOutSettings) {
                // Read controls into settings
                HWND hRadChars = GetDlgItem(hWnd, IDC_SETT_RAD_CHARS);
                if (SendMessageW(hRadChars, BM_GETCHECK, 0, 0) == BST_CHECKED) {
                    pCtx->pOutSettings->defaultMode = SplitMode::ByCharacters;
                } else {
                    pCtx->pOutSettings->defaultMode = SplitMode::ByLines;
                }

                wchar_t szBuf[64];
                GetDlgItemTextW(hWnd, IDC_SETT_TXT_CHARLIMIT, szBuf, 64);
                uint64_t valChar = _wtoi64(szBuf);
                if (valChar > 0) pCtx->pOutSettings->defaultCharLimit = valChar;

                GetDlgItemTextW(hWnd, IDC_SETT_TXT_LINELIMIT, szBuf, 64);
                uint64_t valLine = _wtoi64(szBuf);
                if (valLine > 0) pCtx->pOutSettings->defaultLineLimit = valLine;

                HWND hChkAutoOpen = GetDlgItem(hWnd, IDC_SETT_CHK_AUTOOPEN);
                pCtx->pOutSettings->autoOpenFolder = (SendMessageW(hChkAutoOpen, BM_GETCHECK, 0, 0) == BST_CHECKED);

                HWND hCmbLogLevel = GetDlgItem(hWnd, IDC_SETT_CMB_LOGLEVEL);
                int selLevel = (int)SendMessageW(hCmbLogLevel, CB_GETCURSEL, 0, 0);
                if (selLevel >= 0) pCtx->pOutSettings->logLevel = selLevel;

                wchar_t szPattern[256];
                GetDlgItemTextW(hWnd, IDC_SETT_TXT_PATTERNTXT, szPattern, 256);
                if (wcslen(szPattern) > 0) pCtx->pOutSettings->subfolderPattern = szPattern;

                pCtx->isApplied = true;
                Logger::LogInfo(L"Settings updated successfully by user.");
            }

            if (wId == IDC_SETT_BTN_OKAY) {
                DestroyWindow(hWnd);
            }
            return 0;
        }
        break;
    }
    }
    return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

// -----------------------------------------------------------------------------
// CLASS REGISTRATION & DIALOG SHOW HELPERS
// -----------------------------------------------------------------------------
void Dialogs::RegisterClasses(HINSTANCE hInstance) {
    WNDCLASSEXW wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize        = sizeof(WNDCLASSEXW);
    wc.style         = CS_HREDRAW | CS_VREDRAW;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);

    // Register About Class
    wc.lpszClassName = ABOUT_CLASS_NAME;
    wc.lpfnWndProc   = AboutWndProc;
    RegisterClassExW(&wc);

    // Register Help Class
    wc.lpszClassName = HELP_CLASS_NAME;
    wc.lpfnWndProc   = HelpWndProc;
    RegisterClassExW(&wc);

    // Register Settings Class
    wc.lpszClassName = SETTINGS_CLASS_NAME;
    wc.lpfnWndProc   = SettingsWndProc;
    RegisterClassExW(&wc);
}

void Dialogs::ShowAbout(HWND hWndParent, HINSTANCE hInstance) {
    RegisterClasses(hInstance);

    int width = 520, height = 260;
    RECT rcParent;
    GetWindowRect(hWndParent, &rcParent);
    int x = rcParent.left + (rcParent.right - rcParent.left - width) / 2;
    int y = rcParent.top + (rcParent.bottom - rcParent.top - height) / 2;

    HWND hDlg = CreateWindowExW(WS_EX_DLGMODALFRAME, ABOUT_CLASS_NAME,
        L"About File Splitter For AI Upload",
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        x, y, width, height, hWndParent, NULL, hInstance, NULL);

    EnableWindow(hWndParent, FALSE);
    MSG msg;
    while (IsWindow(hDlg) && GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    EnableWindow(hWndParent, TRUE);
    SetForegroundWindow(hWndParent);
}

void Dialogs::ShowHelp(HWND hWndParent, HINSTANCE hInstance) {
    RegisterClasses(hInstance);

    int width = 560, height = 480;
    RECT rcParent;
    GetWindowRect(hWndParent, &rcParent);
    int x = rcParent.left + (rcParent.right - rcParent.left - width) / 2;
    int y = rcParent.top + (rcParent.bottom - rcParent.top - height) / 2;

    HWND hDlg = CreateWindowExW(WS_EX_DLGMODALFRAME, HELP_CLASS_NAME,
        L"File Splitter Help & Operational Guide",
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        x, y, width, height, hWndParent, NULL, hInstance, NULL);

    EnableWindow(hWndParent, FALSE);
    MSG msg;
    while (IsWindow(hDlg) && GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    EnableWindow(hWndParent, TRUE);
    SetForegroundWindow(hWndParent);
}

bool Dialogs::ShowSettings(HWND hWndParent, HINSTANCE hInstance, AppSettings& settings) {
    RegisterClasses(hInstance);

    int width = 460, height = 420;
    RECT rcParent;
    GetWindowRect(hWndParent, &rcParent);
    int x = rcParent.left + (rcParent.right - rcParent.left - width) / 2;
    int y = rcParent.top + (rcParent.bottom - rcParent.top - height) / 2;

    SettingsDialogContext ctx;
    ctx.currentSettings = settings;
    ctx.pOutSettings = &settings;
    ctx.isApplied = false;

    HWND hDlg = CreateWindowExW(WS_EX_DLGMODALFRAME, SETTINGS_CLASS_NAME,
        L"File Splitter Configuration Settings",
        WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE,
        x, y, width, height, hWndParent, NULL, hInstance, &ctx);

    EnableWindow(hWndParent, FALSE);
    MSG msg;
    while (IsWindow(hDlg) && GetMessageW(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    EnableWindow(hWndParent, TRUE);
    SetForegroundWindow(hWndParent);

    return ctx.isApplied;
}

} // namespace FileSplitter

#pragma endregion
