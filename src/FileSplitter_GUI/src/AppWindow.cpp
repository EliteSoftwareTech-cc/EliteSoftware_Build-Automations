/**
 * @file AppWindow.cpp
 * @brief Implementation of Main Win32 GUI window adhering to EliteSoftware v1.2.0.0 guidelines.
 * @author EliteSoftwareTech Co.
 */

#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include "AppWindow.h"
#include "Logger.h"
#include <commdlg.h>
#include <shlwapi.h>
#include <uxtheme.h>
#include <sstream>
#include <iomanip>

#pragma region Main AppWindow Implementation

namespace FileSplitter {

static const wchar_t* MAIN_WINDOW_CLASS = L"EliteFileSplitterMainWindowClass";

static void SetListViewItemTextW(HWND hList, int item, int subItem, const wchar_t* text) {
    LVITEMW lvi;
    ZeroMemory(&lvi, sizeof(lvi));
    lvi.iSubItem = subItem;
    lvi.pszText = (LPWSTR)text;
    SendMessageW(hList, LVM_SETITEMTEXTW, (WPARAM)item, (LPARAM)&lvi);
}

AppWindow::AppWindow() {
}

AppWindow::~AppWindow() {
    if (m_workerThread.joinable()) {
        m_cancelToken.store(true);
        m_workerThread.join();
    }
    if (m_hFontTitle) DeleteObject(m_hFontTitle);
    if (m_hFontSub) DeleteObject(m_hFontSub);
    if (m_hFontBody) DeleteObject(m_hFontBody);
    if (m_hFontUnderline) DeleteObject(m_hFontUnderline);
    if (m_hAppIcon) DestroyIcon(m_hAppIcon);
}

void AppWindow::CreateFonts() {
    m_hFontTitle = CreateFontW(-15, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");

    m_hFontSub = CreateFontW(-12, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");

    m_hFontBody = CreateFontW(-13, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");

    m_hFontUnderline = CreateFontW(-13, 0, 0, 0, FW_NORMAL, FALSE, TRUE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
}

HICON AppWindow::LoadDynamicIcon() {
    wchar_t szExePath[MAX_PATH];
    GetModuleFileNameW(NULL, szExePath, MAX_PATH);

    // Priority 1: Check for <ExeName>.ico alongside running executable in directory
    std::wstring icoPath = szExePath;
    size_t dotPos = icoPath.find_last_of(L".");
    if (dotPos != std::wstring::npos) {
        icoPath = icoPath.substr(0, dotPos) + L".ico";
    }

    HICON hIcon = NULL;
    DWORD dwAttrib = GetFileAttributesW(icoPath.c_str());
    if (dwAttrib != INVALID_FILE_ATTRIBUTES && !(dwAttrib & FILE_ATTRIBUTE_DIRECTORY)) {
        hIcon = (HICON)LoadImageW(NULL, icoPath.c_str(), IMAGE_ICON, 32, 32, LR_LOADFROMFILE);
        if (!hIcon) {
            hIcon = ExtractIconW(m_hInstance, icoPath.c_str(), 0);
        }
        if (hIcon) {
            Logger::LogInfo(L"Dynamic Icon Sideloading Priority: Successfully loaded icon from file: " + icoPath);
        }
    }

    // Priority 2: Embedded EXE Resource Fallback
    if (!hIcon) {
        hIcon = (HICON)LoadImageW(m_hInstance, MAKEINTRESOURCEW(IDI_APPICON), IMAGE_ICON, 32, 32, 0);
    }

    // Priority 3: Windows Standard Application Icon Fallback
    if (!hIcon) {
        hIcon = LoadIconW(NULL, MAKEINTRESOURCEW(32512));
    }

    return hIcon;
}

bool AppWindow::Create(HINSTANCE hInstance, int nCmdShow) {
    m_hInstance = hInstance;
    CreateFonts();

    WNDCLASSEXW wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize        = sizeof(WNDCLASSEXW);
    wc.style         = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc   = AppWindow::WindowProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.lpszClassName = MAIN_WINDOW_CLASS;
    
    m_hAppIcon = LoadDynamicIcon();
    wc.hIcon   = m_hAppIcon;
    wc.hIconSm = m_hAppIcon;

    if (!RegisterClassExW(&wc)) {
        return false;
    }

    int width = 780, height = 620;
    int screenW = GetSystemMetrics(SM_CXSCREEN);
    int screenH = GetSystemMetrics(SM_CYSCREEN);
    int x = (screenW - width) / 2;
    int y = (screenH - height) / 2;

    m_hWnd = CreateWindowExW(0, MAIN_WINDOW_CLASS,
        L"File Splitter For AI Upload — EliteSoftwareTech Co. v1.2.0.0",
        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
        x, y, width, height, NULL, NULL, hInstance, this);

    if (!m_hWnd) {
        return false;
    }

    if (m_hAppIcon) {
        SendMessageW(m_hWnd, WM_SETICON, ICON_BIG, (LPARAM)m_hAppIcon);
        SendMessageW(m_hWnd, WM_SETICON, ICON_SMALL, (LPARAM)m_hAppIcon);
    }

    ShowWindow(m_hWnd, nCmdShow);
    UpdateWindow(m_hWnd);

    Logger::LogInfo(L"Win32 GUI Main Window initialized successfully.");
    return true;
}

LRESULT CALLBACK AppWindow::WindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    AppWindow* pThis = nullptr;
    if (uMsg == WM_NCCREATE) {
        CREATESTRUCT* pcs = (CREATESTRUCT*)lParam;
        pThis = (AppWindow*)pcs->lpCreateParams;
        pThis->m_hWnd = hWnd;
        SetWindowLongPtrW(hWnd, GWLP_USERDATA, (LONG_PTR)pThis);
    } else {
        pThis = (AppWindow*)GetWindowLongPtrW(hWnd, GWLP_USERDATA);
    }

    if (pThis) {
        return pThis->HandleMessage(uMsg, wParam, lParam);
    }
    return DefWindowProcW(hWnd, uMsg, wParam, lParam);
}

void AppWindow::InitializeMenuBar() {
    HMENU hMenuBar   = ::CreateMenu();
    HMENU hFileMenu  = CreatePopupMenu();
    HMENU hToolsMenu = CreatePopupMenu();
    HMENU hHelpMenu  = CreatePopupMenu();

    // File Menu
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_OPEN, L"&Open Single File...\tCtrl+O");
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_ADDBATCH, L"&Add Batch Files...\tCtrl+B");
    AppendMenuW(hFileMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_STARTSPLIT, L"&Start Splitting\tF5");
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_CANCEL, L"&Cancel Splitting");
    AppendMenuW(hFileMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hFileMenu, MF_STRING, IDM_FILE_EXIT, L"E&xit\tAlt+F4");

    // Tools Menu
    AppendMenuW(hToolsMenu, MF_STRING, IDM_TOOLS_SETTINGS, L"&Settings...");
    AppendMenuW(hToolsMenu, MF_STRING, IDM_TOOLS_VIEWLOG, L"&View FileSplitter Logs");
    AppendMenuW(hToolsMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hToolsMenu, MF_STRING, IDM_TOOLS_CLEARBATCH, L"&Clear Batch Queue");

    // Help Menu
    AppendMenuW(hHelpMenu, MF_STRING, IDM_HELP_DOCUMENTATION, L"&Documentation & Help\tF1");
    AppendMenuW(hHelpMenu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(hHelpMenu, MF_STRING, IDM_HELP_ABOUT, L"&About File Splitter...");

    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hFileMenu, L"&File");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hToolsMenu, L"&Tools");
    AppendMenuW(hMenuBar, MF_POPUP, (UINT_PTR)hHelpMenu, L"&Help");

    SetMenu(m_hWnd, hMenuBar);
}

void AppWindow::CreateToolbarControls() {
    m_hToolbar = CreateWindowExW(0, TOOLBARCLASSNAMEW, NULL,
        WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_TOOLTIPS | CCS_TOP,
        0, 0, 0, 0, m_hWnd, (HMENU)(INT_PTR)IDC_MAIN_TOOLBAR, m_hInstance, NULL);

    SendMessageW(m_hToolbar, TB_BUTTONSTRUCTSIZE, (WPARAM)sizeof(TBBUTTON), 0);

    // Standard Toolbar buttons
    TBBUTTON tbb[6];
    ZeroMemory(tbb, sizeof(tbb));

    tbb[0].iBitmap = STD_FILEOPEN;
    tbb[0].idCommand = IDM_FILE_OPEN;
    tbb[0].fsState = TBSTATE_ENABLED;
    tbb[0].fsStyle = BTNS_BUTTON;
    tbb[0].iString = (INT_PTR)L"Open";

    tbb[1].iBitmap = STD_FILENEW;
    tbb[1].idCommand = IDM_FILE_STARTSPLIT;
    tbb[1].fsState = TBSTATE_ENABLED;
    tbb[1].fsStyle = BTNS_BUTTON;
    tbb[1].iString = (INT_PTR)L"Start Split";

    tbb[2].iBitmap = STD_DELETE;
    tbb[2].idCommand = IDM_FILE_CANCEL;
    tbb[2].fsState = TBSTATE_INDETERMINATE;
    tbb[2].fsStyle = BTNS_BUTTON;
    tbb[2].iString = (INT_PTR)L"Cancel";

    tbb[3].iBitmap = STD_PROPERTIES;
    tbb[3].idCommand = IDM_TOOLS_SETTINGS;
    tbb[3].fsState = TBSTATE_ENABLED;
    tbb[3].fsStyle = BTNS_BUTTON;
    tbb[3].iString = (INT_PTR)L"Settings";

    tbb[4].iBitmap = STD_PRINT;
    tbb[4].idCommand = IDM_TOOLS_VIEWLOG;
    tbb[4].fsState = TBSTATE_ENABLED;
    tbb[4].fsStyle = BTNS_BUTTON;
    tbb[4].iString = (INT_PTR)L"View Log";

    tbb[5].iBitmap = STD_HELP;
    tbb[5].idCommand = IDM_HELP_DOCUMENTATION;
    tbb[5].fsState = TBSTATE_ENABLED;
    tbb[5].fsStyle = BTNS_BUTTON;
    tbb[5].iString = (INT_PTR)L"Help";

    TBADDBITMAP tbab;
    tbab.hInst = HINST_COMMCTRL;
    tbab.nID = IDB_STD_SMALL_COLOR;
    SendMessageW(m_hToolbar, TB_ADDBITMAP, 0, (LPARAM)&tbab);
    SendMessageW(m_hToolbar, TB_ADDBUTTONSW, 6, (LPARAM)&tbb);
    SendMessageW(m_hToolbar, TB_AUTOSIZE, 0, 0);
}

void AppWindow::CreateMainControls() {
    // 1. Single File Input Controls
    HWND hLblFile = CreateWindowExW(0, L"STATIC", L"Target Input File:",
        WS_CHILD | WS_VISIBLE, 20, 92, 140, 20, m_hWnd, (HMENU)(INT_PTR)IDC_LBL_FILEPATH, m_hInstance, NULL);
    SendMessageW(hLblFile, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hTxtFilePath = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
        WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
        20, 114, 590, 24, m_hWnd, (HMENU)(INT_PTR)IDC_TXT_FILEPATH, m_hInstance, NULL);
    SendMessageW(m_hTxtFilePath, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hBtnBrowse = CreateWindowExW(0, L"BUTTON", L"Browse...",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        620, 114, 130, 24, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_BROWSE, m_hInstance, NULL);
    SendMessageW(m_hBtnBrowse, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    // 2. Split Mode Configuration Group Box
    HWND hGrpMode = CreateWindowExW(0, L"BUTTON", L"Splitting Options & Limits",
        WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        20, 148, 730, 65, m_hWnd, (HMENU)(INT_PTR)IDC_GRP_SPLITMODE, m_hInstance, NULL);
    SendMessageW(hGrpMode, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hRadChars = CreateWindowExW(0, L"BUTTON", L"Split by Character Count",
        WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON | WS_GROUP,
        35, 172, 195, 22, m_hWnd, (HMENU)(INT_PTR)IDC_RAD_CHARS, m_hInstance, NULL);
    SendMessageW(m_hRadChars, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);
    SendMessageW(m_hRadChars, BM_SETCHECK, BST_CHECKED, 0);

    m_hRadLines = CreateWindowExW(0, L"BUTTON", L"Split by Line Count",
        WS_CHILD | WS_VISIBLE | BS_AUTORADIOBUTTON,
        235, 172, 170, 22, m_hWnd, (HMENU)(INT_PTR)IDC_RAD_LINES, m_hInstance, NULL);
    SendMessageW(m_hRadLines, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    HWND hLblLimit = CreateWindowExW(0, L"STATIC", L"Limit:",
        WS_CHILD | WS_VISIBLE, 415, 174, 45, 20, m_hWnd, (HMENU)(INT_PTR)IDC_LBL_LIMIT, m_hInstance, NULL);
    SendMessageW(hLblLimit, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hTxtLimit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"3000",
        WS_CHILD | WS_VISIBLE | ES_NUMBER | ES_RIGHT,
        460, 172, 85, 22, m_hWnd, (HMENU)(INT_PTR)IDC_TXT_LIMIT, m_hInstance, NULL);
    SendMessageW(m_hTxtLimit, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hChkSubfolder = CreateWindowExW(0, L"BUTTON", L"Save in subfolder",
        WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
        555, 172, 185, 22, m_hWnd, (HMENU)(INT_PTR)IDC_CHK_SUBFOLDER, m_hInstance, NULL);
    SendMessageW(m_hChkSubfolder, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);
    SendMessageW(m_hChkSubfolder, BM_SETCHECK, BST_CHECKED, 0);

    // 3. Batch Processing Queue Group Box & ListView
    HWND hGrpBatch = CreateWindowExW(0, L"BUTTON", L"Batch Processing Queue",
        WS_CHILD | WS_VISIBLE | BS_GROUPBOX,
        20, 223, 730, 230, m_hWnd, (HMENU)(INT_PTR)IDC_GRP_BATCHQUEUE, m_hInstance, NULL);
    SendMessageW(hGrpBatch, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hLstBatchFiles = CreateWindowExW(WS_EX_CLIENTEDGE, WC_LISTVIEWW, L"",
        WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_SHOWSELALWAYS | WS_VSCROLL,
        35, 245, 575, 195, m_hWnd, (HMENU)(INT_PTR)IDC_LST_BATCHFILES, m_hInstance, NULL);
    SendMessageW(m_hLstBatchFiles, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);
    ListView_SetExtendedListViewStyle(m_hLstBatchFiles, LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);

    // Setup ListView Columns
    LVCOLUMNW lvc;
    ZeroMemory(&lvc, sizeof(lvc));
    lvc.mask = LVCF_TEXT | LVCF_WIDTH | LVCF_SUBITEM;
    
    lvc.pszText = (LPWSTR)L"File Path";
    lvc.cx = 340;
    lvc.iSubItem = 0;
    ListView_InsertColumn(m_hLstBatchFiles, 0, &lvc);

    lvc.pszText = (LPWSTR)L"Size";
    lvc.cx = 100;
    lvc.iSubItem = 1;
    ListView_InsertColumn(m_hLstBatchFiles, 1, &lvc);

    lvc.pszText = (LPWSTR)L"Status";
    lvc.cx = 115;
    lvc.iSubItem = 2;
    ListView_InsertColumn(m_hLstBatchFiles, 2, &lvc);

    m_hBtnAddBatch = CreateWindowExW(0, L"BUTTON", L"Add Files...",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        620, 245, 120, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_ADDBATCH, m_hInstance, NULL);
    SendMessageW(m_hBtnAddBatch, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hBtnRemoveBatch = CreateWindowExW(0, L"BUTTON", L"Remove Selected",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        620, 280, 120, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_REMOVEBATCH, m_hInstance, NULL);
    SendMessageW(m_hBtnRemoveBatch, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hBtnClearBatch = CreateWindowExW(0, L"BUTTON", L"Clear Queue",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        620, 315, 120, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_CLEARBATCH, m_hInstance, NULL);
    SendMessageW(m_hBtnClearBatch, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    // 4. Progress Bar
    m_hProgressBar = CreateWindowExW(WS_EX_CLIENTEDGE, PROGRESS_CLASSW, L"",
        WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
        20, 462, 730, 20, m_hWnd, (HMENU)(INT_PTR)IDC_PROGRESSBAR, m_hInstance, NULL);

    // 5. The "Chin" Area Controls (Bottom action bar)
    m_hLnkLogFile = CreateWindowExW(0, L"STATIC", L"View FileSplitter Logs",
        WS_CHILD | WS_VISIBLE | SS_NOTIFY,
        20, 508, 160, 20, m_hWnd, (HMENU)(INT_PTR)IDC_LNK_LOGFILE, m_hInstance, NULL);
    SendMessageW(m_hLnkLogFile, WM_SETFONT, (WPARAM)m_hFontUnderline, TRUE);

    m_hBtnOkay = CreateWindowExW(0, L"BUTTON", L"Okay",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON | BS_DEFPUSHBUTTON,
        400, 504, 80, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_OKAY, m_hInstance, NULL);
    SendMessageW(m_hBtnOkay, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hBtnApply = CreateWindowExW(0, L"BUTTON", L"Apply",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        488, 504, 75, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_APPLY, m_hInstance, NULL);
    SendMessageW(m_hBtnApply, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    m_hBtnCancel = CreateWindowExW(0, L"BUTTON", L"Cancel",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        571, 504, 80, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_CANCEL, m_hInstance, NULL);
    SendMessageW(m_hBtnCancel, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);
    EnableWindow(m_hBtnCancel, FALSE); // Initially disabled until split starts

    m_hBtnExit = CreateWindowExW(0, L"BUTTON", L"Exit",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        659, 504, 75, 26, m_hWnd, (HMENU)(INT_PTR)IDC_BTN_EXIT, m_hInstance, NULL);
    SendMessageW(m_hBtnExit, WM_SETFONT, (WPARAM)m_hFontBody, TRUE);

    // 6. Status Bar with Grab Handle
    m_hStatusBar = CreateWindowExW(0, STATUSCLASSNAMEW, L"",
        WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
        0, 0, 0, 0, m_hWnd, (HMENU)(INT_PTR)IDC_STATUSBAR, m_hInstance, NULL);
    
    int sbParts[3] = { 380, 620, -1 };
    SendMessageW(m_hStatusBar, SB_SETPARTS, 3, (LPARAM)sbParts);
    SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Ready");
    SendMessageW(m_hStatusBar, SB_SETTEXTW, 1, (LPARAM)L"Mode: Characters (3000)");
    SendMessageW(m_hStatusBar, SB_SETTEXTW, 2, (LPARAM)L"Queue: 0 files");

    // Enable Non-Elevated Drag & Drop
    DragAcceptFiles(m_hWnd, TRUE);
}

void AppWindow::AddTooltip(HWND hControl, const wchar_t* tipText) {
    if (!m_hToolTip || !hControl) return;

    TOOLINFOW ti;
    ZeroMemory(&ti, sizeof(ti));
    ti.cbSize = sizeof(TOOLINFOW);
    ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;
    ti.hwnd = m_hWnd;
    ti.uId = (UINT_PTR)hControl;
    ti.lpszText = (LPWSTR)tipText;

    SendMessageW(m_hToolTip, TTM_ADDTOOLW, 0, (LPARAM)&ti);
}

void AppWindow::CreateTooltips() {
    m_hToolTip = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, NULL,
        WS_POPUP | TTS_ALWAYSTIP | TTS_BALLOON | TTS_NOPREFIX,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        m_hWnd, NULL, m_hInstance, NULL);

    SetWindowPos(m_hToolTip, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);

    // Multi-line detailed tooltips for ALL interactive elements with sarcastic/witty undertone
    AddTooltip(m_hTxtFilePath,
        L"Target Input File Path\r\n"
        L"Path to your gigantic text file. Drag & drop works too—if your mouse aims true.\r\n"
        L"Accepts .txt, .log, .md, .json, .csv, and other text-based prompt formats.");

    AddTooltip(m_hBtnBrowse,
        L"Browse System Files\r\n"
        L"Opens standard Win32 File Open Dialog.\r\n"
        L"Because typing 120-character paths manually is classified as cruel and unusual torture.");

    AddTooltip(m_hRadChars,
        L"Split by Character Count\r\n"
        L"Slices text based on total UTF-8 codepoints.\r\n"
        L"Essential when LLMs enforce strict context window character limits.");

    AddTooltip(m_hRadLines,
        L"Split by Line Count\r\n"
        L"Slices text cleanly by line breaks (CRLF/LF).\r\n"
        L"Ideal for source code files, CSV records, and structured log files.");

    AddTooltip(m_hTxtLimit,
        L"Maximum Chunk Size Limit\r\n"
        L"Specifies maximum characters or lines per output chunk file.\r\n"
        L"Enter zero only if you enjoy divide-by-zero exceptions.");

    AddTooltip(m_hChkSubfolder,
        L"Organize Chunks in Subfolder\r\n"
        L"Creates dedicated subfolder '<FileName>_parts' for generated chunks.\r\n"
        L"Prevents cluttering your desktop with hundreds of individual files.");

    AddTooltip(m_hLstBatchFiles,
        L"Batch Processing Queue\r\n"
        L"List of queued files for batch processing.\r\n"
        L"Select items and click 'Remove Selected' or drop more files to queue.");

    AddTooltip(m_hBtnAddBatch,
        L"Add Files to Batch Queue\r\n"
        L"Appends one or more text files to the batch processing queue.\r\n"
        L"Processes sequentially without freezing the user interface.");

    AddTooltip(m_hBtnRemoveBatch,
        L"Remove Selected File\r\n"
        L"Removes currently selected file from batch queue.\r\n"
        L"Does not delete the physical file on disk.");

    AddTooltip(m_hBtnClearBatch,
        L"Clear Batch Queue\r\n"
        L"Empties the batch processing queue.\r\n"
        L"Resets queue counter so you can start with a fresh file batch.");

    AddTooltip(m_hProgressBar,
        L"Splitting Operation Progress\r\n"
        L"Visual progress indicator for current splitting job.\r\n"
        L"Watch the green progress bar move faster than a Python script.");

    AddTooltip(m_hLnkLogFile,
        L"View System Log File\r\n"
        L"Launches Notepad to reveal log output.\r\n"
        L"Located at %SystemDrive%\\EliteSoftware\\Logs\\FileSplitter.log.");

    AddTooltip(m_hBtnOkay,
        L"Execute File Splitting\r\n"
        L"Initiates file splitting immediately on background thread.\r\n"
        L"Sit back and enjoy native C++ multi-threaded performance.");

    AddTooltip(m_hBtnApply,
        L"Save Preferences\r\n"
        L"Saves active splitting parameters as default settings.\r\n"
        L"Does not trigger a file splitting execution.");

    AddTooltip(m_hBtnCancel,
        L"Cancel Active Operation\r\n"
        L"Aborts background splitting cleanly before disk fills up.\r\n"
        L"Safely finishes current chunk file before stopping.");

    AddTooltip(m_hBtnExit,
        L"Exit Application\r\n"
        L"Terminates File Splitter and releases resources.\r\n"
        L"Saved settings are preserved across sessions.");
}

void AppWindow::LayoutControls() {
    RECT rcClient;
    GetClientRect(m_hWnd, &rcClient);
    int width = rcClient.right;
    int height = rcClient.bottom;

    // Resize Menu / Toolbar / Statusbar
    if (m_hToolbar) SendMessageW(m_hToolbar, WM_SIZE, 0, 0);
    if (m_hStatusBar) SendMessageW(m_hStatusBar, WM_SIZE, 0, 0);

    int tbHeight = 28;
    int bannerHeight = 56;
    int chinHeight = 48;
    int sbHeight = 24;

    int insetTop = tbHeight + bannerHeight;
    int chinTop = height - sbHeight - chinHeight;

    // Adjust single file browse button & text box
    int rightMargin = 20;
    int btnWidth = 120;
    SetWindowPos(m_hTxtFilePath, NULL, 20, insetTop + 26, width - 40 - btnWidth - 10, 24, SWP_NOZORDER);
    SetWindowPos(m_hBtnBrowse, NULL, width - rightMargin - btnWidth, insetTop + 26, btnWidth, 24, SWP_NOZORDER);

    // Adjust Group Box 1 (Mode Options)
    SetWindowPos(GetDlgItem(m_hWnd, IDC_GRP_SPLITMODE), NULL, 20, insetTop + 60, width - 40, 65, SWP_NOZORDER);

    // Adjust Group Box 2 (Batch Queue)
    int batchTop = insetTop + 135;
    int batchHeight = chinTop - batchTop - 35; // Leave room for progress bar
    SetWindowPos(GetDlgItem(m_hWnd, IDC_GRP_BATCHQUEUE), NULL, 20, batchTop, width - 40, batchHeight, SWP_NOZORDER);
    SetWindowPos(m_hLstBatchFiles, NULL, 35, batchTop + 22, width - 185, batchHeight - 32, SWP_NOZORDER);

    // Batch buttons
    SetWindowPos(m_hBtnAddBatch, NULL, width - 135, batchTop + 22, 110, 26, SWP_NOZORDER);
    SetWindowPos(m_hBtnRemoveBatch, NULL, width - 135, batchTop + 56, 110, 26, SWP_NOZORDER);
    SetWindowPos(m_hBtnClearBatch, NULL, width - 135, batchTop + 90, 110, 26, SWP_NOZORDER);

    // Progress Bar
    SetWindowPos(m_hProgressBar, NULL, 20, chinTop - 25, width - 40, 18, SWP_NOZORDER);

    // Chin Controls
    SetWindowPos(m_hLnkLogFile, NULL, 20, chinTop + 14, 160, 20, SWP_NOZORDER);
    SetWindowPos(m_hBtnExit, NULL, width - 20 - 75, chinTop + 11, 75, 26, SWP_NOZORDER);
    SetWindowPos(m_hBtnCancel, NULL, width - 20 - 75 - 10 - 80, chinTop + 11, 80, 26, SWP_NOZORDER);
    SetWindowPos(m_hBtnApply, NULL, width - 20 - 75 - 10 - 80 - 10 - 75, chinTop + 11, 75, 26, SWP_NOZORDER);
    SetWindowPos(m_hBtnOkay, NULL, width - 20 - 75 - 10 - 80 - 10 - 75 - 10 - 80, chinTop + 11, 80, 26, SWP_NOZORDER);

    // Statusbar Parts
    int sbParts[3] = { width / 2, width - 160, -1 };
    SendMessageW(m_hStatusBar, SB_SETPARTS, 3, (LPARAM)sbParts);
}

void AppWindow::OnPaint(HDC hdc) {
    RECT rcClient;
    GetClientRect(m_hWnd, &rcClient);

    int tbHeight = 28;
    int bannerHeight = 56;
    int chinHeight = 48;
    int sbHeight = 24;

    // 1. Draw Title Banner (Height: 56px, directly below toolbar)
    RECT rcBanner = { 0, tbHeight, rcClient.right, tbHeight + bannerHeight };
    FillRect(hdc, &rcBanner, (HBRUSH)(COLOR_WINDOW + 1));

    RECT rcBannerLine = { 0, tbHeight + bannerHeight - 1, rcClient.right, tbHeight + bannerHeight };
    DrawEdge(hdc, &rcBannerLine, EDGE_ETCHED, BF_BOTTOM);

    if (m_hAppIcon) {
        DrawIconEx(hdc, 16, tbHeight + 12, m_hAppIcon, 32, 32, 0, NULL, DI_NORMAL);
    }

    SetBkMode(hdc, TRANSPARENT);
    SelectObject(hdc, m_hFontTitle);
    SetTextColor(hdc, RGB(20, 20, 20));
    RECT rcTitle = { 60, tbHeight + 10, rcClient.right - 10, tbHeight + 30 };
    DrawTextW(hdc, L"File Splitter For AI Upload", -1, &rcTitle, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

    SelectObject(hdc, m_hFontSub);
    SetTextColor(hdc, RGB(80, 80, 80));
    RECT rcSub = { 60, tbHeight + 30, rcClient.right - 10, tbHeight + 48 };
    DrawTextW(hdc, L"High-Performance Native Text File Slicing Utility (v1.2.0.0)", -1, &rcSub, DT_SINGLELINE | DT_LEFT | DT_VCENTER);

    // 2. Draw Chin Area (Height: 48px, above statusbar)
    int chinTop = rcClient.bottom - sbHeight - chinHeight;
    RECT rcChin = { 0, chinTop, rcClient.right, rcClient.bottom - sbHeight };
    HBRUSH hChinBrush = CreateSolidBrush(RGB(224, 224, 224));
    FillRect(hdc, &rcChin, hChinBrush);
    DeleteObject(hChinBrush);

    RECT rcChinLine = { 0, chinTop, rcClient.right, chinTop + 1 };
    DrawEdge(hdc, &rcChinLine, EDGE_ETCHED, BF_TOP);
}

LRESULT AppWindow::HandleMessage(UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_CREATE: {
        InitializeMenuBar();
        CreateToolbarControls();
        CreateMainControls();
        CreateTooltips();
        Logger::Initialize();
        return 0;
    }

    case WM_SIZE: {
        LayoutControls();
        return 0;
    }

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(m_hWnd, &ps);
        OnPaint(hdc);
        EndPaint(m_hWnd, &ps);
        return 0;
    }

    case WM_CTLCOLORSTATIC: {
        HDC hdcStatic = (HDC)wParam;
        HWND hCtrl = (HWND)lParam;
        
        if (hCtrl == m_hLnkLogFile) {
            SetBkColor(hdcStatic, RGB(224, 224, 224));
            SetTextColor(hdcStatic, RGB(0, 102, 204));
            static HBRUSH hBrushLink = CreateSolidBrush(RGB(224, 224, 224));
            return (INT_PTR)hBrushLink;
        }

        RECT rcCtrl, rcWindow;
        GetWindowRect(hCtrl, &rcCtrl);
        GetWindowRect(m_hWnd, &rcWindow);
        int ctrlRelY = rcCtrl.top - rcWindow.top;
        RECT rcClient;
        GetClientRect(m_hWnd, &rcClient);

        int chinTop = rcClient.bottom - 24 - 48;
        if (ctrlRelY >= chinTop) {
            SetBkColor(hdcStatic, RGB(224, 224, 224));
            SetTextColor(hdcStatic, RGB(20, 20, 20));
            static HBRUSH hBrushChinStatic = CreateSolidBrush(RGB(224, 224, 224));
            return (INT_PTR)hBrushChinStatic;
        }
        SetBkMode(hdcStatic, TRANSPARENT);
        return (INT_PTR)GetStockObject(NULL_BRUSH);
    }

    case WM_SETCURSOR: {
        HWND hCtrl = (HWND)wParam;
        if (hCtrl == m_hLnkLogFile) {
            SetCursor(LoadCursorW(NULL, MAKEINTRESOURCEW(32514)));
            return TRUE;
        }
        break;
    }

    case WM_COMMAND: {
        WORD wId = LOWORD(wParam);
        WORD wEvent = HIWORD(wParam);
        HWND hCtrl = (HWND)lParam;
        OnCommand(wId, wEvent, hCtrl);
        return 0;
    }

    case WM_DROPFILES: {
        OnDropFiles((HDROP)wParam);
        return 0;
    }

    case WM_SPLIT_PROGRESS: {
        DWORD percent = (DWORD)wParam;
        ProgressInfo* pInfo = (ProgressInfo*)lParam;
        
        SendMessageW(m_hProgressBar, PBM_SETPOS, percent, 0);

        if (pInfo) {
            wchar_t szStatus[256];
            swprintf_s(szStatus, 256, L"Status: Processing file %zu of %zu (%u%%)...",
                pInfo->currentFile, pInfo->totalFiles, percent);
            SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)szStatus);
            delete pInfo;
        }
        return 0;
    }

    case WM_SPLIT_COMPLETE: {
        BOOL success = (BOOL)wParam;
        BatchSplitResult* pBatchResult = (BatchSplitResult*)lParam;

        UpdateControlsState(false);
        m_isSplitting = false;
        SendMessageW(m_hProgressBar, PBM_SETPOS, 100, 0);

        if (success && pBatchResult) {
            size_t totalChunks = 0;
            for (const auto& res : pBatchResult->results) {
                totalChunks += res.chunksCreated;
            }

            wchar_t szStatus[256];
            swprintf_s(szStatus, 256, L"Status: Splitting completed! %zu chunks created across %zu file(s).",
                totalChunks, pBatchResult->successfulFiles);
            SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)szStatus);

            std::wstring logMsg = L"Split operation completed successfully. Created " +
                std::to_wstring(totalChunks) + L" chunk files.";
            Logger::LogInfo(logMsg);

            MessageBoxW(m_hWnd, logMsg.c_str(), L"EliteSoftware Operation Complete", MB_OK | MB_ICONINFORMATION);
            
            // Auto open output subfolder if enabled
            if (m_settings.autoOpenFolder && !pBatchResult->results.empty()) {
                std::wstring folderToOpen = pBatchResult->results[0].outputFolderPath;
                ShellExecuteW(m_hWnd, L"open", folderToOpen.c_str(), NULL, NULL, SW_SHOWNORMAL);
            }
        } else {
            SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Splitting operation cancelled or encountered errors.");
            Logger::LogWarning(L"Split operation was cancelled or finished with errors.");
        }

        if (pBatchResult) delete pBatchResult;
        return 0;
    }

    case WM_SPLIT_ERROR: {
        wchar_t* pErrStr = (wchar_t*)lParam;
        UpdateControlsState(false);
        m_isSplitting = false;

        std::wstring errText = pErrStr ? pErrStr : L"An unknown error occurred during splitting.";
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Operation failed.");
        Logger::LogError(L"Split Error: " + errText);

        MessageBoxW(m_hWnd, errText.c_str(), L"EliteSoftware Splitting Exception", MB_OK | MB_ICONERROR);

        if (pErrStr) delete[] pErrStr;
        return 0;
    }

    case WM_DESTROY: {
        PostQuitMessage(0);
        return 0;
    }
    }
    return DefWindowProcW(m_hWnd, uMsg, wParam, lParam);
}

void AppWindow::FormatFileSize(uint64_t bytes, wchar_t* outBuf, size_t bufLen) {
    if (bytes < 1024) {
        swprintf_s(outBuf, bufLen, L"%llu B", bytes);
    } else if (bytes < 1024 * 1024) {
        double kb = (double)bytes / 1024.0;
        swprintf_s(outBuf, bufLen, L"%.1f KB", kb);
    } else {
        double mb = (double)bytes / (1024.0 * 1024.0);
        swprintf_s(outBuf, bufLen, L"%.2f MB", mb);
    }
}

void AppWindow::BrowseInputFile() {
    wchar_t szFile[MAX_PATH];
    ZeroMemory(szFile, sizeof(szFile));

    OPENFILENAMEW ofn;
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(OPENFILENAMEW);
    ofn.hwndOwner = m_hWnd;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = MAX_PATH;
    ofn.lpstrFilter = L"Text Files (*.txt;*.log;*.md;*.json;*.csv)\0*.txt;*.log;*.md;*.json;*.csv\0All Files (*.*)\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;

    if (GetOpenFileNameW(&ofn)) {
        SetWindowTextW(m_hTxtFilePath, szFile);
        Logger::LogInfo(L"Selected input file via Browse: " + std::wstring(szFile));
    }
}

void AppWindow::AddBatchFiles() {
    wchar_t szFiles[8192];
    ZeroMemory(szFiles, sizeof(szFiles));

    OPENFILENAMEW ofn;
    ZeroMemory(&ofn, sizeof(ofn));
    ofn.lStructSize = sizeof(OPENFILENAMEW);
    ofn.hwndOwner = m_hWnd;
    ofn.lpstrFile = szFiles;
    ofn.nMaxFile = 8192;
    ofn.lpstrFilter = L"Text Files (*.txt;*.log;*.md;*.json;*.csv)\0*.txt;*.log;*.md;*.json;*.csv\0All Files (*.*)\0*.*\0";
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST | OFN_ALLOWMULTISELECT | OFN_EXPLORER;

    if (GetOpenFileNameW(&ofn)) {
        std::vector<std::wstring> newFiles;
        wchar_t* p = szFiles;
        std::wstring dir = p;
        p += dir.length() + 1;

        if (*p == L'\0') {
            // Single file selected
            newFiles.push_back(dir);
        } else {
            // Multiple files selected
            while (*p != L'\0') {
                std::wstring fullPath = dir + L"\\" + p;
                newFiles.push_back(fullPath);
                p += wcslen(p) + 1;
            }
        }

        for (const auto& file : newFiles) {
            // Avoid duplicates
            bool exists = false;
            for (const auto& bFile : m_batchFiles) {
                if (_wcsicmp(bFile.c_str(), file.c_str()) == 0) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                m_batchFiles.push_back(file);
                
                WIN32_FILE_ATTRIBUTE_DATA fad;
                uint64_t fileSize = 0;
                if (GetFileAttributesExW(file.c_str(), GetFileExInfoStandard, &fad)) {
                    fileSize = ((uint64_t)fad.nFileSizeHigh << 32) | fad.nFileSizeLow;
                }

                wchar_t szSize[64];
                FormatFileSize(fileSize, szSize, 64);

                LVITEMW lvi;
                ZeroMemory(&lvi, sizeof(lvi));
                lvi.mask = LVIF_TEXT;
                lvi.iItem = ListView_GetItemCount(m_hLstBatchFiles);
                lvi.pszText = (LPWSTR)file.c_str();
                int idx = ListView_InsertItem(m_hLstBatchFiles, &lvi);

                SetListViewItemTextW(m_hLstBatchFiles, idx, 1, szSize);
                SetListViewItemTextW(m_hLstBatchFiles, idx, 2, L"Pending");
            }
        }

        wchar_t szStatus[64];
        swprintf_s(szStatus, 64, L"Queue: %zu files", m_batchFiles.size());
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 2, (LPARAM)szStatus);

        Logger::LogInfo(L"Added " + std::to_wstring(newFiles.size()) + L" file(s) to batch processing queue.");
    }
}

void AppWindow::RemoveSelectedBatchFile() {
    int selected = ListView_GetNextItem(m_hLstBatchFiles, -1, LVNI_SELECTED);
    if (selected >= 0 && selected < (int)m_batchFiles.size()) {
        m_batchFiles.erase(m_batchFiles.begin() + selected);
        ListView_DeleteItem(m_hLstBatchFiles, selected);

        wchar_t szStatus[64];
        swprintf_s(szStatus, 64, L"Queue: %zu files", m_batchFiles.size());
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 2, (LPARAM)szStatus);
    }
}

void AppWindow::ClearBatchQueue() {
    m_batchFiles.clear();
    ListView_DeleteAllItems(m_hLstBatchFiles);
    SendMessageW(m_hStatusBar, SB_SETTEXTW, 2, (LPARAM)L"Queue: 0 files");
    Logger::LogInfo(L"Cleared batch processing queue.");
}

void AppWindow::OnDropFiles(HDROP hDrop) {
    UINT fileCount = DragQueryFileW(hDrop, 0xFFFFFFFF, NULL, 0);
    if (fileCount == 0) {
        DragFinish(hDrop);
        return;
    }

    if (fileCount == 1 && m_batchFiles.empty()) {
        wchar_t szFilePath[MAX_PATH];
        DragQueryFileW(hDrop, 0, szFilePath, MAX_PATH);
        SetWindowTextW(m_hTxtFilePath, szFilePath);
        Logger::LogInfo(L"Dropped single file: " + std::wstring(szFilePath));
    } else {
        for (UINT i = 0; i < fileCount; i++) {
            wchar_t szFilePath[MAX_PATH];
            DragQueryFileW(hDrop, i, szFilePath, MAX_PATH);

            bool exists = false;
            for (const auto& bFile : m_batchFiles) {
                if (_wcsicmp(bFile.c_str(), szFilePath) == 0) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                m_batchFiles.push_back(szFilePath);

                WIN32_FILE_ATTRIBUTE_DATA fad;
                uint64_t fileSize = 0;
                if (GetFileAttributesExW(szFilePath, GetFileExInfoStandard, &fad)) {
                    fileSize = ((uint64_t)fad.nFileSizeHigh << 32) | fad.nFileSizeLow;
                }

                wchar_t szSize[64];
                FormatFileSize(fileSize, szSize, 64);

                LVITEMW lvi;
                ZeroMemory(&lvi, sizeof(lvi));
                lvi.mask = LVIF_TEXT;
                lvi.iItem = ListView_GetItemCount(m_hLstBatchFiles);
                lvi.pszText = szFilePath;
                int idx = ListView_InsertItem(m_hLstBatchFiles, &lvi);

                SetListViewItemTextW(m_hLstBatchFiles, idx, 1, szSize);
                SetListViewItemTextW(m_hLstBatchFiles, idx, 2, L"Pending");
            }
        }

        wchar_t szStatus[64];
        swprintf_s(szStatus, 64, L"Queue: %zu files", m_batchFiles.size());
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 2, (LPARAM)szStatus);

        Logger::LogInfo(L"Dropped " + std::to_wstring(fileCount) + L" files into batch queue.");
    }
    DragFinish(hDrop);
}

void AppWindow::UpdateControlsState(bool isSplitting) {
    EnableWindow(m_hBtnOkay, !isSplitting);
    EnableWindow(m_hBtnApply, !isSplitting);
    EnableWindow(m_hBtnBrowse, !isSplitting);
    EnableWindow(m_hBtnAddBatch, !isSplitting);
    EnableWindow(m_hBtnRemoveBatch, !isSplitting);
    EnableWindow(m_hBtnClearBatch, !isSplitting);
    EnableWindow(m_hTxtFilePath, !isSplitting);
    EnableWindow(m_hTxtLimit, !isSplitting);
    EnableWindow(m_hRadChars, !isSplitting);
    EnableWindow(m_hRadLines, !isSplitting);
    EnableWindow(m_hChkSubfolder, !isSplitting);

    EnableWindow(m_hBtnCancel, isSplitting);

    // Update toolbar button states
    if (m_hToolbar) {
        SendMessageW(m_hToolbar, TB_ENABLEBUTTON, IDM_FILE_OPEN, MAKELONG(!isSplitting, 0));
        SendMessageW(m_hToolbar, TB_ENABLEBUTTON, IDM_FILE_STARTSPLIT, MAKELONG(!isSplitting, 0));
        SendMessageW(m_hToolbar, TB_ENABLEBUTTON, IDM_FILE_CANCEL, MAKELONG(isSplitting, 0));
    }
}

void AppWindow::StartSplitOperation() {
    if (m_isSplitting) return;

    // Determine files to split (Single file or Batch list)
    wchar_t szSinglePath[MAX_PATH] = { 0 };
    GetWindowTextW(m_hTxtFilePath, szSinglePath, MAX_PATH);

    std::vector<std::wstring> targetFiles;
    if (wcslen(szSinglePath) > 0) {
        targetFiles.push_back(szSinglePath);
    }
    for (const auto& bFile : m_batchFiles) {
        if (targetFiles.empty() || _wcsicmp(targetFiles[0].c_str(), bFile.c_str()) != 0) {
            targetFiles.push_back(bFile);
        }
    }

    if (targetFiles.empty()) {
        MessageBoxW(m_hWnd,
            L"Please select an input file or add files to the batch processing queue.",
            L"EliteSoftware Validation Warning", MB_OK | MB_ICONWARNING);
        return;
    }

    // Read Limit
    wchar_t szLimit[64];
    GetWindowTextW(m_hTxtLimit, szLimit, 64);
    uint64_t maxLimit = _wtoi64(szLimit);
    if (maxLimit == 0) {
        MessageBoxW(m_hWnd,
            L"Limit per chunk must be greater than zero. Enter zero only if you enjoy divide-by-zero exceptions.",
            L"EliteSoftware Validation Warning", MB_OK | MB_ICONWARNING);
        return;
    }

    // Read Split Mode
    SplitMode mode = SplitMode::ByCharacters;
    if (SendMessageW(m_hRadLines, BM_GETCHECK, 0, 0) == BST_CHECKED) {
        mode = SplitMode::ByLines;
    }

    m_isSplitting = true;
    m_cancelToken.store(false);
    UpdateControlsState(true);
    SendMessageW(m_hProgressBar, PBM_SETPOS, 0, 0);
    SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Starting background split worker...");

    HWND hWndMain = m_hWnd;
    std::atomic<bool>* pCancel = &m_cancelToken;

    // Join prior worker if any
    if (m_workerThread.joinable()) {
        m_workerThread.join();
    }

    m_workerThread = std::thread([hWndMain, targetFiles, mode, maxLimit, pCancel]() {
        SplitOptions baseOptions;
        baseOptions.mode = mode;
        baseOptions.maxLimit = maxLimit;
        baseOptions.cancelToken = pCancel;

        baseOptions.progressCallback = [hWndMain](size_t currentFile, size_t totalFiles, uint64_t bytesProcessed, uint64_t totalBytes) {
            ProgressInfo* pInfo = new ProgressInfo();
            pInfo->currentFile = currentFile;
            pInfo->totalFiles = totalFiles;
            pInfo->bytesProcessed = bytesProcessed;
            pInfo->totalBytes = totalBytes;
            
            int percent = 0;
            if (totalBytes > 0) {
                percent = (int)((bytesProcessed * 100) / totalBytes);
            }
            pInfo->percent = percent;

            PostMessageW(hWndMain, WM_SPLIT_PROGRESS, (WPARAM)percent, (LPARAM)pInfo);
        };

        BatchSplitResult* pBatchResult = new BatchSplitResult();

        try {
            *pBatchResult = TextSplitterEngine::SplitBatch(targetFiles, baseOptions);
            bool allSuccess = (!pBatchResult->wasCancelled && pBatchResult->failedFiles == 0);
            PostMessageW(hWndMain, WM_SPLIT_COMPLETE, (WPARAM)(allSuccess ? TRUE : FALSE), (LPARAM)pBatchResult);
        } catch (const std::exception& ex) {
            delete pBatchResult;
            std::string errStr = ex.what();
            int wlen = MultiByteToWideChar(CP_UTF8, 0, errStr.c_str(), -1, NULL, 0);
            wchar_t* pWerr = new wchar_t[wlen + 1];
            MultiByteToWideChar(CP_UTF8, 0, errStr.c_str(), -1, pWerr, wlen);

            PostMessageW(hWndMain, WM_SPLIT_ERROR, 0, (LPARAM)pWerr);
        }
    });
}

void AppWindow::CancelSplitOperation() {
    if (m_isSplitting) {
        m_cancelToken.store(true);
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Cancellation requested...");
        Logger::LogInfo(L"User requested cancellation of file splitting operation.");
    }
}

void AppWindow::OnCommand(WORD wId, WORD wEvent, HWND hCtrl) {
    (void)wEvent;
    (void)hCtrl;

    switch (wId) {
    case IDM_FILE_OPEN:
    case IDC_BTN_BROWSE:
        BrowseInputFile();
        break;

    case IDM_FILE_ADDBATCH:
    case IDC_BTN_ADDBATCH:
        AddBatchFiles();
        break;

    case IDC_BTN_REMOVEBATCH:
        RemoveSelectedBatchFile();
        break;

    case IDM_TOOLS_CLEARBATCH:
    case IDC_BTN_CLEARBATCH:
        ClearBatchQueue();
        break;

    case IDM_FILE_STARTSPLIT:
    case IDC_BTN_OKAY:
        StartSplitOperation();
        break;

    case IDM_FILE_CANCEL:
    case IDC_BTN_CANCEL:
        CancelSplitOperation();
        break;

    case IDC_BTN_APPLY:
        // Save limits and status
        Logger::LogInfo(L"Configuration parameters applied.");
        SendMessageW(m_hStatusBar, SB_SETTEXTW, 0, (LPARAM)L"Status: Configuration settings saved.");
        break;

    case IDM_TOOLS_SETTINGS:
    case IDB_TOOLBAR_SETTINGS:
        if (Dialogs::ShowSettings(m_hWnd, m_hInstance, m_settings)) {
            // Apply new settings to UI controls
            if (m_settings.defaultMode == SplitMode::ByCharacters) {
                SendMessageW(m_hRadChars, BM_SETCHECK, BST_CHECKED, 0);
                SendMessageW(m_hRadLines, BM_SETCHECK, BST_UNCHECKED, 0);
                SetWindowTextW(m_hTxtLimit, std::to_wstring(m_settings.defaultCharLimit).c_str());
            } else {
                SendMessageW(m_hRadChars, BM_SETCHECK, BST_UNCHECKED, 0);
                SendMessageW(m_hRadLines, BM_SETCHECK, BST_CHECKED, 0);
                SetWindowTextW(m_hTxtLimit, std::to_wstring(m_settings.defaultLineLimit).c_str());
            }
        }
        break;

    case IDM_TOOLS_VIEWLOG:
    case IDB_TOOLBAR_VIEWLOG:
    case IDC_LNK_LOGFILE:
        Logger::OpenLogFileInNotepad(m_hWnd);
        break;

    case IDM_HELP_DOCUMENTATION:
    case IDB_TOOLBAR_HELP:
        Dialogs::ShowHelp(m_hWnd, m_hInstance);
        break;

    case IDM_HELP_ABOUT:
        Dialogs::ShowAbout(m_hWnd, m_hInstance);
        break;

    case IDM_FILE_EXIT:
    case IDC_BTN_EXIT:
        DestroyWindow(m_hWnd);
        break;
    }
}

} // namespace FileSplitter

#pragma endregion
