#include <windows.h>
#include <iostream>
#include <commctrl.h>
#include <windowsx.h>
#include <string>
#include <vector>
#include <fstream>
#include <filesystem>
#include <sstream>
#include <iomanip>
#include <shellapi.h>
#include "ProgressDialog.h"

#pragma comment(lib, "comctl32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "msimg32.lib")
#pragma comment(lib, "winmm.lib")

#include <mmsystem.h>
#include <gdiplus.h>
#pragma comment(lib, "gdiplus.lib")
#pragma comment(lib, "version.lib")

// EliteSoftware GUI Guidelines enforce Native Win32 aesthetics with visual styles.
#pragma comment(linker,"\"/manifestdependency:type='win32' \
name='Microsoft.Windows.Common-Controls' version='6.0.0.0' \
processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

#define IDC_TARGET_FILE 201
#define IDC_BTN_BROWSE 202
#define IDC_LST_RESOURCES 203
#define IDC_IMG_PREVIEW 210
#define IDC_TEXT_PREVIEW 220
#define IDC_BTN_SAVE_RESOURCE 221
#define IDC_BTN_PLAY_WAV 222
#define IDC_BTN_LIST 204
#define IDC_BTN_REPLACE 205
#define IDC_LOGS_LINK 206
#define IDC_BTN_SETTINGS 207
#define IDC_BTN_OKAY 208
#define IDC_BTN_CANCEL 209
#define IDC_BTN_EXTRACT 211
#define IDC_BTN_DELETE 212
#define IDC_BTN_ADD 213

#define IDC_MAIN_TOOL 300
#define IDM_FILE_OPEN 1001
#define IDM_FILE_SAVE 1002
#define IDM_FILE_SAVEAS 1003
#define IDM_FILE_EXPORT_MONOLITHIC 1004
#define IDM_TEST_LOAD 2000
#define IDM_FILE_EXIT 301
#define IDM_EDIT_REPLACE 1005
#define IDM_VIEW_EXPAND 1006
#define IDM_ACTION_SCAN 1007
#define IDM_HELP_CONTENTS 302
#define IDM_HELP_ABOUT 303
#define IDM_HELP_WHATSNEW 304
#ifndef APP_VERSION
#define APP_VERSION "1.0.0.0"
#endif

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

// Globals
bool g_bSafetyBackup = true;
bool g_bVerboseLogging = true;
bool g_bShowResourceOrigins = true;

std::wstring g_loadedFile;
std::wstring g_loadedFileMUN;
std::wstring g_loadedFileMUI;

std::wstring g_originalFile;
std::wstring g_originalFileMUN;
std::wstring g_originalFileMUI;

std::wstring g_customCertPath = L"";

#define ORIGIN_BASE 0
#define ORIGIN_MUN  1
#define ORIGIN_MUI  2

void LoadTargetPE(HWND hwnd, const std::wstring& path);

HWND g_hwndMain = NULL;
HWND g_hwndToolBar = NULL;
HWND g_hwndRebar = NULL;
HWND g_hwndInset = NULL;
HWND g_hwndEditFile = NULL;
HWND g_hwndBtnBrowse = NULL;
HWND g_hwndListBox = NULL;
HWND g_hwndBtnList = NULL;
HWND g_hwndBtnReplace = NULL;
HWND g_hwndBtnExtract = NULL;
HWND g_hwndBtnDelete = NULL;
HWND g_hwndBtnAdd = NULL;
HWND g_hwndBtnOkay = NULL;
HWND g_hwndBtnCancel = NULL;
HWND g_hwndBtnSettings = NULL;
HWND g_hwndLogsLink = NULL;
HWND g_hwndStatus = NULL;
HWND g_hwndTextPreview = NULL;
HWND g_hwndBtnSaveResource = NULL;
HWND g_hwndBtnPlayWav = NULL;
HFONT g_hLinkFont = NULL;
HICON g_hAppIconLarge = NULL;
HICON g_hAppIconSmall = NULL;

int g_treeWidth = 220;
int g_treeIconSize = 16;
bool g_bDraggingSplitter = false;

bool GetSelectedResourceInfo(HWND hwnd, std::wstring& outType, std::wstring& outName, std::wstring& outLang, int* outOrigin = nullptr);
std::wstring GetFileFromOrigin(int origin);
HIMAGELIST g_hImageListTV = NULL;
void GuiListResources(const std::wstring& path, HWND hwndTV);

std::wstring ParseResourceToText(LPCWSTR typeId, void* data, DWORD size) {
    if (size == 0 || !data) return L"";
    
    // Check if typeId is an integer resource type
    bool isIntResource = IS_INTRESOURCE(typeId);
    
    if (isIntResource && ((ULONG_PTR)typeId == (ULONG_PTR)RT_VERSION || (ULONG_PTR)typeId == (ULONG_PTR)RT_STRING || (ULONG_PTR)typeId == (ULONG_PTR)RT_DIALOG || (ULONG_PTR)typeId == (ULONG_PTR)RT_MENU || (ULONG_PTR)typeId == (ULONG_PTR)RT_MESSAGETABLE)) {
        std::wstring out;
        wchar_t* ptr = (wchar_t*)data;
        DWORD wchars = size / 2;
        std::wstring currentStr;
        for (DWORD i = 0; i < wchars; ++i) {
            wchar_t c = ptr[i];
            if ((c >= 32 && c <= 126) || c > 127 || c == L'\t' || c == L'\n' || c == L'\r') { // Preserve basic formatting and printables
                currentStr += c;
            } else {
                if (currentStr.length() >= 3) {
                    out += currentStr + L"\r\n";
                }
                currentStr.clear();
            }
        }
        if (currentStr.length() >= 3) out += currentStr + L"\r\n";
        if (out.empty()) out = L"(Binary data, no strings found)";
        return out;
    } else if (isIntResource && ((ULONG_PTR)typeId == (ULONG_PTR)RT_MANIFEST || (ULONG_PTR)typeId == (ULONG_PTR)RT_HTML)) {
        int wLen = MultiByteToWideChar(CP_UTF8, 0, (char*)data, size, NULL, 0);
        std::wstring out(wLen, 0);
        MultiByteToWideChar(CP_UTF8, 0, (char*)data, size, &out[0], wLen);
        return out;
    }
    
    // Fallback: Hex Dump for unknown binary data to prevent Mojibake
    std::wstring out;
    unsigned char* p = (unsigned char*)data;
    wchar_t buf[256];
    for (DWORD i = 0; i < size && i < 4096; i += 16) {
        swprintf(buf, 256, L"%08X  ", i);
        out += buf;
        for (DWORD j = 0; j < 16; ++j) {
            if (i + j < size) {
                swprintf(buf, 256, L"%02X ", p[i + j]);
                out += buf;
            } else {
                out += L"   ";
            }
        }
        out += L" ";
        for (DWORD j = 0; j < 16; ++j) {
            if (i + j < size) {
                unsigned char c = p[i + j];
                if (c >= 32 && c <= 126) {
                    out += (wchar_t)c;
                } else {
                    out += L".";
                }
            }
        }
        out += L"\r\n";
    }
    if (size > 4096) {
        out += L"\r\n... (Truncated for preview) ...\r\n";
    }
    return out;
}

struct ToolbarBtnConfig {
    int idCommand;
    int iBitmap;
    std::wstring defaultLabel;
    std::wstring customLabel;
    bool visible;
    bool showLabel;
};
extern ToolbarBtnConfig g_toolbarBtns[7];
extern bool g_bToolbarLocked;
extern HWND g_hwndToolBar;
extern HWND g_hwndRebar;

void BuildToolbar();

bool LoadSettings(HWND hwnd) {
    HKEY hKey;
    bool loaded = false;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\EliteSoftware\\ResourceAlchemyHacker", 0, KEY_READ, &hKey) == ERROR_SUCCESS) {
        DWORD type, size;
        
        size = sizeof(g_treeWidth);
        RegQueryValueExW(hKey, L"TreeWidth", NULL, &type, (LPBYTE)&g_treeWidth, &size);
        size = sizeof(g_bToolbarLocked);
        RegQueryValueExW(hKey, L"ToolbarLocked", NULL, &type, (LPBYTE)&g_bToolbarLocked, &size);
        size = sizeof(g_treeIconSize);
        if (RegQueryValueExW(hKey, L"TreeIconSize", NULL, &type, (LPBYTE)&g_treeIconSize, &size) != ERROR_SUCCESS) {
            g_treeIconSize = 16;
        }
        
        WINDOWPLACEMENT wp = { sizeof(wp) };
        size = sizeof(wp);
        if (RegQueryValueExW(hKey, L"WindowPlacement", NULL, &type, (LPBYTE)&wp, &size) == ERROR_SUCCESS) {
            SetWindowPlacement(hwnd, &wp);
            loaded = true;
        }
        for (int i=0; i<7; i++) {
            std::wstring prefix = L"TB_" + std::to_wstring(i) + L"_";
            DWORD vis = 1;
            DWORD showLbl = 1;
            size = sizeof(vis);
            if (RegQueryValueExW(hKey, (prefix + L"Vis").c_str(), NULL, &type, (LPBYTE)&vis, &size) == ERROR_SUCCESS) {
                g_toolbarBtns[i].visible = (vis != 0);
            }
            size = sizeof(showLbl);
            if (RegQueryValueExW(hKey, (prefix + L"ShowLbl").c_str(), NULL, &type, (LPBYTE)&showLbl, &size) == ERROR_SUCCESS) {
                g_toolbarBtns[i].showLabel = (showLbl != 0);
            }
            wchar_t label[256] = {0};
            size = sizeof(label);
            if (RegQueryValueExW(hKey, (prefix + L"Label").c_str(), NULL, &type, (LPBYTE)label, &size) == ERROR_SUCCESS) {
                g_toolbarBtns[i].customLabel = label;
            }
        }
        RegCloseKey(hKey);
    }
    return loaded;
}

void SaveSettings(HWND hwnd) {
    HKEY hKey;
    if (RegCreateKeyExW(HKEY_CURRENT_USER, L"Software\\EliteSoftware\\ResourceAlchemyHacker", 0, NULL, 0, KEY_WRITE, NULL, &hKey, NULL) == ERROR_SUCCESS) {
        WINDOWPLACEMENT wp = { sizeof(wp) };
        if (GetWindowPlacement(hwnd, &wp)) {
            RegSetValueExW(hKey, L"WindowPlacement", 0, REG_BINARY, (LPBYTE)&wp, sizeof(wp));
        }
        RegSetValueExW(hKey, L"TreeWidth", 0, REG_DWORD, (LPBYTE)&g_treeWidth, sizeof(g_treeWidth));
        RegSetValueExW(hKey, L"TreeIconSize", 0, REG_DWORD, (LPBYTE)&g_treeIconSize, sizeof(g_treeIconSize));
        RegSetValueExW(hKey, L"ToolbarLocked", 0, REG_DWORD, (LPBYTE)&g_bToolbarLocked, sizeof(g_bToolbarLocked));
        for (int i=0; i<7; i++) {
            std::wstring prefix = L"TB_" + std::to_wstring(i) + L"_";
            DWORD vis = g_toolbarBtns[i].visible ? 1 : 0;
            DWORD showLbl = g_toolbarBtns[i].showLabel ? 1 : 0;
            RegSetValueExW(hKey, (prefix + L"Vis").c_str(), 0, REG_DWORD, (LPBYTE)&vis, sizeof(vis));
            RegSetValueExW(hKey, (prefix + L"ShowLbl").c_str(), 0, REG_DWORD, (LPBYTE)&showLbl, sizeof(showLbl));
            if (!g_toolbarBtns[i].customLabel.empty()) {
                RegSetValueExW(hKey, (prefix + L"Label").c_str(), 0, REG_SZ, (LPBYTE)g_toolbarBtns[i].customLabel.c_str(), (g_toolbarBtns[i].customLabel.length() + 1) * sizeof(wchar_t));
            } else {
                RegDeleteValueW(hKey, (prefix + L"Label").c_str());
            }
        }
        RegCloseKey(hKey);
    }
}

ToolbarBtnConfig g_toolbarBtns[7] = {
    { 5101, 0, L"Open PE", L"", true, true }, // IDM_FILE_OPEN
    { 5102, 1, L"Save Hacks", L"", true, true }, // IDM_FILE_SAVE
    { 5103, 2, L"Save Copy", L"", true, true }, // IDM_FILE_SAVEAS
    { 205, 3, L"Replace", L"", true, true }, // IDC_BTN_REPLACE
    { 212, 4, L"Delete", L"", true, true }, // IDC_BTN_DELETE
    { 2000, 5, L"Demo File!", L"", true, true }, // IDM_TEST_LOAD
    { 5308, 6, L"Compile", L"", true, true }
};
bool g_bToolbarLocked = false;

void BuildToolbar() {
    int count = SendMessageW(g_hwndToolBar, TB_BUTTONCOUNT, 0, 0);
    for (int i = count - 1; i >= 0; i--) {
        SendMessageW(g_hwndToolBar, TB_DELETEBUTTON, i, 0);
    }
    std::vector<TBBUTTON> tbb;
    for (int i=0; i<7; i++) {
        if (g_toolbarBtns[i].visible) {
            TBBUTTON b = {0};
            b.iBitmap = g_toolbarBtns[i].iBitmap;
            b.idCommand = g_toolbarBtns[i].idCommand;
            b.fsState = TBSTATE_ENABLED;
            b.fsStyle = BTNS_BUTTON | BTNS_AUTOSIZE;
            if (g_toolbarBtns[i].showLabel) b.fsStyle |= BTNS_SHOWTEXT;
            b.iString = (INT_PTR)(g_toolbarBtns[i].customLabel.empty() ? g_toolbarBtns[i].defaultLabel.c_str() : g_toolbarBtns[i].customLabel.c_str());
            tbb.push_back(b);
        }
    }
    if (!tbb.empty()) {
        SendMessageW(g_hwndToolBar, TB_ADDBUTTONSW, tbb.size(), (LPARAM)tbb.data());
    }
    SendMessageW(g_hwndToolBar, TB_AUTOSIZE, 0, 0);
    
    REBARBANDINFOW rbbi = { sizeof(REBARBANDINFOW), RBBIM_STYLE | RBBIM_CHILDSIZE | RBBIM_SIZE };
    SendMessageW(g_hwndRebar, RB_GETBANDINFOW, 0, (LPARAM)&rbbi);
    if (g_bToolbarLocked) rbbi.fStyle |= RBBS_NOGRIPPER;
    else rbbi.fStyle &= ~RBBS_NOGRIPPER;
    SIZE size;
    SendMessageW(g_hwndToolBar, TB_GETMAXSIZE, 0, (LPARAM)&size);
    rbbi.cxMinChild = size.cx;
    rbbi.cyMinChild = size.cy;
    rbbi.cx = size.cx;
    SendMessageW(g_hwndRebar, RB_SETBANDINFOW, 0, (LPARAM)&rbbi);
}

LRESULT CALLBACK CustomizeToolbarDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    static HWND hListAvail, hListCurr, hText, hCheckShow, hBtnAdd, hBtnRemove;
    static int selectedIdx = -1; // Index in g_toolbarBtns (0..6)
    
    auto RefreshLists = [&]() {
        SendMessageW(hListAvail, LB_RESETCONTENT, 0, 0);
        SendMessageW(hListCurr, LB_RESETCONTENT, 0, 0);
        for (int i=0; i<7; i++) {
            HWND targetList = g_toolbarBtns[i].visible ? hListCurr : hListAvail;
            int pos = SendMessageW(targetList, LB_ADDSTRING, 0, (LPARAM)g_toolbarBtns[i].defaultLabel.c_str());
            SendMessageW(targetList, LB_SETITEMDATA, pos, i);
        }
    };
    
    switch (uMsg) {
    case WM_CREATE:
        {
            CreateWindowW(L"STATIC", L"Available Buttons:", WS_CHILD | WS_VISIBLE, 10, 10, 150, 20, hwnd, NULL, NULL, NULL);
            hListAvail = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", NULL, WS_CHILD | WS_VISIBLE | LBS_NOTIFY | WS_VSCROLL, 10, 30, 150, 150, hwnd, (HMENU)101, NULL, NULL);
            
            hBtnAdd = CreateWindowW(L"BUTTON", L"Add ->", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 170, 70, 80, 25, hwnd, (HMENU)104, NULL, NULL);
            hBtnRemove = CreateWindowW(L"BUTTON", L"<- Remove", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 170, 105, 80, 25, hwnd, (HMENU)105, NULL, NULL);

            CreateWindowW(L"STATIC", L"Current Toolbar:", WS_CHILD | WS_VISIBLE, 260, 10, 150, 20, hwnd, NULL, NULL, NULL);
            hListCurr = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", NULL, WS_CHILD | WS_VISIBLE | LBS_NOTIFY | WS_VSCROLL, 260, 30, 150, 150, hwnd, (HMENU)106, NULL, NULL);

            CreateWindowW(L"STATIC", L"Custom Label:", WS_CHILD | WS_VISIBLE, 10, 195, 100, 20, hwnd, NULL, NULL, NULL);
            hText = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"", WS_CHILD | WS_VISIBLE | WS_TABSTOP | ES_AUTOHSCROLL, 110, 190, 140, 25, hwnd, (HMENU)102, NULL, NULL);
            
            hCheckShow = CreateWindowW(L"BUTTON", L"Show Text Label", WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX, 260, 192, 150, 20, hwnd, (HMENU)103, NULL, NULL);
            
            CreateWindowW(L"BUTTON", L"Done!", WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON, 330, 240, 80, 30, hwnd, (HMENU)IDOK, NULL, NULL);
            
            RefreshLists();

            HFONT hFont = CreateFontW(14, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            SendMessageW(hwnd, WM_SETFONT, (WPARAM)hFont, TRUE);
            EnumChildWindows(hwnd, [](HWND child, LPARAM param) -> BOOL {
                SendMessageW(child, WM_SETFONT, param, TRUE); return TRUE;
            }, (LPARAM)hFont);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            int wmEvent = HIWORD(wParam);
            if ((wmId == 101 || wmId == 106) && wmEvent == LBN_SELCHANGE) {
                HWND hList = (wmId == 101) ? hListAvail : hListCurr;
                int sel = SendMessageW(hList, LB_GETCURSEL, 0, 0);
                if (sel >= 0) {
                    selectedIdx = SendMessageW(hList, LB_GETITEMDATA, sel, 0);
                    SetWindowTextW(hText, g_toolbarBtns[selectedIdx].customLabel.c_str());
                    SendMessageW(hCheckShow, BM_SETCHECK, g_toolbarBtns[selectedIdx].showLabel ? BST_CHECKED : BST_UNCHECKED, 0);
                }
            }
            else if (wmId == 102 && wmEvent == EN_CHANGE) {
                if (selectedIdx >= 0 && selectedIdx < 7) {
                    wchar_t buf[256] = {0};
                    GetWindowTextW(hText, buf, 256);
                    g_toolbarBtns[selectedIdx].customLabel = buf;
                }
            }
            else if (wmId == 103 && wmEvent == BN_CLICKED) {
                if (selectedIdx >= 0 && selectedIdx < 7) {
                    g_toolbarBtns[selectedIdx].showLabel = (SendMessageW(hCheckShow, BM_GETCHECK, 0, 0) == BST_CHECKED);
                }
            }
            else if (wmId == 104) {
                int sel = SendMessageW(hListAvail, LB_GETCURSEL, 0, 0);
                if (sel >= 0) {
                    int realIdx = SendMessageW(hListAvail, LB_GETITEMDATA, sel, 0);
                    g_toolbarBtns[realIdx].visible = true;
                    RefreshLists();
                }
            }
            else if (wmId == 105) {
                int sel = SendMessageW(hListCurr, LB_GETCURSEL, 0, 0);
                if (sel >= 0) {
                    int realIdx = SendMessageW(hListCurr, LB_GETITEMDATA, sel, 0);
                    g_toolbarBtns[realIdx].visible = false;
                    RefreshLists();
                }
            }
            else if (wmId == IDOK || wmId == IDCANCEL) {
                BuildToolbar();
                SaveSettings(GetParent(hwnd));
                DestroyWindow(hwnd);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect; GetClientRect(hwnd, &rect);
            FillRect(hdc, &rect, GetSysColorBrush(COLOR_BTNFACE));
            RECT chinRect = rect; chinRect.top = rect.bottom - 45;
            FillRect(hdc, &chinRect, GetSysColorBrush(COLOR_3DSHADOW));
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}



void EliteLog(const std::wstring& msg) {
    wchar_t sysDrive[MAX_PATH];
    GetEnvironmentVariableW(L"SystemDrive", sysDrive, MAX_PATH);
    std::wstring logDir = std::wstring(sysDrive) + L"\\EliteSoftware\\Logs";
    CreateDirectoryW((std::wstring(sysDrive) + L"\\EliteSoftware").c_str(), NULL);
    CreateDirectoryW(logDir.c_str(), NULL);
    std::wstring logFile = logDir + L"\\ResourceAlchemist.log";
    
    SYSTEMTIME st;
    GetLocalTime(&st);
    
    std::wofstream out(std::filesystem::path(logFile), std::ios::app);
    if (out.is_open()) {
        out << L"[" << std::setfill(L'0') << std::setw(4) << st.wYear << L"-" << std::setw(2) << st.wMonth << L"-" << std::setw(2) << st.wDay
            << L" " << std::setw(2) << st.wHour << L":" << std::setw(2) << st.wMinute << L":" << std::setw(2) << st.wSecond << L"] "
            << msg << std::endl;
    }
}

void LogWin32Error(const std::wstring& context, DWORD errCode = GetLastError()) {
    std::wstring witty;
    switch (errCode) {
        case ERROR_ACCESS_DENIED: witty = L"Windows slammed the door in our face. Are you running as Admin, or just pretending?"; break;
        case ERROR_SHARING_VIOLATION: witty = L"The file is currently being held hostage by another process. Kill it and try again."; break;
        case ERROR_FILE_NOT_FOUND: witty = L"File not found. Did it vanish into the void, or did you make a typo?"; break;
        case ERROR_RESOURCE_DATA_NOT_FOUND: witty = L"Resource not found. You're hunting ghosts in this PE file."; break;
        default: witty = L"A technical anomaly occurred. Blame the gremlins."; break;
    }
    std::wstringstream ss;
    ss << context << L" - Error " << errCode << L": " << witty;
    EliteLog(ss.str());
}

std::wstring GetResIdOrName(LPCWSTR val) {
    if (IS_INTRESOURCE(val)) {
        return std::to_wstring((USHORT)(ULONG_PTR)val);
    }
    return std::wstring(val);
}

// Icon Loading
void LoadDynamicIcon(HINSTANCE hInstance) {
    HMODULE hExe = GetModuleHandleW(NULL);
    g_hAppIconLarge = (HICON)LoadImageW(hExe, MAKEINTRESOURCEW(1), IMAGE_ICON, GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), 0);
    g_hAppIconSmall = (HICON)LoadImageW(hExe, MAKEINTRESOURCEW(1), IMAGE_ICON, GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0);

    if (!g_hAppIconLarge) g_hAppIconLarge = LoadIconW(NULL, IDI_APPLICATION);
    if (!g_hAppIconSmall) g_hAppIconSmall = LoadIconW(NULL, IDI_APPLICATION);
}

// Tooltips
HWND CreateToolTip(HWND hwndParent, HWND hwndControl, const wchar_t* text) {
    HWND hwndTip = CreateWindowExW(NULL, TOOLTIPS_CLASSW, NULL,
        WS_POPUP | TTS_ALWAYSTIP,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
        hwndParent, NULL, (HINSTANCE)GetWindowLongPtrW(hwndParent, GWLP_HINSTANCE), NULL);
        
    if (!hwndTip) return NULL;
    
    TOOLINFOW toolInfo = { 0 };
    toolInfo.cbSize = sizeof(toolInfo);
    toolInfo.hwnd = hwndParent;
    toolInfo.uFlags = TTF_IDISHWND | TTF_SUBCLASS;
    toolInfo.uId = (UINT_PTR)hwndControl;
    toolInfo.lpszText = const_cast<wchar_t*>(text);
    
    SendMessageW(hwndTip, TTM_ADDTOOLW, 0, (LPARAM)&toolInfo);
    return hwndTip;
}

// Inset Windows Procedure
LRESULT CALLBACK InsetWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            
            HWND hEdit = GetDlgItem(hwnd, IDC_TARGET_FILE);
            if (hEdit) SetWindowPos(hEdit, NULL, 15, 38, width - 110, 23, SWP_NOZORDER);
            
            HWND hBrowse = GetDlgItem(hwnd, IDC_BTN_BROWSE);
            if (hBrowse) SetWindowPos(hBrowse, NULL, width - 85, 37, 70, 25, SWP_NOZORDER);
            
            HWND hBtnList = GetDlgItem(hwnd, IDC_BTN_LIST);
            if (hBtnList) SetWindowPos(hBtnList, NULL, 15, 70, 120, 25, SWP_NOZORDER);
            
            HWND hBtnReplace = GetDlgItem(hwnd, IDC_BTN_REPLACE);
            if (hBtnReplace) SetWindowPos(hBtnReplace, NULL, 145, 70, 140, 25, SWP_NOZORDER);
            
            HWND hBtnExtract = GetDlgItem(hwnd, IDC_BTN_EXTRACT);
            if (hBtnExtract) SetWindowPos(hBtnExtract, NULL, 295, 70, 140, 25, SWP_NOZORDER);
            
            HWND hBtnDelete = GetDlgItem(hwnd, IDC_BTN_DELETE);
            if (hBtnDelete) SetWindowPos(hBtnDelete, NULL, 445, 70, 130, 25, SWP_NOZORDER);
            
            HWND hBtnAdd = GetDlgItem(hwnd, IDC_BTN_ADD);
            if (hBtnAdd) SetWindowPos(hBtnAdd, NULL, 585, 70, 130, 25, SWP_NOZORDER);
            
            HWND hList = GetDlgItem(hwnd, IDC_LST_RESOURCES);
            HWND hPreview = GetDlgItem(hwnd, IDC_IMG_PREVIEW);
            if (hList && hPreview) {
                int topY = 105;
                int panesHeight = height - topY - 15;
                if (panesHeight < 50) panesHeight = 50;
                
                if (g_treeWidth > width - 100) g_treeWidth = width - 100;
                if (g_treeWidth < 100) g_treeWidth = 100;
                
                int previewWidth = width - g_treeWidth - 40;
                if (previewWidth < 50) previewWidth = 50;
                
                SetWindowPos(hList, NULL, 15, topY, g_treeWidth, panesHeight, SWP_NOZORDER);
                SetWindowPos(hPreview, NULL, 15 + g_treeWidth + 10, topY, previewWidth, panesHeight, SWP_NOZORDER);
                if (g_hwndTextPreview) SetWindowPos(g_hwndTextPreview, NULL, 15 + g_treeWidth + 10, topY, previewWidth, panesHeight - 35, SWP_NOZORDER);
                if (g_hwndBtnSaveResource) SetWindowPos(g_hwndBtnSaveResource, NULL, 15 + g_treeWidth + 10, topY + panesHeight - 30, 100, 25, SWP_NOZORDER);
                if (g_hwndBtnPlayWav) SetWindowPos(g_hwndBtnPlayWav, NULL, 15 + g_treeWidth + 10 + 110, topY + panesHeight - 30, 100, 25, SWP_NOZORDER);
            }
        }
        break;
    case WM_MOUSEMOVE:
        {
            int x = GET_X_LPARAM(lParam);
            int y = GET_Y_LPARAM(lParam);
            if (g_bDraggingSplitter) {
                RECT rc;
                GetClientRect(hwnd, &rc);
                g_treeWidth = x - 15 - 5;
                if (g_treeWidth < 100) g_treeWidth = 100;
                if (g_treeWidth > rc.right - 100) g_treeWidth = rc.right - 100;
                SendMessageW(hwnd, WM_SIZE, 0, MAKELPARAM(rc.right, rc.bottom));
                InvalidateRect(hwnd, NULL, TRUE);
            } else {
                if (x > 15 + g_treeWidth && x < 15 + g_treeWidth + 10 && y > 105) {
                    SetCursor(LoadCursor(NULL, IDC_SIZEWE));
                }
            }
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    case WM_LBUTTONDOWN:
        {
            int x = GET_X_LPARAM(lParam);
            int y = GET_Y_LPARAM(lParam);
            if (x > 15 + g_treeWidth && x < 15 + g_treeWidth + 10 && y > 105) {
                g_bDraggingSplitter = true;
                SetCapture(hwnd);
            }
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    case WM_LBUTTONUP:
        if (g_bDraggingSplitter) {
            g_bDraggingSplitter = false;
            ReleaseCapture();
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SETCURSOR:
        {
            if (LOWORD(lParam) == HTCLIENT) {
                POINT pt;
                GetCursorPos(&pt);
                ScreenToClient(hwnd, &pt);
                if (pt.x > 15 + g_treeWidth && pt.x < 15 + g_treeWidth + 10 && pt.y > 105) {
                    SetCursor(LoadCursor(NULL, IDC_SIZEWE));
                    return TRUE;
                }
            }
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
        }
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORSTATIC:
        {
            static HBRUSH hInsetBg = CreateSolidBrush(RGB(220, 220, 225));
            SetBkMode((HDC)wParam, TRANSPARENT);
            return (INT_PTR)hInsetBg;
        }
    case WM_DRAWITEM:
        {
            DRAWITEMSTRUCT* dis = (DRAWITEMSTRUCT*)lParam;
            if (dis->CtlID == IDC_IMG_PREVIEW) {
                FillRect(dis->hDC, &dis->rcItem, (HBRUSH)(COLOR_WINDOW + 1));
                HWND hTree = GetDlgItem(hwnd, IDC_LST_RESOURCES);
                if (hTree) {
                    HTREEITEM hSel = (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_CARET, 0);
                    if (hSel) {
                        wchar_t buf[256];
                        TVITEMW tvi = { 0 };
                        tvi.hItem = hSel;
                        tvi.mask = TVIF_IMAGE | TVIF_TEXT;
                        tvi.pszText = buf;
                        tvi.cchTextMax = 256;
                        SendMessageW(hTree, TVM_GETITEMW, 0, (LPARAM)&tvi);
                        if (true) { 
                                std::wstring rType, rName, rLang;
                                int rOrigin = 0;
                                if (GetSelectedResourceInfo(hwnd, rType, rName, rLang, &rOrigin) && !rName.empty()) {
                                    extern std::wstring g_loadedFile;
                                    std::wstring originFile = GetFileFromOrigin(rOrigin);
                                    HMODULE hMod = LoadLibraryExW(originFile.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                                    if (hMod) {
                                        LPCWSTR id = rName.c_str();
                                    if (rName.find(L"#") == 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str() + 1));
                                    else if (_wtoi(rName.c_str()) != 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str()));
                                    
                                    LPCWSTR typeId = rType.c_str();
                                    if (rType.find(L"#") == 0) typeId = MAKEINTRESOURCEW(_wtoi(rType.c_str() + 1));
                                    
                                    int maxY = 10;
                                    if (rType == L"#14" || rType == L"#3" || rType == L"#12" || rType == L"#1" || rType == L"21") { // Icon Group, Icon, Cursor Group, Cursor, ANI Cursor
                                        int sizes[] = { 16, 24, 32, 48, 64, 128, 256 };
                                        int x = 10;
                                        UINT imgType = (rType == L"#14" || rType == L"#3") ? IMAGE_ICON : IMAGE_CURSOR;
                                        for (int s : sizes) {
                                            HICON hIco = (HICON)LoadImageW(hMod, id, imgType, s, s, 0);
                                            if (hIco) {
                                                DrawIconEx(dis->hDC, x, 10, hIco, s, s, 0, NULL, DI_NORMAL);
                                                x += s + 10;
                                                if (10 + s > maxY) maxY = 10 + s;
                                                DestroyIcon(hIco);
                                            }
                                        }
                                    } else if (rType == L"#2") { // Bitmap
                                        HBITMAP hBmp = (HBITMAP)LoadImageW(hMod, id, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
                                        if (hBmp) {
                                            HDC hdcMem = CreateCompatibleDC(dis->hDC);
                                            SelectObject(hdcMem, hBmp);
                                            BITMAP bm;
                                            GetObject(hBmp, sizeof(bm), &bm);
                                            BitBlt(dis->hDC, 10, 10, bm.bmWidth, bm.bmHeight, hdcMem, 0, 0, SRCCOPY);
                                            DeleteDC(hdcMem);
                                            DeleteObject(hBmp);
                                            if (10 + bm.bmHeight > maxY) maxY = 10 + bm.bmHeight;
                                        }
                                    } else if (rType == L"PNG" || rType == L"IMAGE" || typeId == MAKEINTRESOURCEW(2110)) {
                                        HRSRC hRes = FindResourceExW(hMod, typeId, id, _wtoi(rLang.c_str()));
                                        if (hRes) {
                                            DWORD size = SizeofResource(hMod, hRes);
                                            HGLOBAL hData = LoadResource(hMod, hRes);
                                            if (hData) {
                                                void* ptr = LockResource(hData);
                                                IStream* pStream = NULL;
                                                HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, size);
                                                if (hMem) {
                                                    void* pMem = GlobalLock(hMem);
                                                    memcpy(pMem, ptr, size);
                                                    GlobalUnlock(hMem);
                                                    CreateStreamOnHGlobal(hMem, TRUE, &pStream);
                                                    if (pStream) {
                                                        Gdiplus::Image image(pStream);
                                                        Gdiplus::Graphics graphics(dis->hDC);
                                                        graphics.DrawImage(&image, 10, 10, image.GetWidth(), image.GetHeight());
                                                        if (10 + (int)image.GetHeight() > maxY) maxY = 10 + image.GetHeight();
                                                        pStream->Release();
                                                    }
                                                    GlobalFree(hMem);
                                                }
                                            }
                                        }
                                    } else if (rType == L"WAVE" || rType == L"WAV") {
                                        std::wstring playingMsg = L"[Use the Play Audio button below to preview this sound]";
                                        SetTextColor(dis->hDC, RGB(0, 120, 215));
                                        SetBkMode(dis->hDC, TRANSPARENT);
                                        TextOutW(dis->hDC, 10, maxY, playingMsg.c_str(), playingMsg.length());
                                        maxY += 25;
                                    }

                                    HRSRC hRes = FindResourceExW(hMod, typeId, id, _wtoi(rLang.c_str()));
                                    if (hRes) {
                                        DWORD size = SizeofResource(hMod, hRes);
                                        std::wstring info = L"Resource Type: " + rType + L"\r\nResource Name: " + rName + L"\r\nLanguage: " + rLang + L"\r\nSize: " + std::to_wstring(size) + L" bytes";
                                        if (maxY <= 10) info += L"\r\n\r\n(Raw Data Preview not natively supported for this binary type yet)";
                                        SetTextColor(dis->hDC, RGB(30, 30, 30));
                                        SetBkMode(dis->hDC, TRANSPARENT);
                                        RECT textRc = dis->rcItem;
                                        textRc.left += 10;
                                        textRc.top = maxY + 15;
                                        HFONT hFont = CreateFontW(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
                                        HGDIOBJ hOld = SelectObject(dis->hDC, hFont);
                                        DrawTextW(dis->hDC, info.c_str(), -1, &textRc, DT_LEFT | DT_TOP | DT_WORDBREAK);
                                        SelectObject(dis->hDC, hOld);
                                        DeleteObject(hFont);
                                    }
                                }
                                FreeLibrary(hMod);
                            }
                        }
                    }
                }
            }
        }
        return TRUE;
    case WM_CONTEXTMENU:
        {
            HWND hTree = GetDlgItem(hwnd, IDC_LST_RESOURCES);
            if ((HWND)wParam == hTree) {
                POINT pt = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
                POINT ptClient = pt;
                ScreenToClient(hTree, &ptClient);
                TVHITTESTINFO ht = { 0 };
                ht.pt = ptClient;
                TreeView_HitTest(hTree, &ht);
                if (ht.flags & (TVHT_ONITEM | TVHT_ONITEMINDENT | TVHT_ONITEMRIGHT)) {
                    TreeView_SelectItem(hTree, ht.hItem);
                    
                    HMENU hMenu = CreatePopupMenu();
                    AppendMenuW(hMenu, MF_STRING, 5001, L"Extract Resource...");
                    AppendMenuW(hMenu, MF_STRING, 5002, L"Delete Resource");
                    
                    int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, NULL);
                    DestroyMenu(hMenu);
                    
                    if (cmd == 5001) {
                        SendMessageW(GetParent(hwnd), WM_COMMAND, MAKEWPARAM(IDC_BTN_EXTRACT, BN_CLICKED), 0);
                    } else if (cmd == 5002) {
                        SendMessageW(GetParent(hwnd), WM_COMMAND, MAKEWPARAM(IDC_BTN_DELETE, BN_CLICKED), 0);
                    }
                }
            }
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BTN_SAVE_RESOURCE) {
            SendMessageW(GetParent(hwnd), WM_COMMAND, MAKEWPARAM(IDC_BTN_EXTRACT, BN_CLICKED), 0);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
        if (LOWORD(wParam) == IDC_BTN_PLAY_WAV) {
            std::wstring rType, rName, rLang;
            int rOrigin = 0;
            if (GetSelectedResourceInfo(hwnd, rType, rName, rLang, &rOrigin) && !rName.empty() && (rType == L"WAVE" || rType == L"AVI")) {
                HMODULE hMod = LoadLibraryExW(GetFileFromOrigin(rOrigin).c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                if (hMod) {
                    LPCWSTR id = rName.c_str();
                    if (rName.find(L"#") == 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str() + 1));
                    else if (_wtoi(rName.c_str()) != 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str()));
                    HRSRC hRes = FindResourceExW(hMod, rType.c_str(), id, _wtoi(rLang.c_str()));
                    if (hRes) {
                        HGLOBAL hGlob = LoadResource(hMod, hRes);
                        if (hGlob) {
                            void* data = LockResource(hGlob);
                            if (rType == L"WAVE") {
                                PlaySoundW((LPCWSTR)data, NULL, SND_MEMORY | SND_ASYNC | SND_NODEFAULT);
                            } else {
                                DWORD size = SizeofResource(hMod, hRes);
                                wchar_t tempPath[MAX_PATH];
                                GetTempPathW(MAX_PATH, tempPath);
                                std::wstring aviFile = std::wstring(tempPath) + L"ResourceAlchemyTemp.avi";
                                std::ofstream out(aviFile, std::ios::binary);
                                out.write((char*)data, size);
                                out.close();
                                ShellExecuteW(NULL, L"open", aviFile.c_str(), NULL, NULL, SW_SHOWNORMAL);
                            }
                        }
                    }
                    FreeLibrary(hMod);
                }
            }
            if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
            return 0;
        }
        return SendMessageW(GetParent(hwnd), uMsg, wParam, lParam);
    case WM_NOTIFY:
        {
            LPNMHDR nmhdr = (LPNMHDR)lParam;
            if (nmhdr->idFrom == IDC_LST_RESOURCES && nmhdr->code == TVN_ITEMEXPANDINGW) {
                NMTREEVIEWW* pnmtv = (NMTREEVIEWW*)lParam;
                if (pnmtv->action == TVE_EXPAND) {
                    HWND hTree = GetDlgItem(hwnd, IDC_LST_RESOURCES);
                    HTREEITEM hChild = (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_CHILD, (LPARAM)pnmtv->itemNew.hItem);
                    
                    HMODULE hMods[3] = {0};
                    extern std::wstring g_loadedFile, g_loadedFileMUN, g_loadedFileMUI;
                    if (!g_loadedFile.empty()) hMods[ORIGIN_BASE] = LoadLibraryExW(g_loadedFile.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                    if (!g_loadedFileMUN.empty()) hMods[ORIGIN_MUN] = LoadLibraryExW(g_loadedFileMUN.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                    if (!g_loadedFileMUI.empty()) hMods[ORIGIN_MUI] = LoadLibraryExW(g_loadedFileMUI.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                    
                    wchar_t parentText[256];
                    TVITEMW tviParent = {0};
                    tviParent.hItem = pnmtv->itemNew.hItem;
                    tviParent.mask = TVIF_TEXT;
                    tviParent.pszText = parentText;
                    tviParent.cchTextMax = 256;
                    SendMessageW(hTree, TVM_GETITEMW, 0, (LPARAM)&tviParent);
                    
                    LPCWSTR lpszType = NULL;
                    std::wstring pt(parentText);
                    if (pt == L"Icon Group") lpszType = RT_GROUP_ICON;
                    else if (pt == L"Icon") lpszType = RT_ICON;
                    else if (pt == L"Bitmap") lpszType = RT_BITMAP;
                    
                    if (lpszType != NULL) {
                        while (hChild) {
                            TVITEMW tvi = {0};
                            tvi.hItem = hChild;
                            tvi.mask = TVIF_IMAGE | TVIF_TEXT | TVIF_PARAM;
                            wchar_t buf[256];
                            tvi.pszText = buf;
                            tvi.cchTextMax = 256;
                            SendMessageW(hTree, TVM_GETITEMW, 0, (LPARAM)&tvi);
                            
                            int rOrigin = (int)tvi.lParam;
                            HMODULE hMod = (rOrigin >= 0 && rOrigin <= 2) ? hMods[rOrigin] : NULL;
                            
                            if (hMod && (tvi.iImage == 10 || tvi.iImage == 9 || tvi.iImage == 11)) {
                                std::wstring nameStr = buf;
                                size_t pos = nameStr.rfind(L" (LANG:");
                                if (pos != std::wstring::npos) nameStr = nameStr.substr(0, pos);
                                
                                LPCWSTR id = nameStr.c_str();
                                if (nameStr.find(L"#") == 0) id = MAKEINTRESOURCEW(_wtoi(nameStr.c_str() + 1));
                                else if (_wtoi(nameStr.c_str()) != 0) id = MAKEINTRESOURCEW(_wtoi(nameStr.c_str()));
                                
                                int imgIndex = tvi.iImage;
                                if (lpszType == RT_GROUP_ICON || lpszType == RT_ICON) {
                                    HICON hIcon = (HICON)LoadImageW(hMod, id, IMAGE_ICON, g_treeIconSize, g_treeIconSize, 0);
                                    if (hIcon) {
                                        imgIndex = ImageList_AddIcon(g_hImageListTV, hIcon);
                                        DestroyIcon(hIcon);
                                    }
                                } else if (lpszType == RT_BITMAP) {
                                    HBITMAP hBmp = (HBITMAP)LoadImageW(hMod, id, IMAGE_BITMAP, g_treeIconSize, g_treeIconSize, LR_CREATEDIBSECTION);
                                    if (hBmp) {
                                        imgIndex = ImageList_Add(g_hImageListTV, hBmp, NULL);
                                        DeleteObject(hBmp);
                                    }
                                }
                                if (imgIndex != tvi.iImage) {
                                    tvi.iImage = imgIndex;
                                    tvi.iSelectedImage = imgIndex;
                                    tvi.mask = TVIF_IMAGE | TVIF_SELECTEDIMAGE;
                                    SendMessageW(hTree, TVM_SETITEMW, 0, (LPARAM)&tvi);
                                }
                            }
                            hChild = (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_NEXT, (LPARAM)hChild);
                        }
                    }
                    if (hMods[0]) FreeLibrary(hMods[0]);
                    if (hMods[1]) FreeLibrary(hMods[1]);
                    if (hMods[2]) FreeLibrary(hMods[2]);
                }
            }
            if (nmhdr->idFrom == IDC_LST_RESOURCES && nmhdr->code == TVN_SELCHANGEDW) {
                HWND hPreview = GetDlgItem(hwnd, IDC_IMG_PREVIEW);
                
                std::wstring rType, rName, rLang;
                bool isText = false;
                bool isWav = false;
                int rOrigin = 0;
                
                if (GetSelectedResourceInfo(hwnd, rType, rName, rLang, &rOrigin) && !rName.empty()) {
                    if (rType == L"#4" || rType == L"#5" || rType == L"#6" || rType == L"#11" || rType == L"#16" || rType == L"#24") {
                        isText = true;
                    } else if (rType == L"WAVE") {
                        isWav = true;
                        SetWindowTextW(g_hwndBtnPlayWav, L"Play Audio");
                    } else if (rType == L"AVI") {
                        isWav = true;
                        SetWindowTextW(g_hwndBtnPlayWav, L"Play AVI");
                    }
                }
                
                if (isText) {
                    ShowWindow(hPreview, SW_HIDE);
                    ShowWindow(g_hwndTextPreview, SW_SHOW);
                    ShowWindow(g_hwndBtnSaveResource, SW_SHOW);
                    ShowWindow(g_hwndBtnPlayWav, SW_HIDE);
                    
                    HMODULE hMod = LoadLibraryExW(GetFileFromOrigin(rOrigin).c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                    if (hMod) {
                        LPCWSTR id = rName.c_str();
                        if (rName.find(L"#") == 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str() + 1));
                        else if (_wtoi(rName.c_str()) != 0) id = MAKEINTRESOURCEW(_wtoi(rName.c_str()));
                        LPCWSTR typeId = rType.c_str();
                        if (rType.find(L"#") == 0) typeId = MAKEINTRESOURCEW(_wtoi(rType.c_str() + 1));
                        
                        HRSRC hRes = FindResourceExW(hMod, typeId, id, _wtoi(rLang.c_str()));
                        if (hRes) {
                            HGLOBAL hGlob = LoadResource(hMod, hRes);
                            if (hGlob) {
                                void* data = LockResource(hGlob);
                                DWORD size = SizeofResource(hMod, hRes);
                                if (data && size > 0) {
                                    std::wstring parsedText = ParseResourceToText(typeId, data, size);
                                    SetWindowTextW(g_hwndTextPreview, parsedText.c_str());
                                }
                            }
                        }
                        FreeLibrary(hMod);
                    }
                } else if (isWav) {
                    ShowWindow(hPreview, SW_SHOW);
                    ShowWindow(g_hwndTextPreview, SW_HIDE);
                    ShowWindow(g_hwndBtnSaveResource, SW_HIDE);
                    if (rType == L"WAVE" || rType == L"WAV") {
                        SetWindowTextW(g_hwndBtnPlayWav, L"Play Audio");
                    } else {
                        SetWindowTextW(g_hwndBtnPlayWav, L"Play AVI");
                    }
                    ShowWindow(g_hwndBtnPlayWav, SW_SHOW);
                    BringWindowToTop(g_hwndBtnPlayWav);
                    if (hPreview) InvalidateRect(hPreview, NULL, TRUE);
                } else {
                    ShowWindow(hPreview, SW_SHOW);
                    ShowWindow(g_hwndTextPreview, SW_HIDE);
                    ShowWindow(g_hwndBtnSaveResource, SW_HIDE);
                    ShowWindow(g_hwndBtnPlayWav, SW_HIDE);
                    if (hPreview) InvalidateRect(hPreview, NULL, TRUE);
                }
            }
        }
        return SendMessageW(GetParent(hwnd), uMsg, wParam, lParam);
    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect;
            GetClientRect(hwnd, &rect);
            HBRUSH hBg = CreateSolidBrush(RGB(220, 220, 225));
            FillRect(hdc, &rect, hBg);
            DeleteObject(hBg);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// Custom Modal Dialog Engine
void ShowCustomModalDialog(HWND hwndParent, WNDPROC lpfnWndProc, const wchar_t* title, int width, int height) {
    HINSTANCE hInst = (HINSTANCE)GetWindowLongPtrW(hwndParent, GWLP_HINSTANCE);
    static int classCounter = 0;
    std::wstring className = L"CustomDlgClass_" + std::to_wstring(classCounter++);
    
    WNDCLASSW wc = { 0 };
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = lpfnWndProc;
    wc.hInstance = hInst;
    wc.lpszClassName = className.c_str();
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.hCursor = LoadCursorW(NULL, IDC_ARROW);
    RegisterClassW(&wc);
    
    RECT rectParent;
    GetWindowRect(hwndParent, &rectParent);
    int x = rectParent.left + (rectParent.right - rectParent.left - width) / 2;
    int y = rectParent.top + (rectParent.bottom - rectParent.top - height) / 2;
    
    HWND hwndDlg = CreateWindowExW(WS_EX_DLGMODALFRAME, className.c_str(), title,
        WS_POPUPWINDOW | WS_CAPTION | WS_DLGFRAME | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS,
        x, y, width, height, hwndParent, NULL, hInst, NULL);
        
    if (!hwndDlg) return;
    
    EnableWindow(hwndParent, FALSE);
    
    MSG msg;
    while (IsWindow(hwndDlg) && GetMessageW(&msg, NULL, 0, 0)) {
        if (msg.message == WM_KEYDOWN && msg.wParam == VK_F1) {
            SendMessageW(g_hwndMain, WM_COMMAND, IDM_HELP_CONTENTS, 0);
            continue;
        }
        if (!IsDialogMessageW(hwndDlg, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    
    EnableWindow(hwndParent, TRUE);
    SetActiveWindow(hwndParent);
    UnregisterClassW(className.c_str(), hInst);
}

#define IDC_REPLACE_OLD_PREVIEW 401
#define IDC_REPLACE_NEW_PREVIEW 402
#define IDC_BTN_REPLACE_BROWSE 403

std::wstring g_replaceType, g_replaceName, g_replaceLang;
std::wstring g_replacementFile;
extern std::wstring g_loadedFile;
bool BrowseFile(HWND hwndParent, std::wstring& outPath, const wchar_t* filter);

LRESULT CALLBACK ReplaceDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch(uMsg) {
    case WM_CREATE:
        CreateWindowW(L"STATIC", L"Original Resource:", WS_CHILD | WS_VISIBLE, 20, 20, 150, 20, hwnd, NULL, NULL, NULL);
        CreateWindowExW(WS_EX_CLIENTEDGE, L"STATIC", L"", WS_CHILD | WS_VISIBLE | SS_OWNERDRAW, 20, 40, 200, 200, hwnd, (HMENU)IDC_REPLACE_OLD_PREVIEW, NULL, NULL);
        
        CreateWindowW(L"STATIC", L"New Resource:", WS_CHILD | WS_VISIBLE, 240, 20, 150, 20, hwnd, NULL, NULL, NULL);
        CreateWindowExW(WS_EX_CLIENTEDGE, L"STATIC", L"", WS_CHILD | WS_VISIBLE | SS_OWNERDRAW, 240, 40, 200, 200, hwnd, (HMENU)IDC_REPLACE_NEW_PREVIEW, NULL, NULL);
        
        CreateWindowW(L"BUTTON", L"Open file with new resource...", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 20, 260, 250, 25, hwnd, (HMENU)IDC_BTN_REPLACE_BROWSE, NULL, NULL);
        CreateWindowW(L"BUTTON", L"Done!", WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON, 280, 260, 80, 25, hwnd, (HMENU)IDOK, NULL, NULL);
        CreateWindowW(L"BUTTON", L"Cancel", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 370, 260, 80, 25, hwnd, (HMENU)IDCANCEL, NULL, NULL);
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_DRAWITEM:
        {
            DRAWITEMSTRUCT* dis = (DRAWITEMSTRUCT*)lParam;
            FillRect(dis->hDC, &dis->rcItem, (HBRUSH)(COLOR_WINDOW+1));
            if (dis->CtlID == IDC_REPLACE_OLD_PREVIEW) {
                HMODULE hMod = LoadLibraryExW(g_loadedFile.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
                if (hMod) {
                    LPCWSTR id = g_replaceName.c_str();
                    if (g_replaceName.find(L"#") == 0) id = MAKEINTRESOURCEW(_wtoi(g_replaceName.c_str() + 1));
                    
                    if (g_replaceType == L"#14" || g_replaceType == L"#3" || g_replaceType == L"#1" || g_replaceType == L"#12") {
                        UINT imgType = (g_replaceType == L"#14" || g_replaceType == L"#3") ? IMAGE_ICON : IMAGE_CURSOR;
                        HICON hIco = (HICON)LoadImageW(hMod, id, imgType, 64, 64, 0);
                        if (hIco) { DrawIconEx(dis->hDC, 10, 10, hIco, 64, 64, 0, NULL, DI_NORMAL); DestroyIcon(hIco); }
                    } else if (g_replaceType == L"#2") {
                        HBITMAP hBmp = (HBITMAP)LoadImageW(hMod, id, IMAGE_BITMAP, 0, 0, LR_CREATEDIBSECTION);
                        if (hBmp) {
                            HDC hdcMem = CreateCompatibleDC(dis->hDC); SelectObject(hdcMem, hBmp);
                            BitBlt(dis->hDC, 10, 10, 180, 180, hdcMem, 0, 0, SRCCOPY);
                            DeleteDC(hdcMem); DeleteObject(hBmp);
                        }
                    } else {
                        SetTextColor(dis->hDC, RGB(30, 30, 30)); SetBkMode(dis->hDC, TRANSPARENT);
                        RECT rc = dis->rcItem; rc.left += 10; rc.top += 10;
                        DrawTextW(dis->hDC, L"(Preview not supported for this type)", -1, &rc, DT_WORDBREAK);
                    }
                    FreeLibrary(hMod);
                }
            } else if (dis->CtlID == IDC_REPLACE_NEW_PREVIEW) {
                if (!g_replacementFile.empty()) {
                    HICON hIco = (HICON)LoadImageW(NULL, g_replacementFile.c_str(), IMAGE_ICON, 64, 64, LR_LOADFROMFILE);
                    if (hIco) { DrawIconEx(dis->hDC, 10, 10, hIco, 64, 64, 0, NULL, DI_NORMAL); DestroyIcon(hIco); }
                    else {
                        HBITMAP hBmp = (HBITMAP)LoadImageW(NULL, g_replacementFile.c_str(), IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE | LR_CREATEDIBSECTION);
                        if (hBmp) {
                            HDC hdcMem = CreateCompatibleDC(dis->hDC); SelectObject(hdcMem, hBmp);
                            BitBlt(dis->hDC, 10, 10, 180, 180, hdcMem, 0, 0, SRCCOPY);
                            DeleteDC(hdcMem); DeleteObject(hBmp);
                        } else {
                            SetTextColor(dis->hDC, RGB(30, 30, 30)); SetBkMode(dis->hDC, TRANSPARENT);
                            RECT rc = dis->rcItem; rc.left += 10; rc.top += 10;
                            std::wstring msg = L"Selected File:\n" + g_replacementFile;
                            DrawTextW(dis->hDC, msg.c_str(), -1, &rc, DT_WORDBREAK);
                        }
                    }
                }
            }
            return TRUE;
        }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_BTN_REPLACE_BROWSE) {
            std::wstring file;
            if (BrowseFile(hwnd, file, L"Resource Files (*.bmp;*.png;*.ico;*.cur;*.res;*.bin)\0*.bmp;*.png;*.ico;*.cur;*.res;*.bin\0All Files (*.*)\0*.*\0")) {
                g_replacementFile = file;
                InvalidateRect(GetDlgItem(hwnd, IDC_REPLACE_NEW_PREVIEW), NULL, TRUE);
            }
        } else if (LOWORD(wParam) == IDOK) {
            if (g_replacementFile.empty()) {
                MessageBoxW(hwnd, L"Please select a replacement file first.", L"Warning", MB_ICONWARNING);
            } else {
                DestroyWindow(hwnd);
            }
        } else if (LOWORD(wParam) == IDCANCEL) {
            g_replacementFile = L""; 
            DestroyWindow(hwnd);
        }
        break;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// Settings Dialog Procedural Handler
LRESULT CALLBACK SettingsDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    static HWND hCheckBackup = NULL;
    static HWND hCheckShowOrigin = NULL;
    static HWND hCheckVerbose = NULL;

    switch (uMsg) {
    case WM_CREATE:
        {
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, (LPARAM)g_hAppIconLarge);
            SendMessageW(hwnd, WM_SETICON, ICON_SMALL, (LPARAM)g_hAppIconSmall);

            hCheckBackup = CreateWindowW(L"BUTTON", L"Enable Safety Backup Protocol (Creates .bak)",
                WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                20, 80, 400, 25, hwnd, (HMENU)101, GetModuleHandleW(NULL), NULL);
            SendMessageW(hCheckBackup, BM_SETCHECK, g_bSafetyBackup ? BST_CHECKED : BST_UNCHECKED, 0);

            hCheckVerbose = CreateWindowW(L"BUTTON", L"Verbose Log Reporting",
                WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                20, 110, 400, 25, hwnd, (HMENU)102, GetModuleHandleW(NULL), NULL);
            SendMessageW(hCheckVerbose, BM_SETCHECK, g_bVerboseLogging ? BST_CHECKED : BST_UNCHECKED, 0);

            hCheckShowOrigin = CreateWindowW(L"BUTTON", L"Show Origin Tags in TreeView ([Base], [MUN], [MUI])",
                WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX,
                20, 140, 400, 25, hwnd, (HMENU)105, GetModuleHandleW(NULL), NULL);
            SendMessageW(hCheckShowOrigin, BM_SETCHECK, g_bShowResourceOrigins ? BST_CHECKED : BST_UNCHECKED, 0);

            CreateWindowW(L"STATIC", L"Custom Signing Certificate (.pfx):",
                WS_CHILD | WS_VISIBLE,
                20, 175, 400, 20, hwnd, NULL, GetModuleHandleW(NULL), NULL);

            HWND hCertEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", g_customCertPath.c_str(),
                WS_CHILD | WS_VISIBLE | WS_TABSTOP | ES_AUTOHSCROLL,
                20, 195, 300, 25, hwnd, (HMENU)103, GetModuleHandleW(NULL), NULL);

            CreateWindowW(L"BUTTON", L"Browse",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                330, 194, 80, 27, hwnd, (HMENU)104, GetModuleHandleW(NULL), NULL);

            CreateWindowW(L"STATIC", L"TreeView Icon Size:",
                WS_CHILD | WS_VISIBLE,
                20, 235, 400, 20, hwnd, (HMENU)106, GetModuleHandleW(NULL), NULL);

            HWND hComboIconSize = CreateWindowW(L"COMBOBOX", L"",
                WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST | WS_TABSTOP,
                20, 255, 100, 150, hwnd, (HMENU)107, GetModuleHandleW(NULL), NULL);

            SendMessageW(hComboIconSize, CB_ADDSTRING, 0, (LPARAM)L"16x16");
            SendMessageW(hComboIconSize, CB_ADDSTRING, 0, (LPARAM)L"24x24");
            SendMessageW(hComboIconSize, CB_ADDSTRING, 0, (LPARAM)L"32x32");
            int selIndex = 0;
            if (g_treeIconSize == 24) selIndex = 1;
            else if (g_treeIconSize == 32) selIndex = 2;
            SendMessageW(hComboIconSize, CB_SETCURSEL, selIndex, 0);

            CreateWindowW(L"BUTTON", L"Done!",
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                110, 290, 80, 25, hwnd, (HMENU)IDOK, GetModuleHandleW(NULL), NULL);
            CreateWindowW(L"BUTTON", L"Cancel",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                200, 290, 80, 25, hwnd, (HMENU)IDCANCEL, GetModuleHandleW(NULL), NULL);

            HFONT hFont = CreateFontW(15, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            SendMessageW(hCheckBackup, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(hCheckVerbose, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(hCheckShowOrigin, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(GetDlgItem(hwnd, 106), WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(hComboIconSize, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(GetDlgItem(hwnd, IDOK), WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(GetDlgItem(hwnd, IDCANCEL), WM_SETFONT, (WPARAM)hFont, TRUE);
            
            CreateToolTip(hwnd, hCheckBackup, L"Toggle creation of backup binaries before performing replacement operations.");
            CreateToolTip(hwnd, hCheckVerbose, L"Enable detailed trace logging to help diagnose execution issues.");
            CreateToolTip(hwnd, hCheckShowOrigin, L"Toggle the display of [Base], [MUN], or [MUI] tags next to resources in the tree.");
            CreateToolTip(hwnd, hComboIconSize, L"Select the display size for icons inside the resource TreeView.");
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            int chinY = height - 45;
            int btnH = 25;
            int btnY = chinY + (45 - btnH) / 2;
            
            HWND hBtnDone = GetDlgItem(hwnd, IDOK);
            HWND hBtnCancel = GetDlgItem(hwnd, IDCANCEL);
            if (hBtnDone && hBtnCancel) {
                int totalW = 80 + 20 + 80;
                int startX = (width - totalW) / 2;
                SetWindowPos(hBtnDone, NULL, startX, btnY, 80, btnH, SWP_NOZORDER);
                SetWindowPos(hBtnCancel, NULL, startX + 100, btnY, 80, btnH, SWP_NOZORDER);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORSTATIC:
        {
            HDC hdc = (HDC)wParam;
            HWND hCtrl = (HWND)lParam;
            int ctrlId = GetDlgCtrlID(hCtrl);
            if (ctrlId == IDOK || ctrlId == IDCANCEL) {
                SetBkMode(hdc, TRANSPARENT);
                static HBRUSH hChinBrush = CreateSolidBrush(RGB(225, 225, 225));
                return (INT_PTR)hChinBrush;
            }
            SetBkMode(hdc, TRANSPARENT);
            return (INT_PTR)GetSysColorBrush(COLOR_BTNFACE);
        }

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rect;
            GetClientRect(hwnd, &rect);

            // Banner
            RECT bannerRect = rect;
            bannerRect.bottom = 60;
            
            TRIVERTEX vertex[2];
            vertex[0].x = bannerRect.left;
            vertex[0].y = bannerRect.top;
            vertex[0].Red = 0x0500;
            vertex[0].Green = 0x0000;
            vertex[0].Blue = 0x1500;
            vertex[0].Alpha = 0x0000;

            vertex[1].x = bannerRect.right;
            vertex[1].y = bannerRect.bottom;
            vertex[1].Red = 0x0000;
            vertex[1].Green = 0x7500;
            vertex[1].Blue = 0xAA00;
            vertex[1].Alpha = 0x0000;

            GRADIENT_RECT gRect;
            gRect.UpperLeft = 0;
            gRect.LowerRight = 1;
            GradientFill(hdc, vertex, 2, &gRect, 1, GRADIENT_FILL_RECT_H);

            DrawIconEx(hdc, 15, 12, g_hAppIconLarge, 36, 36, 0, NULL, DI_NORMAL);

            SetTextColor(hdc, RGB(255, 255, 255));
            SetBkMode(hdc, TRANSPARENT);
            HFONT hFont = CreateFontW(22, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, L"Segoe UI");
            SelectObject(hdc, hFont);
            RECT textRect = bannerRect;
            textRect.left = 65;
            DrawTextW(hdc, L"Settings Manager", -1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
            DeleteObject(hFont);

            DrawEdge(hdc, &bannerRect, BDR_SUNKENOUTER, BF_BOTTOM);

            // Chin
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            DrawEdge(hdc, &chinRect, BDR_RAISEDINNER, BF_TOP);
            EndPaint(hwnd, &ps);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect;
            GetClientRect(hwnd, &rect);
            HBRUSH hBg = GetSysColorBrush(COLOR_BTNFACE);
            FillRect(hdc, &rect, hBg);
            
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            HBRUSH hChinBrush = CreateSolidBrush(RGB(200, 200, 200));
            FillRect(hdc, &chinRect, hChinBrush);
            DeleteObject(hChinBrush);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

    case WM_COMMAND:
        if (LOWORD(wParam) == 104) { // Browse Custom Cert
            wchar_t szFile[MAX_PATH] = { 0 };
            OPENFILENAMEW ofn = { sizeof(ofn) };
            ofn.hwndOwner = hwnd;
            ofn.lpstrFile = szFile;
            ofn.nMaxFile = MAX_PATH;
            ofn.lpstrFilter = L"PFX Certificates (*.pfx)\0*.pfx\0All Files (*.*)\0*.*\0";
            ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
            if (GetOpenFileNameW(&ofn)) {
                SetWindowTextW(GetDlgItem(hwnd, 103), szFile);
            }
        } else if (LOWORD(wParam) == IDOK) {
            g_bSafetyBackup = (SendMessageW(hCheckBackup, BM_GETCHECK, 0, 0) == BST_CHECKED);
            g_bVerboseLogging = (SendMessageW(hCheckVerbose, BM_GETCHECK, 0, 0) == BST_CHECKED);
            bool oldShowOrigin = g_bShowResourceOrigins;
            g_bShowResourceOrigins = (SendMessageW(hCheckShowOrigin, BM_GETCHECK, 0, 0) == BST_CHECKED);
            
            HWND hCombo = GetDlgItem(hwnd, 107);
            int sel = SendMessageW(hCombo, CB_GETCURSEL, 0, 0);
            int oldSize = g_treeIconSize;
            if (sel == 1) g_treeIconSize = 24;
            else if (sel == 2) g_treeIconSize = 32;
            else g_treeIconSize = 16;
            
            wchar_t buf[MAX_PATH];
            GetWindowTextW(GetDlgItem(hwnd, 103), buf, MAX_PATH);
            g_customCertPath = buf;
            
            wchar_t sysDrive[MAX_PATH];
            GetEnvironmentVariableW(L"SystemDrive", sysDrive, MAX_PATH);
            std::wstring iniFile = std::wstring(sysDrive) + L"\\EliteSoftware\\ResourceAlchemist.ini";
            WritePrivateProfileStringW(L"Settings", L"SafetyBackup", g_bSafetyBackup ? L"1" : L"0", iniFile.c_str());
            WritePrivateProfileStringW(L"Settings", L"VerboseLogging", g_bVerboseLogging ? L"1" : L"0", iniFile.c_str());
            WritePrivateProfileStringW(L"Settings", L"ShowResourceOrigins", g_bShowResourceOrigins ? L"1" : L"0", iniFile.c_str());
            WritePrivateProfileStringW(L"Settings", L"CustomCertPath", g_customCertPath.c_str(), iniFile.c_str());
            WritePrivateProfileStringW(L"Settings", L"TreeIconSize", std::to_wstring(g_treeIconSize).c_str(), iniFile.c_str());
            
            if ((oldShowOrigin != g_bShowResourceOrigins || oldSize != g_treeIconSize) && !g_loadedFile.empty()) {
                extern HWND g_hwndListBox;
                GuiListResources(g_loadedFile, g_hwndListBox);
            }
            
            DestroyWindow(hwnd);
        } else if (LOWORD(wParam) == IDCANCEL) {
            DestroyWindow(hwnd);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// What's New Dialog Procedural Handler
LRESULT CALLBACK WhatsNewDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_CREATE:
        {
            extern HICON g_hAppIconLarge;
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, (LPARAM)g_hAppIconLarge);

            HWND hText = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT",
                L"What's New in v1.4.0.6:\r\n"
                L"- Fixed signtool errors by removing unreachable timestamp servers.\r\n"
                L"- Bugtracker populated with new issues.\r\n"
                L"\r\n"
                L"What's New in v1.4.0.4:\r\n"
                L"- Packaged zipped releases into subdirectories (portable setup).\r\n"
                L"- Add installer to packaged zipped releases.\r\n"
                L"- Refactored Settings Dialog to use main window custom gradient banner.\r\n"
                L"- Added dynamic TreeView Icon Extraction & Scaling Options (16x16, 24x24, 32x32).\r\n"
                L"- Added What's New Dialog.\r\n"
                L"\r\n"
                L"What's New in v1.4.0.3:\r\n"
                L"- Fix UI scaling so TreeView properly cascades and fills space on start.\r\n"
                L"- Hex-dump fallback in text viewer to prevent mojibake on binary items.\r\n"
                L"- Removed unneeded manual layout jumps.\r\n",
                WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_READONLY,
                20, 80, 460, 250, hwnd, (HMENU)102, GetModuleHandleW(NULL), NULL);

            HFONT hFont = CreateFontW(14, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            SendMessageW(hText, WM_SETFONT, (WPARAM)hFont, TRUE);

            CreateWindowW(L"BUTTON", L"Okay",
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                210, 345, 80, 25, hwnd, (HMENU)IDOK, GetModuleHandleW(NULL), NULL);
            SendMessageW(GetDlgItem(hwnd, IDOK), WM_SETFONT, (WPARAM)hFont, TRUE);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            int chinY = height - 45;
            int btnH = 25;
            int btnY = chinY + (45 - btnH) / 2;
            
            HWND hBtn = GetDlgItem(hwnd, IDOK);
            if (hBtn) {
                SetWindowPos(hBtn, NULL, (width - 80) / 2, btnY, 80, btnH, SWP_NOZORDER);
            }
            HWND hText = GetDlgItem(hwnd, 102);
            if (hText) {
                SetWindowPos(hText, NULL, 20, 80, width - 40, chinY - 80 - 15, SWP_NOZORDER);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORSTATIC:
        {
            HDC hdc = (HDC)wParam;
            HWND hCtrl = (HWND)lParam;
            int ctrlId = GetDlgCtrlID(hCtrl);
            if (ctrlId == IDOK || ctrlId == 103) {
                SetBkMode(hdc, TRANSPARENT);
                static HBRUSH hChinBrush = CreateSolidBrush(RGB(225, 225, 225));
                return (INT_PTR)hChinBrush;
            }
            SetBkMode(hdc, TRANSPARENT);
            return (INT_PTR)GetSysColorBrush(COLOR_BTNFACE);
        }

    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect;
            GetClientRect(hwnd, &rect);
            HBRUSH hBg = GetSysColorBrush(COLOR_BTNFACE);
            FillRect(hdc, &rect, hBg);
            
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            HBRUSH hChinBrush = CreateSolidBrush(RGB(200, 200, 200));
            FillRect(hdc, &chinRect, hChinBrush);
            DeleteObject(hChinBrush);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rect;
            GetClientRect(hwnd, &rect);

            RECT bannerRect = rect;
            bannerRect.bottom = 60;
            
            TRIVERTEX vertex[2];
            vertex[0].x = bannerRect.left;
            vertex[0].y = bannerRect.top;
            vertex[0].Red = 0x0500;
            vertex[0].Green = 0x0000;
            vertex[0].Blue = 0x1500;
            vertex[0].Alpha = 0x0000;

            vertex[1].x = bannerRect.right;
            vertex[1].y = bannerRect.bottom;
            vertex[1].Red = 0x0000;
            vertex[1].Green = 0x7500;
            vertex[1].Blue = 0xAA00;
            vertex[1].Alpha = 0x0000;

            GRADIENT_RECT gRect;
            gRect.UpperLeft = 0;
            gRect.LowerRight = 1;
            GradientFill(hdc, vertex, 2, &gRect, 1, GRADIENT_FILL_RECT_H);

            extern HICON g_hAppIconLarge;
            DrawIconEx(hdc, 15, 12, g_hAppIconLarge, 32, 32, 0, NULL, DI_NORMAL);

            SetTextColor(hdc, RGB(255, 255, 255));
            SetBkMode(hdc, TRANSPARENT);
            HFONT hFont = CreateFontW(22, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, L"Segoe UI");
            SelectObject(hdc, hFont);
            RECT textRect = bannerRect;
            textRect.left = 65;
            DrawTextW(hdc, L"What's New in Resource Alchemy Hacker", -1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
            DeleteObject(hFont);

            DrawEdge(hdc, &bannerRect, BDR_SUNKENOUTER, BF_BOTTOM);
            
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            DrawEdge(hdc, &chinRect, BDR_RAISEDINNER, BF_TOP);
            
            EndPaint(hwnd, &ps);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL) {
            DestroyWindow(hwnd);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// About Dialog Procedural Handler
LRESULT CALLBACK AboutDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    static HWND hBtnExpand = NULL;
    static HWND hSysInfo = NULL;
    static bool bExpanded = false;

    switch (uMsg) {
    case WM_CREATE:
        {
            extern HICON g_hAppIconLarge;
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, (LPARAM)g_hAppIconLarge);

            HWND hText = CreateWindowW(L"STATIC",
                (std::wstring(L"Resource Alchemy Hacker\nVersion ") + RAH_VERSION + L"\n\nEliteSoftwareTech Co. - Antigravity Suite\nTarget Framework: .NET Framework 4.6 (WinForms / Legacy Win32)\nMinimum OS Target: Windows Vista / Windows 7").c_str(),
                WS_CHILD | WS_VISIBLE,
                20, 80, 360, 80, hwnd, (HMENU)102, GetModuleHandleW(NULL), NULL);

            HFONT hFont = CreateFontW(14, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            SendMessageW(hText, WM_SETFONT, (WPARAM)hFont, TRUE);

            hBtnExpand = CreateWindowW(L"BUTTON", L"Show System Info >>",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                20, 160, 150, 25, hwnd, (HMENU)103, GetModuleHandleW(NULL), NULL);
            SendMessageW(hBtnExpand, WM_SETFONT, (WPARAM)hFont, TRUE);

            hSysInfo = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
                WS_CHILD | WS_VSCROLL | ES_MULTILINE | ES_READONLY,
                20, 195, 360, 100, hwnd, (HMENU)104, GetModuleHandleW(NULL), NULL);
            SendMessageW(hSysInfo, WM_SETFONT, (WPARAM)hFont, TRUE);

            std::wstring sysInfoText;
            MEMORYSTATUSEX statex;
            statex.dwLength = sizeof(statex);
            if (GlobalMemoryStatusEx(&statex)) {
                sysInfoText += L"Total Physical RAM: " + std::to_wstring(statex.ullTotalPhys / (1024 * 1024)) + L" MB\r\n";
                sysInfoText += L"Available Physical RAM: " + std::to_wstring(statex.ullAvailPhys / (1024 * 1024)) + L" MB\r\n";
            }
            SYSTEM_INFO sysinfo;
            GetSystemInfo(&sysinfo);
            sysInfoText += L"Number of Processors: " + std::to_wstring(sysinfo.dwNumberOfProcessors) + L"\r\n";
            sysInfoText += L"Processor Architecture: ";
            if (sysinfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64) sysInfoText += L"x64 (AMD64)\r\n";
            else if (sysinfo.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_INTEL) sysInfoText += L"x86 (Intel)\r\n";
            else sysInfoText += L"Unknown\r\n";
            sysInfoText += L"OS Version: Windows Vista / 7 / 10 / 11 compliant\r\n";
            SetWindowTextW(hSysInfo, sysInfoText.c_str());

            CreateWindowW(L"BUTTON", L"Done!",
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                300, 160, 80, 25, hwnd, (HMENU)IDOK, GetModuleHandleW(NULL), NULL);
            SendMessageW(GetDlgItem(hwnd, IDOK), WM_SETFONT, (WPARAM)hFont, TRUE);

            CreateToolTip(hwnd, hBtnExpand, L"Toggle display of advanced system hardware metrics and platform diagnostics.");
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            int chinY = height - 45;
            int btnH = 25;
            int btnY = chinY + (45 - btnH) / 2;
            
            if (hBtnExpand && GetDlgItem(hwnd, IDOK)) {
                int totalW = 150 + 20 + 80;
                int startX = (width - totalW) / 2;
                SetWindowPos(hBtnExpand, NULL, startX, btnY, 150, btnH, SWP_NOZORDER);
                SetWindowPos(GetDlgItem(hwnd, IDOK), NULL, startX + 170, btnY, 80, btnH, SWP_NOZORDER);
            }
            
            if (hSysInfo) {
                SetWindowPos(hSysInfo, NULL, 20, 170, width - 40, chinY - 170 - 10, SWP_NOZORDER);
            }
            HWND hText = GetDlgItem(hwnd, 102);
            if (hText) {
                SetWindowPos(hText, NULL, 20, 75, width - 40, 85, SWP_NOZORDER);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORSTATIC:
        {
            HDC hdc = (HDC)wParam;
            HWND hCtrl = (HWND)lParam;
            int ctrlId = GetDlgCtrlID(hCtrl);
            if (ctrlId == IDOK || ctrlId == 103) {
                SetBkMode(hdc, TRANSPARENT);
                static HBRUSH hChinBrush = CreateSolidBrush(RGB(225, 225, 225));
                return (INT_PTR)hChinBrush;
            }
            SetBkMode(hdc, TRANSPARENT);
            return (INT_PTR)GetSysColorBrush(COLOR_BTNFACE);
        }

    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect;
            GetClientRect(hwnd, &rect);
            HBRUSH hBg = GetSysColorBrush(COLOR_BTNFACE);
            FillRect(hdc, &rect, hBg);
            
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            HBRUSH hChinBrush = CreateSolidBrush(RGB(200, 200, 200));
            FillRect(hdc, &chinRect, hChinBrush);
            DeleteObject(hChinBrush);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rect;
            GetClientRect(hwnd, &rect);

            RECT bannerRect = rect;
            bannerRect.bottom = 60;
            HBRUSH hBannerBrush = CreateSolidBrush(RGB(50, 50, 100));
            FillRect(hdc, &bannerRect, hBannerBrush);
            DeleteObject(hBannerBrush);

            extern HICON g_hAppIconLarge;
            DrawIconEx(hdc, 15, 12, g_hAppIconLarge, 32, 32, 0, NULL, DI_NORMAL);

            SetTextColor(hdc, RGB(255, 255, 255));
            SetBkMode(hdc, TRANSPARENT);
            HFONT hFont = CreateFontW(22, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, L"Segoe UI");
            SelectObject(hdc, hFont);
            RECT textRect = bannerRect;
            textRect.left = 65;
            DrawTextW(hdc, L"About Resource Alchemy Hacker", -1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
            DeleteObject(hFont);

            DrawEdge(hdc, &bannerRect, BDR_SUNKENOUTER, BF_BOTTOM);

            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            DrawEdge(hdc, &chinRect, BDR_RAISEDINNER, BF_TOP);
            EndPaint(hwnd, &ps);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            DestroyWindow(hwnd);
        } else if (LOWORD(wParam) == 103) {
            if (!bExpanded) {
                SetWindowTextW((HWND)lParam, L"Hide System Info <<");
                RECT rc;
                GetWindowRect(hwnd, &rc);
                SetWindowPos(hwnd, NULL, 0, 0, rc.right - rc.left, 470, SWP_NOMOVE | SWP_NOZORDER);
                ShowWindow(hSysInfo, SW_SHOW);
                bExpanded = true;
            } else {
                SetWindowTextW((HWND)lParam, L"Show System Info >>");
                RECT rc;
                GetWindowRect(hwnd, &rc);
                SetWindowPos(hwnd, NULL, 0, 0, rc.right - rc.left, 270, SWP_NOMOVE | SWP_NOZORDER);
                ShowWindow(hSysInfo, SW_HIDE);
                bExpanded = false;
            }
            InvalidateRect(hwnd, NULL, TRUE);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_DESTROY:
        bExpanded = false;
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// Help Dialog Procedural Handler
LRESULT CALLBACK HelpDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    static HICON hIconHelp = NULL;

    switch (uMsg) {
    case WM_CREATE:
        {
            hIconHelp = LoadIconW(NULL, IDI_QUESTION);
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, (LPARAM)hIconHelp);

            HWND hHelpText = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT",
                L"RESOURCE ALCHEMY HACKER HELP CONTENTS\r\n"
                L"====================================\r\n\r\n"
                L"1. CLI Usage:\r\n"
                L"   ResourceAlchemyHacker_CLI.exe /list <target_exe>\r\n"
                L"   ResourceAlchemyHacker_CLI.exe /extract <target_exe> <type> <name> <lang> <outpath>\r\n"
                L"   ResourceAlchemyHacker_CLI.exe /replace <target_exe> <type> <name> <lang> <inpath>\r\n\r\n"
                L"2. Context Menu Integration:\r\n"
                L"   Right-click any file and select 'Resource Alchemy Hacker' to load the GUI directly with the target file.\r\n\r\n"
                L"3. Safety Backups:\r\n"
                L"   When replacing resources, the tool automatically creates safety backups (.bak) using sequential indexing (e.g. file_1.bak).\r\n\r\n"
                L"4. Settings Panel:\r\n"
                L"   Click 'Settings' on the bottom anchor chin to toggle creation of backups and logging modes.\r\n\r\n"
                L"For support or licensing, contact EliteSoftwareTech Co. customer support.",
                WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_READONLY,
                20, 80, 460, 260, hwnd, (HMENU)105, GetModuleHandleW(NULL), NULL);

            HFONT hFont = CreateFontW(14, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            SendMessageW(hHelpText, WM_SETFONT, (WPARAM)hFont, TRUE);

            CreateWindowW(L"BUTTON", L"Done!",
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                400, 365, 80, 25, hwnd, (HMENU)IDOK, GetModuleHandleW(NULL), NULL);
            SendMessageW(GetDlgItem(hwnd, IDOK), WM_SETFONT, (WPARAM)hFont, TRUE);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            int chinY = height - 45;
            int btnW = 80, btnH = 25;
            int btnY = chinY + (45 - btnH) / 2;
            int btnX = (width - btnW) / 2;
            
            HWND hBtnDone = GetDlgItem(hwnd, IDOK);
            if (hBtnDone) {
                SetWindowPos(hBtnDone, NULL, btnX, btnY, btnW, btnH, SWP_NOZORDER);
            }
            
            HWND hHelpText = GetDlgItem(hwnd, 105);
            if (hHelpText) {
                SetWindowPos(hHelpText, NULL, 20, 80, width - 40, chinY - 80 - 15, SWP_NOZORDER);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORSTATIC:
        {
            HDC hdc = (HDC)wParam;
            HWND hCtrl = (HWND)lParam;
            int ctrlId = GetDlgCtrlID(hCtrl);
            if (ctrlId == IDOK) {
                SetBkMode(hdc, TRANSPARENT);
                static HBRUSH hChinBrush = CreateSolidBrush(RGB(225, 225, 225));
                return (INT_PTR)hChinBrush;
            }
            SetBkMode(hdc, TRANSPARENT);
            return (INT_PTR)GetSysColorBrush(COLOR_BTNFACE);
        }

    case WM_ERASEBKGND:
        {
            HDC hdc = (HDC)wParam;
            RECT rect;
            GetClientRect(hwnd, &rect);
            HBRUSH hBg = GetSysColorBrush(COLOR_BTNFACE);
            FillRect(hdc, &rect, hBg);
            
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            HBRUSH hChinBrush = CreateSolidBrush(RGB(200, 200, 200));
            FillRect(hdc, &chinRect, hChinBrush);
            DeleteObject(hChinBrush);
            if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
            return 1;
        }

    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rect;
            GetClientRect(hwnd, &rect);

            RECT bannerRect = rect;
            bannerRect.bottom = 60;
            HBRUSH hBannerBrush = CreateSolidBrush(RGB(0, 102, 204));
            FillRect(hdc, &bannerRect, hBannerBrush);
            DeleteObject(hBannerBrush);

            DrawIconEx(hdc, 15, 12, hIconHelp, 36, 36, 0, NULL, DI_NORMAL);

            SetTextColor(hdc, RGB(255, 255, 255));
            SetBkMode(hdc, TRANSPARENT);
            HFONT hFont = CreateFontW(22, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, L"Segoe UI");
            SelectObject(hdc, hFont);
            RECT textRect = bannerRect;
            textRect.left = 65;
            DrawTextW(hdc, L"Help & Documentation", -1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
            DeleteObject(hFont);

            DrawEdge(hdc, &bannerRect, BDR_SUNKENOUTER, BF_BOTTOM);

            RECT chinRect = rect;
            chinRect.top = rect.bottom - 45;
            DrawEdge(hdc, &chinRect, BDR_RAISEDINNER, BF_TOP);
            EndPaint(hwnd, &ps);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK) {
            DestroyWindow(hwnd);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

// File Dialogue Helper
bool BrowseFile(HWND hwndParent, std::wstring& outPath, const wchar_t* filter) {
    wchar_t szFile[MAX_PATH] = { 0 };
    OPENFILENAMEW ofn = { 0 };
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner = hwndParent;
    ofn.lpstrFile = szFile;
    ofn.nMaxFile = sizeof(szFile) / sizeof(wchar_t);
    ofn.lpstrFilter = filter;
    ofn.nFilterIndex = 1;
    ofn.Flags = OFN_PATHMUSTEXIST | OFN_FILEMUSTEXIST;
    
    if (GetOpenFileNameW(&ofn)) {
        outPath = szFile;
        return true;
    }
    return false;
}

// Safety Backup Protocol Helper
void BackupFile(const std::wstring& target) {
    std::wstring base = target;
    std::wstring ext = L"";
    size_t extPos = base.find_last_of(L".");
    if (extPos != std::wstring::npos) {
        ext = base.substr(extPos);
        base = base.substr(0, extPos);
    }
    
    int index = 1;
    while (true) {
        std::wstring backupPath = base + L"_" + std::to_wstring(index) + ext + L".bak";
        if (GetFileAttributesW(backupPath.c_str()) == INVALID_FILE_ATTRIBUTES) {
            if (CopyFileW(target.c_str(), backupPath.c_str(), TRUE)) {
                EliteLog(L"EliteSoftware Safety Backup Protocol: Created backup at " + backupPath);
                return;
            } else {
                LogWin32Error(L"Safety Backup failed on CopyFileW");
                return;
            }
        }
        index++;
    }
}

// Resources Listing Helper in GUI (TreeView Version)
struct GuiEnumCtx {
    HWND hTreeView;
    HTREEITEM hCurrentType;
    HTREEITEM hCurrentName;
    HMODULE hMod;
    int* pThumbnailCount;
    int origin;
};

HTREEITEM AddTreeItem(HWND hwndTV, HTREEITEM hParent, const std::wstring& text, LPARAM lParam, int iImage) {
    TVINSERTSTRUCTW tvis = { 0 };
    tvis.hParent = hParent;
    tvis.hInsertAfter = TVI_LAST;
    tvis.item.mask = TVIF_TEXT | TVIF_PARAM | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    tvis.item.pszText = (LPWSTR)text.c_str();
    tvis.item.lParam = lParam;
    tvis.item.iImage = iImage;
    tvis.item.iSelectedImage = iImage;
    return (HTREEITEM)SendMessageW(hwndTV, TVM_INSERTITEMW, 0, (LPARAM)&tvis);
}

struct LangCollectorCtx {
    std::vector<WORD> langs;
};

BOOL CALLBACK LangCollectorProc(HMODULE hMod, LPCWSTR lpszType, LPCWSTR lpszName, WORD wIDLanguage, LONG_PTR lParam) {
    LangCollectorCtx* ctx = (LangCollectorCtx*)lParam;
    ctx->langs.push_back(wIDLanguage);
    return TRUE;
}

struct GuiLangCtx {
    std::vector<WORD> langs;
};
BOOL CALLBACK GuiEnumResLangProc(HMODULE hModule, LPCWSTR lpszType, LPCWSTR lpszName, WORD wIDLanguage, LONG_PTR lParam) {
    GuiLangCtx* ctx = (GuiLangCtx*)lParam;
    ctx->langs.push_back(wIDLanguage);
    return TRUE;
}

BOOL CALLBACK GuiEnumResNameProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    GuiEnumCtx* ctx = (GuiEnumCtx*)lParam;
    std::wstring nameStr = GetResIdOrName(lpszName);
    std::wstring typeStr = GetResIdOrName((LPWSTR)lpszType);
    
    int imgIndex = 1;
    if (lpszType == RT_GROUP_ICON) imgIndex = 9;
    else if (lpszType == RT_ICON) imgIndex = 10;
    else if (lpszType == RT_BITMAP) imgIndex = 11;
    else if (lpszType == RT_CURSOR || lpszType == RT_GROUP_CURSOR) imgIndex = 6;
    else if (lpszType == RT_STRING || lpszType == RT_MESSAGETABLE) imgIndex = 3;
    else if (lpszType == RT_DIALOG) imgIndex = 4;
    else if (lpszType == RT_MENU || lpszType == RT_ACCELERATOR) imgIndex = 7;
    else if (lpszType == RT_MANIFEST) imgIndex = 8;
    else if (lpszType == RT_VERSION) imgIndex = 14;
    else if (typeStr == L"PNG" || (ULONG_PTR)lpszType == 2110) imgIndex = 12; // 2110 is sometimes PNG
    else if (typeStr == L"MUI" || (ULONG_PTR)lpszType == 211) imgIndex = 13; 

    if (*(ctx->pThumbnailCount) < 200) {
        if (lpszType == RT_GROUP_ICON || lpszType == RT_ICON) {
            HRSRC hRes = FindResourceW(ctx->hMod, lpszName, lpszType);
            if (hRes) {
                HGLOBAL hData = LoadResource(ctx->hMod, hRes);
                if (hData) {
                    PBYTE pData = (PBYTE)LockResource(hData);
                    int nID = (lpszType == RT_GROUP_ICON) ? LookupIconIdFromDirectoryEx(pData, TRUE, g_treeIconSize, g_treeIconSize, LR_DEFAULTCOLOR) : 0;
                    HRSRC hResIcon = (lpszType == RT_GROUP_ICON) ? FindResourceW(ctx->hMod, MAKEINTRESOURCEW(nID), RT_ICON) : hRes;
                    if (hResIcon) {
                        HGLOBAL hIconData = LoadResource(ctx->hMod, hResIcon);
                        if (hIconData) {
                            PBYTE pIconData = (PBYTE)LockResource(hIconData);
                            DWORD iconSize = SizeofResource(ctx->hMod, hResIcon);
                            HICON hIcon = CreateIconFromResourceEx(pIconData, iconSize, TRUE, 0x00030000, g_treeIconSize, g_treeIconSize, LR_DEFAULTCOLOR);
                            if (hIcon) {
                                imgIndex = ImageList_AddIcon(g_hImageListTV, hIcon);
                                DestroyIcon(hIcon);
                                (*(ctx->pThumbnailCount))++;
                            }
                        }
                    }
                }
            }
        } else if (lpszType == RT_BITMAP) {
            HBITMAP hBmp = (HBITMAP)LoadImageW(ctx->hMod, lpszName, IMAGE_BITMAP, g_treeIconSize, g_treeIconSize, LR_CREATEDIBSECTION);
            if (hBmp) {
                imgIndex = ImageList_Add(g_hImageListTV, hBmp, NULL);
                DeleteObject(hBmp);
                (*(ctx->pThumbnailCount))++;
            }
        } else if (typeStr == L"PNG" || typeStr == L"IMAGE" || (ULONG_PTR)lpszType == 2110) {
            HRSRC hRes = FindResourceW(ctx->hMod, lpszName, lpszType);
            if (hRes) {
                HGLOBAL hData = LoadResource(ctx->hMod, hRes);
                if (hData) {
                    PBYTE pData = (PBYTE)LockResource(hData);
                    DWORD size = SizeofResource(ctx->hMod, hRes);
                    IStream* pStream = NULL;
                    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, size);
                    if (hMem) {
                        void* pMem = GlobalLock(hMem);
                        memcpy(pMem, pData, size);
                        GlobalUnlock(hMem);
                        CreateStreamOnHGlobal(hMem, TRUE, &pStream);
                        if (pStream) {
                            Gdiplus::Image image(pStream);
                            Gdiplus::Bitmap* pBitmap = new Gdiplus::Bitmap(g_treeIconSize, g_treeIconSize, image.GetPixelFormat());
                            Gdiplus::Graphics g(pBitmap);
                            g.DrawImage(&image, 0, 0, g_treeIconSize, g_treeIconSize);
                            HBITMAP hBmp = NULL;
                            pBitmap->GetHBITMAP(Gdiplus::Color(255,255,255,255), &hBmp);
                            if (hBmp) {
                                imgIndex = ImageList_Add(g_hImageListTV, hBmp, NULL);
                                DeleteObject(hBmp);
                                (*(ctx->pThumbnailCount))++;
                            }
                            delete pBitmap;
                            pStream->Release();
                        }
                        GlobalFree(hMem);
                    }
                }
            }
        }
    }
    
    LangCollectorCtx langCtx;
    EnumResourceLanguagesW(hModule, lpszType, lpszName, LangCollectorProc, (LONG_PTR)&langCtx);
    
    for (WORD wIDLanguage : langCtx.langs) {
        std::wstring finalName = nameStr;
        finalName += L" [LANG: " + std::to_wstring(wIDLanguage) + L"]";
        
        if (g_bShowResourceOrigins) {
            if (ctx->origin == ORIGIN_MUN) finalName += L" [MUN]";
            else if (ctx->origin == ORIGIN_MUI) finalName += L" [MUI]";
            else finalName += L" [Base]";
        }
        
        HTREEITEM hItem = AddTreeItem(ctx->hTreeView, ctx->hCurrentType, finalName, ctx->origin, imgIndex);
        if (ctx->hCurrentName == NULL) ctx->hCurrentName = hItem;
    }
    return TRUE;
}

BOOL CALLBACK GuiEnumResTypeProc(HMODULE hModule, LPWSTR lpszType, LONG_PTR lParam) {
    GuiEnumCtx* ctx = (GuiEnumCtx*)lParam;
    std::wstring typeStr = GetResIdOrName(lpszType);
    if (lpszType == RT_GROUP_ICON) typeStr = L"Icon Group";
    else if (lpszType == RT_ICON) typeStr = L"Icon";
    else if (lpszType == RT_BITMAP) typeStr = L"Bitmap";
    else if (lpszType == RT_STRING) typeStr = L"String Table";
    else if (lpszType == RT_DIALOG) typeStr = L"Dialog";
    else if (lpszType == RT_VERSION) typeStr = L"Version Info";
    else if (lpszType == RT_MANIFEST) typeStr = L"Manifest";
    
    int typeIcon = 0; // Default folder
    if (lpszType == RT_GROUP_ICON) typeIcon = 9;
    else if (lpszType == RT_ICON) typeIcon = 10;
    else if (lpszType == RT_BITMAP) typeIcon = 11;
    else if (lpszType == RT_CURSOR || lpszType == RT_GROUP_CURSOR) typeIcon = 6;
    else if (typeStr == L"WAVE") typeIcon = 5;
    else if (lpszType == RT_STRING || lpszType == RT_MESSAGETABLE) typeIcon = 3;
    else if (lpszType == RT_DIALOG) typeIcon = 4;
    else if (lpszType == RT_MENU || lpszType == RT_ACCELERATOR) typeIcon = 7;
    else if (lpszType == RT_MANIFEST || typeStr == L"XML") typeIcon = 8;
    else if (lpszType == RT_VERSION) typeIcon = 14;
    else if (typeStr == L"PNG") typeIcon = 12;
    else if (typeStr == L"MUI") typeIcon = 13;
    
    ctx->hCurrentType = AddTreeItem(ctx->hTreeView, TVI_ROOT, typeStr, 0, typeIcon);
    EnumResourceNamesW(hModule, lpszType, GuiEnumResNameProc, lParam);
    return TRUE;
}

void GuiListResources(const std::wstring& target, HWND hTreeView) {
    SendMessageW(hTreeView, TVM_DELETEITEM, 0, (LPARAM)TVI_ROOT);
    
    if (g_hImageListTV) {
        ImageList_Destroy(g_hImageListTV);
        g_hImageListTV = NULL;
    }
    g_hImageListTV = ImageList_Create(g_treeIconSize, g_treeIconSize, ILC_COLOR32 | ILC_MASK, 0, 500);
    SendMessageW(hTreeView, TVM_SETIMAGELIST, TVSIL_NORMAL, (LPARAM)g_hImageListTV);
    
    HINSTANCE hInstance = GetModuleHandle(NULL);
    HICON hIconFolder = ExtractIconW(hInstance, L"shell32.dll", 3);
    HICON hIconFile = ExtractIconW(hInstance, L"shell32.dll", 2);
    HICON hIconImage = ExtractIconW(hInstance, L"shell32.dll", 325); 
    HICON hIconString = ExtractIconW(hInstance, L"shell32.dll", 55); 
    HICON hIconDialog = ExtractIconW(hInstance, L"shell32.dll", 22);
    HICON hIconAudio = ExtractIconW(hInstance, L"shell32.dll", 116);
    HICON hIconCursor = ExtractIconW(hInstance, L"shell32.dll", 191);
    HICON hIconMenu = ExtractIconW(hInstance, L"shell32.dll", 54);
    HICON hIconXml = ExtractIconW(hInstance, L"shell32.dll", 73);
    HICON hIconGroup = ExtractIconW(hInstance, L"shell32.dll", 43); // index 9
    HICON hIconIcon = ExtractIconW(hInstance, L"shell32.dll", 15);  // index 10
    HICON hIconBitmap = ExtractIconW(hInstance, L"shell32.dll", 72); // index 11
    HICON hIconPng = ExtractIconW(hInstance, L"shell32.dll", 70); // index 12
    HICON hIconMui = ExtractIconW(hInstance, L"shell32.dll", 18); // index 13
    HICON hIconVersion = ExtractIconW(hInstance, L"shell32.dll", 77); // index 14

    ImageList_AddIcon(g_hImageListTV, hIconFolder); // 0
    ImageList_AddIcon(g_hImageListTV, hIconFile);   // 1
    ImageList_AddIcon(g_hImageListTV, hIconImage);  // 2
    ImageList_AddIcon(g_hImageListTV, hIconString); // 3
    ImageList_AddIcon(g_hImageListTV, hIconDialog); // 4
    ImageList_AddIcon(g_hImageListTV, hIconAudio ? hIconAudio : hIconFile); // 5
    ImageList_AddIcon(g_hImageListTV, hIconCursor ? hIconCursor : hIconFile); // 6
    ImageList_AddIcon(g_hImageListTV, hIconMenu ? hIconMenu : hIconFile); // 7
    ImageList_AddIcon(g_hImageListTV, hIconXml ? hIconXml : hIconFile); // 8
    ImageList_AddIcon(g_hImageListTV, hIconGroup ? hIconGroup : hIconFile); // 9
    ImageList_AddIcon(g_hImageListTV, hIconIcon ? hIconIcon : hIconFile); // 10
    ImageList_AddIcon(g_hImageListTV, hIconBitmap ? hIconBitmap : hIconFile); // 11
    ImageList_AddIcon(g_hImageListTV, hIconPng ? hIconPng : hIconFile); // 12
    ImageList_AddIcon(g_hImageListTV, hIconMui ? hIconMui : hIconFile); // 13
    ImageList_AddIcon(g_hImageListTV, hIconVersion ? hIconVersion : hIconFile); // 14

    DestroyIcon(hIconFolder); DestroyIcon(hIconFile); DestroyIcon(hIconImage); DestroyIcon(hIconString); DestroyIcon(hIconDialog);
    if (hIconAudio) DestroyIcon(hIconAudio);
    if (hIconCursor) DestroyIcon(hIconCursor);
    if (hIconMenu) DestroyIcon(hIconMenu);
    if (hIconXml) DestroyIcon(hIconXml);
    if (hIconGroup) DestroyIcon(hIconGroup);
    if (hIconIcon) DestroyIcon(hIconIcon);
    if (hIconBitmap) DestroyIcon(hIconBitmap);
    if (hIconPng) DestroyIcon(hIconPng);
    if (hIconMui) DestroyIcon(hIconMui);
    if (hIconVersion) DestroyIcon(hIconVersion);

    SendMessageW(hTreeView, WM_SETREDRAW, FALSE, 0);
    int thumbCount = 0;
    
    struct OriginScan {
        std::wstring path;
        int origin;
    };
    
    OriginScan scans[] = {
        { target, ORIGIN_BASE },
        { g_loadedFileMUN, ORIGIN_MUN },
        { g_loadedFileMUI, ORIGIN_MUI }
    };
    
    bool anyLoaded = false;
    for (int i = 0; i < 3; ++i) {
        if (scans[i].path.empty()) continue;
        
        // Wait, if it's the base file and MUN exists, maybe we shouldn't use LOAD_LIBRARY_AS_IMAGE_RESOURCE because it will auto-load MUI/MUN?
        // But since we copy to a temp name (RAHxxxx.tmp) that has no .mun or .mui next to it, Windows won't find them! So it's safe!
        HMODULE hMod = LoadLibraryExW(scans[i].path.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
        if (hMod) {
            anyLoaded = true;
            GuiEnumCtx ctx;
            ctx.hTreeView = hTreeView;
            ctx.hMod = hMod;
            ctx.pThumbnailCount = &thumbCount;
            ctx.origin = scans[i].origin;
            EnumResourceTypesW(hMod, GuiEnumResTypeProc, (LONG_PTR)&ctx);
            FreeLibrary(hMod);
        }
    }
    
    if (!anyLoaded) {
        AddTreeItem(hTreeView, TVI_ROOT, L"Failed to load binary file.", 0, 0);
    }
    
    SendMessageW(hTreeView, WM_SETREDRAW, TRUE, 0);
    InvalidateRect(hTreeView, NULL, TRUE);
}

// First Icon resource searcher helper
struct FirstIconCtx {
    std::wstring iconName;
};
BOOL CALLBACK EnumFirstIconProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    FirstIconCtx* ctx = (FirstIconCtx*)lParam;
    if (IS_INTRESOURCE(lpszName)) {
        ctx->iconName = L"#" + std::to_wstring((USHORT)(ULONG_PTR)lpszName);
    } else {
        ctx->iconName = lpszName;
    }
    return FALSE;
}
std::wstring GetFirstGroupIconName(const std::wstring& targetPath) {
    HMODULE hMod = LoadLibraryExW(targetPath.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
    if (!hMod) return L"1";
    FirstIconCtx ctx;
    EnumResourceNamesW(hMod, RT_GROUP_ICON, EnumFirstIconProc, (LONG_PTR)&ctx);
    FreeLibrary(hMod);
    return ctx.iconName.empty() ? L"1" : ctx.iconName;
}

// Icon Deconstructor & Replacement Engine
struct EnumGroupCtx {
    LPCWSTR targetName;
    WORD lang;
    std::vector<WORD> oldSubIconIds;
    std::vector<WORD> otherSubIconIds;
};

BOOL CALLBACK EnumGroupIconsProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    EnumGroupCtx* ctx = (EnumGroupCtx*)lParam;
    HRSRC hResGroup = FindResourceExW(hModule, RT_GROUP_ICON, lpszName, ctx->lang);
    if (!hResGroup) {
        hResGroup = FindResourceW(hModule, lpszName, RT_GROUP_ICON);
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

bool ReplaceIconGroup(const std::wstring& target, LPCWSTR name, WORD lang, const std::wstring& icoPath) {
    EnumGroupCtx ctx;
    ctx.targetName = name;
    ctx.lang = lang;
    
    HMODULE hMod = LoadLibraryExW(target.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
    if (hMod) {
        EnumResourceNamesW(hMod, RT_GROUP_ICON, EnumGroupIconsProc, (LONG_PTR)&ctx);
        FreeLibrary(hMod);
    }
    
    std::ifstream icoFile(icoPath, std::ios::binary);
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
    
    std::vector<ICONDIRENTRY> entries(header.idCount);
    if (!icoFile.read((char*)entries.data(), header.idCount * sizeof(ICONDIRENTRY))) {
        EliteLog(L"ReplaceIconGroup: Failed to read ICO entries");
        return false;
    }
    
    std::vector<std::vector<char>> iconImages(header.idCount);
    for (int i = 0; i < header.idCount; ++i) {
        icoFile.seekg(entries[i].dwImageOffset, std::ios::beg);
        iconImages[i].resize(entries[i].dwBytesInRes);
        if (!icoFile.read(iconImages[i].data(), entries[i].dwBytesInRes)) {
            EliteLog(L"ReplaceIconGroup: Failed to read icon image data for entry " + std::to_wstring(i));
            return false;
        }
    }
    icoFile.close();
    
    std::vector<WORD> newSubIconIds;
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
        UpdateResourceW(hUpdate, RT_ICON, MAKEINTRESOURCEW(oldId), lang, NULL, 0);
    }
    
    for (int i = 0; i < header.idCount; ++i) {
        WORD newId = newSubIconIds[i];
        if (!UpdateResourceW(hUpdate, RT_ICON, MAKEINTRESOURCEW(newId), lang, iconImages[i].data(), (DWORD)iconImages[i].size())) {
            LogWin32Error(L"ReplaceIconGroup: Failed to write new sub-icon ID " + std::to_wstring(newId));
            EndUpdateResourceW(hUpdate, TRUE);
            return false;
        }
    }
    
    std::vector<char> groupDirectoryBuffer(sizeof(ICONDIR) + header.idCount * sizeof(GRPICONDIRENTRY));
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
    
    if (!UpdateResourceW(hUpdate, RT_GROUP_ICON, name, lang, groupDirectoryBuffer.data(), (DWORD)groupDirectoryBuffer.size())) {
        LogWin32Error(L"ReplaceIconGroup: Failed to write new RT_GROUP_ICON directory");
        EndUpdateResourceW(hUpdate, TRUE);
        return false;
    }
    
    if (!EndUpdateResourceW(hUpdate, FALSE)) {
        LogWin32Error(L"ReplaceIconGroup: EndUpdateResourceW failed to commit changes");
        return false;
    }
    
    EliteLog(L"ReplaceIconGroup: Successfully replaced icon group.");
    return true;
}

bool GetSelectedResourceInfo(HWND hwnd, std::wstring& outType, std::wstring& outName, std::wstring& outLang, int* outOrigin) {
    HWND hTree = GetDlgItem(g_hwndInset, IDC_LST_RESOURCES);
    HTREEITEM hSel = (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_CARET, 0);
    if (!hSel) return false;

    auto GetItemInfo = [&](HTREEITEM hItem, std::wstring& textOut, LPARAM& paramOut) {
        wchar_t buf[256] = {0};
        TVITEMW tvi = {0};
        tvi.hItem = hItem;
        tvi.mask = TVIF_TEXT | TVIF_PARAM;
        tvi.pszText = buf;
        tvi.cchTextMax = 256;
        SendMessageW(hTree, TVM_GETITEMW, 0, (LPARAM)&tvi);
        textOut = buf;
        paramOut = tvi.lParam;
    };

    HTREEITEM hParent1 = (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_PARENT, (LPARAM)hSel);
    HTREEITEM hParent2 = hParent1 ? (HTREEITEM)SendMessageW(hTree, TVM_GETNEXTITEM, TVGN_PARENT, (LPARAM)hParent1) : NULL;

    LPARAM param = 0;
    
    if (hParent2) { // Sel is Lang (Wait, we don't do Lang as child node, Lang is part of Name!)
        // This is dead code but keep it safe
        std::wstring tmp;
        GetItemInfo(hSel, outLang, param);
        GetItemInfo(hParent1, outName, param);
        GetItemInfo(hParent2, outType, param);
    } else if (hParent1) { // Sel is Name
        LPARAM tmpParam = 0;
        GetItemInfo(hSel, outName, param);
        GetItemInfo(hParent1, outType, tmpParam);
        
        // Strip [Base], [MUN], [MUI]
        if (outName.length() >= 7 && outName.substr(outName.length() - 7) == L" [Base]") outName = outName.substr(0, outName.length() - 7);
        else if (outName.length() >= 6 && outName.substr(outName.length() - 6) == L" [MUN]") outName = outName.substr(0, outName.length() - 6);
        else if (outName.length() >= 6 && outName.substr(outName.length() - 6) == L" [MUI]") outName = outName.substr(0, outName.length() - 6);

        // Strip [LANG: xxx]
        size_t pos = outName.rfind(L" [LANG: ");
        if (pos != std::wstring::npos) {
            outLang = L"LANG: " + outName.substr(pos + 8, outName.length() - pos - 9); 
            outName = outName.substr(0, pos);
        } else {
            outLang = L"LANG: 1033"; 
        }
    } else { // Sel is Type
        LPARAM tmpParam;
        GetItemInfo(hSel, outType, tmpParam);
        outName = L""; 
        outLang = L"LANG: 1033";
    }
    
    if (outOrigin) *outOrigin = (int)param;
    
    if (outType == L"Icon Group") outType = L"#14";
    else if (outType == L"Icon") outType = L"#3";
    else if (outType == L"Bitmap") outType = L"#2";
    else if (outType == L"String Table") outType = L"#6";
    else if (outType == L"Dialog") outType = L"#5";
    else if (outType == L"Version Info") outType = L"#16";
    else if (outType == L"Manifest") outType = L"#24";
    
    if (outLang.find(L"LANG: ") == 0) outLang = outLang.substr(6);
    
    return true;
}

std::wstring GetFileFromOrigin(int origin) {
    if (origin == ORIGIN_MUN && !g_loadedFileMUN.empty()) return g_loadedFileMUN;
    if (origin == ORIGIN_MUI && !g_loadedFileMUI.empty()) return g_loadedFileMUI;
    return g_loadedFile;
}

bool RunCLIAction(const std::wstring& action, const std::wstring& target, const std::wstring& type, const std::wstring& name, const std::wstring& lang, const std::wstring& extra = L"") {
    wchar_t exePath[MAX_PATH];
    GetModuleFileNameW(NULL, exePath, MAX_PATH);
    std::wstring exeStr = exePath;
    std::wstring dir = exeStr.substr(0, exeStr.find_last_of(L"\\/"));
    std::wstring cliPath = dir + L"\\ResourceAlchemyHacker_CLI.exe";

    std::wstring cmd = L"\"" + cliPath + L"\" " + action + L" \"" + target + L"\" \"" + type + L"\" \"" + name + L"\" " + lang;
    if (!extra.empty()) cmd += L" \"" + extra + L"\"";

    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi;
    std::vector<wchar_t> cmdBuf(cmd.begin(), cmd.end());
    cmdBuf.push_back(L'\0');
    if (CreateProcessW(NULL, cmdBuf.data(), NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
        WaitForSingleObject(pi.hProcess, INFINITE);
        DWORD exitCode = 0;
        GetExitCodeProcess(pi.hProcess, &exitCode);
        CloseHandle(pi.hProcess);
        CloseHandle(pi.hThread);
        return exitCode == 0;
    }
    return false;
}

// Main Window Procedure
LRESULT CALLBACK WndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    switch (uMsg) {
    case WM_CREATE:
        {
            Sleep(750);
            HINSTANCE hInstance = (HINSTANCE)GetWindowLongPtrW(hwnd, GWLP_HINSTANCE);
            
            wchar_t sysDrive[MAX_PATH];
            GetEnvironmentVariableW(L"SystemDrive", sysDrive, MAX_PATH);
            std::wstring logsDir = std::wstring(sysDrive) + L"\\EliteSoftware\\Logs";
            CreateDirectoryW((std::wstring(sysDrive) + L"\\EliteSoftware").c_str(), NULL);
            CreateDirectoryW(logsDir.c_str(), NULL);
            
            std::wstring iniFile = std::wstring(sysDrive) + L"\\EliteSoftware\\ResourceAlchemist.ini";
            g_bSafetyBackup = GetPrivateProfileIntW(L"Settings", L"SafetyBackup", 1, iniFile.c_str()) != 0;
            g_bVerboseLogging = GetPrivateProfileIntW(L"Settings", L"VerboseLogging", 1, iniFile.c_str()) != 0;
            g_bShowResourceOrigins = GetPrivateProfileIntW(L"Settings", L"ShowResourceOrigins", 1, iniFile.c_str()) != 0;
            
            wchar_t certBuf[MAX_PATH] = { 0 };
            GetPrivateProfileStringW(L"Settings", L"CustomCertPath", L"", certBuf, MAX_PATH, iniFile.c_str());
            g_customCertPath = certBuf;
            
            EliteLog(L"GUI: System Startup initialized.");

            LoadDynamicIcon(hInstance);
            SendMessageW(hwnd, WM_SETICON, ICON_BIG, (LPARAM)g_hAppIconLarge);
            SendMessageW(hwnd, WM_SETICON, ICON_SMALL, (LPARAM)g_hAppIconSmall);

            g_hwndStatus = CreateWindowW(STATUSCLASSNAMEW, L"",
                WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP, 0, 0, 0, 0,
                hwnd, (HMENU)200, hInstance, NULL);

            int parts[2] = { 600, -1 };
            SendMessageW(g_hwndStatus, SB_SETPARTS, 2, (LPARAM)parts);
            SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Ready.");
            std::wstring verStr = std::wstring(L"v") + RAH_VERSION;
            SendMessageW(g_hwndStatus, SB_SETTEXTW, 1, (LPARAM)verStr.c_str());


            g_hwndRebar = CreateWindowExW(WS_EX_TOOLWINDOW, REBARCLASSNAMEW, NULL,
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT | RBS_BANDBORDERS | CCS_NODIVIDER | CCS_NOPARENTALIGN,
                0, 60, 0, 0, hwnd, NULL, hInstance, NULL);

            g_hwndToolBar = CreateWindowExW(0, TOOLBARCLASSNAMEW, NULL, WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_TRANSPARENT | TBSTYLE_LIST | CCS_ADJUSTABLE | CCS_NODIVIDER | CCS_NORESIZE, 0, 0, 0, 0, g_hwndRebar, (HMENU)IDC_MAIN_TOOL, hInstance, NULL);
            SendMessageW(g_hwndToolBar, TB_BUTTONSTRUCTSIZE, (WPARAM)sizeof(TBBUTTON), 0);
            SendMessageW(g_hwndToolBar, TB_SETEXTENDEDSTYLE, 0, (LPARAM)TBSTYLE_EX_MIXEDBUTTONS);
            
            HIMAGELIST hImageList = ImageList_Create(16, 16, ILC_COLOR32 | ILC_MASK, 7, 7);
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 4));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 6));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 18));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 238));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 132));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 73));
            ImageList_AddIcon(hImageList, ExtractIconW(hInstance, L"shell32.dll", 2));
            SendMessageW(g_hwndToolBar, TB_SETIMAGELIST, 0, (LPARAM)hImageList);
            
            REBARBANDINFOW rbBand = { sizeof(REBARBANDINFOW) };
            rbBand.fMask = RBBIM_STYLE | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_SIZE;
            rbBand.fStyle = RBBS_CHILDEDGE | (g_bToolbarLocked ? RBBS_NOGRIPPER : RBBS_GRIPPERALWAYS);
            rbBand.hwndChild = g_hwndToolBar;
            rbBand.cxMinChild = 100;
            rbBand.cyMinChild = 24;
            rbBand.cx = 200;
            SendMessageW(g_hwndRebar, RB_INSERTBANDW, (WPARAM)-1, (LPARAM)&rbBand);
            
            BuildToolbar();

            g_hwndInset = CreateWindowExW(WS_EX_CLIENTEDGE, L"ResourceAlchemyHackerInset", L"",
                WS_CHILD | WS_VISIBLE,
                10, 70, 780, 430, hwnd, (HMENU)100, hInstance, NULL);

            HMENU hMenu = CreateMenu();
            HMENU hFile = CreatePopupMenu();
            AppendMenuW(hFile, MF_STRING, IDM_FILE_OPEN, L"&Open...\tCtrl+O");
            AppendMenuW(hFile, MF_STRING, IDM_FILE_SAVE, L"&Save\tCtrl+S");
            AppendMenuW(hFile, MF_STRING, IDM_FILE_SAVEAS, L"Save &As...");
            AppendMenuW(hFile, MF_STRING, IDM_FILE_EXPORT_MONOLITHIC, L"Export &Monolithic (Flattened)...");
            AppendMenuW(hFile, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hFile, MF_STRING, 5104, L"&Close");
            AppendMenuW(hFile, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hFile, MF_STRING, IDM_FILE_EXIT, L"E&xit\tAlt+F4");
            
            HMENU hEdit = CreatePopupMenu();
            AppendMenuW(hEdit, MF_STRING, 5201, L"Copy\tCtrl+C");
            AppendMenuW(hEdit, MF_STRING, 5202, L"Paste\tCtrl+V");
            AppendMenuW(hEdit, MF_STRING, 5203, L"Select All\tCtrl+A");
            AppendMenuW(hEdit, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hEdit, MF_STRING, 5204, L"Find Text...\tCtrl+F");
            AppendMenuW(hEdit, MF_STRING, 5205, L"Find Next\tF3");
            
            HMENU hAction = CreatePopupMenu();
            AppendMenuW(hAction, MF_STRING, 5301, L"Add a single binary or image resource...");
            AppendMenuW(hAction, MF_STRING, 5302, L"Add from a Resource file (*.res, *.rc)");
            AppendMenuW(hAction, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hAction, MF_STRING, 5303, L"Replace Icon...");
            AppendMenuW(hAction, MF_STRING, 5304, L"Replace Cursor...");
            AppendMenuW(hAction, MF_STRING, 5305, L"Replace Bitmap...");
            AppendMenuW(hAction, MF_STRING, IDC_BTN_REPLACE, L"Replace Other Resource...");
            AppendMenuW(hAction, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hAction, MF_STRING, IDC_BTN_DELETE, L"Delete Resource");
            AppendMenuW(hAction, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hAction, MF_STRING, 5308, L"Compile Script\tF5");
            
            HMENU hView = CreatePopupMenu();
            AppendMenuW(hView, MF_STRING, 5401, L"Expand Tree Node\tCtrl+E");
            AppendMenuW(hView, MF_STRING, 5402, L"Collapse Tree Node\tCtrl+C");
            
            HMENU hHelp = CreatePopupMenu();
            AppendMenuW(hHelp, MF_STRING, IDM_HELP_CONTENTS, L"Help Topics\tF1");
            AppendMenuW(hHelp, MF_STRING, IDM_HELP_ABOUT, L"About Resource Alchemy Hacker");
            AppendMenuW(hHelp, MF_SEPARATOR, 0, NULL);
            AppendMenuW(hHelp, MF_STRING, IDM_HELP_WHATSNEW, L"What's New...");
            
            AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hFile, L"&File");
            AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hEdit, L"&Edit");
            AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hView, L"&View");
            AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hAction, L"&Action");
            AppendMenuW(hMenu, MF_POPUP, (UINT_PTR)hHelp, L"&Help");
            
            SetMenu(hwnd, hMenu);

            // Controls inside Inset
            HWND hLblFile = CreateWindowW(L"STATIC", L"Target PE Binary:",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
                15, 15, 200, 20, g_hwndInset, NULL, hInstance, NULL);

            g_hwndEditFile = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | ES_AUTOHSCROLL,
                15, 35, 650, 23, g_hwndInset, (HMENU)IDC_TARGET_FILE, hInstance, NULL);

            g_hwndBtnBrowse = CreateWindowW(L"BUTTON", L"Browse...",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                675, 34, 80, 25, g_hwndInset, (HMENU)IDC_BTN_BROWSE, hInstance, NULL);

            g_hwndListBox = CreateWindowExW(WS_EX_CLIENTEDGE, WC_TREEVIEWW, L"",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | WS_VSCROLL | TVS_HASLINES | TVS_LINESATROOT | TVS_HASBUTTONS | TVS_SHOWSELALWAYS | TVS_NOHSCROLL,
                30, 95, 250, 280, g_hwndInset, (HMENU)IDC_LST_RESOURCES, hInstance, NULL);
                
            CreateWindowExW(WS_EX_CLIENTEDGE, L"STATIC", L"",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | SS_OWNERDRAW,
                290, 95, 260, 280, g_hwndInset, (HMENU)IDC_IMG_PREVIEW, hInstance, NULL);

            g_hwndTextPreview = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
                WS_CHILD | WS_CLIPSIBLINGS | WS_VSCROLL | WS_HSCROLL | ES_MULTILINE | ES_WANTRETURN | ES_AUTOVSCROLL | ES_AUTOHSCROLL,
                290, 95, 260, 280, g_hwndInset, (HMENU)IDC_TEXT_PREVIEW, hInstance, NULL);

            g_hwndBtnSaveResource = CreateWindowW(L"BUTTON", L"Save Script",
                WS_CHILD | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                290, 380, 100, 25, g_hwndInset, (HMENU)IDC_BTN_SAVE_RESOURCE, hInstance, NULL);

            g_hwndBtnPlayWav = CreateWindowW(L"BUTTON", L"Play Audio",
                WS_CHILD | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                290, 380, 100, 25, g_hwndInset, (HMENU)IDC_BTN_PLAY_WAV, hInstance, NULL);

            g_hwndBtnList = CreateWindowW(L"BUTTON", L"Scan Resources",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                570, 105, 160, 25, g_hwndInset, (HMENU)IDC_BTN_LIST, hInstance, NULL);

            g_hwndBtnReplace = CreateWindowW(L"BUTTON", L"Replace Resource...",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                145, 70, 140, 25, g_hwndInset, (HMENU)IDC_BTN_REPLACE, hInstance, NULL);

            g_hwndBtnExtract = CreateWindowW(L"BUTTON", L"Extract Resource...",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                295, 70, 140, 25, g_hwndInset, (HMENU)IDC_BTN_EXTRACT, hInstance, NULL);

            g_hwndBtnDelete = CreateWindowW(L"BUTTON", L"Delete Resource",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                445, 70, 130, 25, g_hwndInset, (HMENU)IDC_BTN_DELETE, hInstance, NULL);

            g_hwndBtnAdd = CreateWindowW(L"BUTTON", L"Add Resource...",
                WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS | BS_PUSHBUTTON,
                585, 70, 130, 25, g_hwndInset, (HMENU)IDC_BTN_ADD, hInstance, NULL);

            // Controls on main window chin
            g_hwndBtnOkay = CreateWindowW(L"BUTTON", L"Okay",
                WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON,
                695, 515, 80, 25, hwnd, (HMENU)IDC_BTN_OKAY, hInstance, NULL);

            g_hwndBtnCancel = CreateWindowW(L"BUTTON", L"Cancel",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                605, 515, 80, 25, hwnd, (HMENU)IDC_BTN_CANCEL, hInstance, NULL);

            g_hwndBtnSettings = CreateWindowW(L"BUTTON", L"Settings...",
                WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                515, 515, 80, 25, hwnd, (HMENU)IDC_BTN_SETTINGS, hInstance, NULL);

            g_hwndLogsLink = CreateWindowW(L"STATIC", L"View Resource Alchemy Hacker Logs",
                WS_CHILD | WS_VISIBLE | SS_NOTIFY,
                15, 518, 300, 20, hwnd, (HMENU)IDC_LOGS_LINK, hInstance, NULL);

            // Fonts setup
            HFONT hFont = CreateFontW(15, 0, 0, 0, FW_REGULAR, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
            
            SendMessageW(hLblFile, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndEditFile, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnBrowse, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndListBox, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnList, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnReplace, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnExtract, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnDelete, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnAdd, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnOkay, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnCancel, WM_SETFONT, (WPARAM)hFont, TRUE);
            SendMessageW(g_hwndBtnSettings, WM_SETFONT, (WPARAM)hFont, TRUE);

            LOGFONTW lf = { 0 };
            lf.lfHeight = -12;
            lf.lfWeight = FW_SEMIBOLD;
            lf.lfUnderline = TRUE;
            wcscpy_s(lf.lfFaceName, L"Segoe UI");
            g_hLinkFont = CreateFontIndirectW(&lf);
            SendMessageW(g_hwndLogsLink, WM_SETFONT, (WPARAM)g_hLinkFont, TRUE);

            // Setup tooltips
            CreateToolTip(hwnd, g_hwndEditFile, L"The path of the executable being hacked. Double-check this before you break a system binary.");
            CreateToolTip(hwnd, g_hwndBtnBrowse, L"Choose a target PE binary. Make sure it's actually an executable and not just random bytes you renamed.");
            CreateToolTip(hwnd, g_hwndListBox, L"Arcane directory listing all resource entities discovered inside the targeted binary.");
            CreateToolTip(hwnd, g_hwndBtnList, L"Initiate deep scan of the target file's PE resource headers and update the directory view.");
            CreateToolTip(hwnd, g_hwndBtnReplace, L"Overwrite an existing resource with a new file (supports bmp, png, ico, cur, res, bin, etc).");
            CreateToolTip(hwnd, g_hwndBtnExtract, L"Extract the selected resource to a standalone file on disk.");
            CreateToolTip(hwnd, g_hwndBtnDelete, L"Delete the selected resource from the target PE binary.");
            CreateToolTip(hwnd, g_hwndBtnAdd, L"Inject a brand new resource into the target PE binary.");
            CreateToolTip(hwnd, g_hwndLogsLink, L"Launch notepad to investigate the internal EliteSoftware operations log.");
            CreateToolTip(hwnd, g_hwndBtnSettings, L"Configure the underlying engine settings. Touch this only if you think you are smarter than our defaults.");
            CreateToolTip(hwnd, g_hwndBtnOkay, L"Commit your resource changes and close the app. Hope you backed up, because we won't save you if you broke it.");
            CreateToolTip(hwnd, g_hwndBtnCancel, L"Abort all operations. Click this to run away from your mistakes.");

            // Parse Command Line Arguments
            int numArgs;
            LPWSTR* szArglist = CommandLineToArgvW(GetCommandLineW(), &numArgs);
            if (numArgs > 1) {
                g_originalFile = szArglist[1];
                LoadTargetPE(g_hwndMain, g_originalFile);
                SetWindowTextW(g_hwndEditFile, g_originalFile.c_str());
            }
            LocalFree(szArglist);

            // Force initial layout update for Inset window since its children are now created
            RECT rcInset;
            GetClientRect(g_hwndInset, &rcInset);
            SendMessageW(g_hwndInset, WM_SIZE, 0, MAKELPARAM(rcInset.right, rcInset.bottom));
            
            RECT rcMain;
            GetClientRect(hwnd, &rcMain);
            PostMessageW(hwnd, WM_SIZE, 0, MAKELPARAM(rcMain.right, rcMain.bottom));
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd, &ps);
            RECT rect;
            GetClientRect(hwnd, &rect);

            int toolHeight = 0;
            if (g_hwndToolBar) {
                RECT rcTool;
                GetWindowRect(g_hwndToolBar, &rcTool);
                toolHeight = rcTool.bottom - rcTool.top;
            }

            // Draw Top Title Banner
            RECT bannerRect = rect;
            bannerRect.bottom = 60;
            
            TRIVERTEX vertex[2];
            vertex[0].x = bannerRect.left;
            vertex[0].y = bannerRect.top;
            vertex[0].Red = 0x0500;
            vertex[0].Green = 0x0000;
            vertex[0].Blue = 0x1500;
            vertex[0].Alpha = 0x0000;

            vertex[1].x = bannerRect.right;
            vertex[1].y = bannerRect.bottom;
            vertex[1].Red = 0x0000;
            vertex[1].Green = 0x7500;
            vertex[1].Blue = 0xAA00;
            vertex[1].Alpha = 0x0000;

            GRADIENT_RECT gRect;
            gRect.UpperLeft = 0;
            gRect.LowerRight = 1;
            GradientFill(hdc, vertex, 2, &gRect, 1, GRADIENT_FILL_RECT_H);

            DrawIconEx(hdc, 15, 12, g_hAppIconLarge, 36, 36, 0, NULL, DI_NORMAL);

            SetTextColor(hdc, RGB(255, 255, 255));
            SetBkMode(hdc, TRANSPARENT);
            HFONT hFont = CreateFontW(24, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_OUTLINE_PRECIS,
                CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY, VARIABLE_PITCH, L"Segoe UI");
            SelectObject(hdc, hFont);
            RECT textRect = bannerRect;
            textRect.left = 65;
            DrawTextW(hdc, L"Resource Alchemy Hacker", -1, &textRect, DT_SINGLELINE | DT_VCENTER | DT_LEFT);
            DeleteObject(hFont);

            DrawEdge(hdc, &bannerRect, BDR_SUNKENOUTER, BF_BOTTOM);

            // Status bar height
            int statusHeight = 0;
            if (g_hwndStatus) {
                RECT rectStatus;
                GetWindowRect(g_hwndStatus, &rectStatus);
                statusHeight = rectStatus.bottom - rectStatus.top;
            }

            // Draw the Chin
            RECT chinRect = rect;
            chinRect.top = rect.bottom - 50 - statusHeight;
            chinRect.bottom = rect.bottom - statusHeight;

            DrawEdge(hdc, &chinRect, BDR_RAISEDINNER, BF_TOP);

            EndPaint(hwnd, &ps);
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_SIZE:
        {
            int width = LOWORD(lParam);
            int height = HIWORD(lParam);
            
            if (g_hwndStatus) {
                if (g_hwndRebar) SendMessageW(g_hwndRebar, WM_SIZE, 0, 0);
                
                int toolHeight = 0;
                if (g_hwndRebar) {
                    RECT rcTool;
                    GetWindowRect(g_hwndRebar, &rcTool);
                    toolHeight = rcTool.bottom - rcTool.top;
                    SetWindowPos(g_hwndRebar, NULL, 0, 60, width, toolHeight, SWP_NOZORDER);
                }

                SendMessageW(g_hwndStatus, WM_SIZE, 0, 0);
                
                int parts[2] = { width - 80, -1 };
                SendMessageW(g_hwndStatus, SB_SETPARTS, 2, (LPARAM)parts);

                RECT rectStatus;
                GetWindowRect(g_hwndStatus, &rectStatus);
                int statusHeight = rectStatus.bottom - rectStatus.top;
                
                int chinY = height - 50 - statusHeight;
                int insetHeight = chinY - (70 + toolHeight) - 10;
                if (insetHeight < 100) insetHeight = 100;
                SetWindowPos(g_hwndInset, NULL, 10, 70 + toolHeight, width - 20, insetHeight, SWP_NOZORDER);
                
                SetWindowPos(g_hwndBtnOkay, NULL, width - 95, chinY + 12, 80, 25, SWP_NOZORDER);
                SetWindowPos(g_hwndBtnCancel, NULL, width - 185, chinY + 12, 80, 25, SWP_NOZORDER);
                SetWindowPos(g_hwndBtnSettings, NULL, width - 275, chinY + 12, 80, 25, SWP_NOZORDER);
                SetWindowPos(g_hwndLogsLink, NULL, 15, chinY + 15, 300, 20, SWP_NOZORDER);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_NOTIFY:
        {
            LPNMHDR nmhdr = (LPNMHDR)lParam;
            if ((nmhdr->hwndFrom == g_hwndRebar || nmhdr->hwndFrom == g_hwndToolBar) && nmhdr->code == NM_RCLICK) {
                POINT pt;
                GetCursorPos(&pt);
                HMENU hMenu = CreatePopupMenu();
                AppendMenuW(hMenu, MF_STRING | (g_bToolbarLocked ? MF_CHECKED : MF_UNCHECKED), 6001, L"Lock Toolbars");
                AppendMenuW(hMenu, MF_STRING, 6002, L"Customize...");
                
                int cmd = TrackPopupMenu(hMenu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, NULL);
                DestroyMenu(hMenu);
                
                if (cmd == 6001) {
                    g_bToolbarLocked = !g_bToolbarLocked;
                    BuildToolbar();
                    SaveSettings(hwnd);
                } else if (cmd == 6002) {
                    ShowCustomModalDialog(hwnd, CustomizeToolbarDlgProc, L"Customize Toolbar", 400, 300);
                }
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_COMMAND:
        {
            WORD ctrlId = LOWORD(wParam);
            if (ctrlId == IDC_BTN_OKAY || ctrlId == IDC_BTN_CANCEL || ctrlId == IDM_FILE_EXIT) {
                PostQuitMessage(0);
            } else if (ctrlId == IDC_BTN_BROWSE) {
                std::wstring selected;
                if (BrowseFile(hwnd, selected, L"Executable Files (*.exe;*.dll)\0*.exe;*.dll\0All Files (*.*)\0*.*\0")) {
                    g_originalFile = selected;
                    LoadTargetPE(hwnd, selected);
                    SetWindowTextW(g_hwndEditFile, g_originalFile.c_str());
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"PE Binary loaded successfully.");
                }
            } else if (ctrlId == IDC_BTN_LIST) {
                if (g_loadedFile.empty()) {
                    MessageBoxW(hwnd, L"Please load a target PE file first.", L"No File", MB_ICONWARNING);
                } else {
                    GuiListResources(g_loadedFile, g_hwndListBox);
                    EliteLog(L"GUI: Re-scanned resources for: " + g_loadedFile);
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Resource headers scanned.");
                }
            } else if (ctrlId == IDM_TEST_LOAD) {
                g_originalFile = L"C:\\Users\\Administrator\\Desktop\\Resource_Alchemy_Hacker\\ResourceAlchemyHacker\\TESTimageres.dll";
                LoadTargetPE(hwnd, g_originalFile);
                SetWindowTextW(g_hwndEditFile, g_originalFile.c_str());
            } else if (ctrlId == IDC_BTN_REPLACE) {
                if (g_loadedFile.empty()) {
                    MessageBoxW(hwnd, L"Please select a target PE file first.", L"Target Missing", MB_ICONERROR);
                    break;
                }
                int rOrigin = 0;
                if (!GetSelectedResourceInfo(hwnd, g_replaceType, g_replaceName, g_replaceLang, &rOrigin) || g_replaceName.empty()) {
                    MessageBoxW(hwnd, L"Please select a specific resource to replace from the TreeView.", L"Select Resource", MB_ICONWARNING);
                    break;
                }
                g_replacementFile = L"";
                ShowCustomModalDialog(hwnd, ReplaceDlgProc, L"Replace Resource", 480, 420);
                if (!g_replacementFile.empty()) {
                    if (g_bSafetyBackup) BackupFile(g_originalFile);
                    if (RunCLIAction(L"/replace", GetFileFromOrigin(rOrigin), g_replaceType, g_replaceName, g_replaceLang, g_replacementFile)) {
                        MessageBoxW(hwnd, L"Resource replaced successfully! (Virtual Changes - Save to write)", L"Success", MB_OK | MB_ICONINFORMATION);
                        SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Resource replacement succeeded.");
                        GuiListResources(g_loadedFile, g_hwndListBox);
                    } else {
                        MessageBoxW(hwnd, L"Failed to replace resource. See log file for details.", L"Error", MB_OK | MB_ICONERROR);
                        SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Resource replacement failed.");
                    }
                }
                          } else if (ctrlId == 5401) { // Expand Tree Node
                  HTREEITEM hSel = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_CARET, 0);
                  if (hSel) {
                      SendMessageW(g_hwndListBox, TVM_EXPAND, TVE_EXPAND, (LPARAM)hSel);
                  } else {
                      HTREEITEM hRoot = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_ROOT, 0);
                      while (hRoot) {
                          SendMessageW(g_hwndListBox, TVM_EXPAND, TVE_EXPAND, (LPARAM)hRoot);
                          hRoot = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_NEXT, (LPARAM)hRoot);
                      }
                  }
              } else if (ctrlId == 5402) { // Collapse Tree Node
                  HTREEITEM hSel = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_CARET, 0);
                  if (hSel) {
                      SendMessageW(g_hwndListBox, TVM_EXPAND, TVE_COLLAPSE, (LPARAM)hSel);
                  } else {
                      HTREEITEM hRoot = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_ROOT, 0);
                      while (hRoot) {
                          SendMessageW(g_hwndListBox, TVM_EXPAND, TVE_COLLAPSE, (LPARAM)hRoot);
                          hRoot = (HTREEITEM)SendMessageW(g_hwndListBox, TVM_GETNEXTITEM, TVGN_NEXT, (LPARAM)hRoot);
                      }
                  }
              } else if (ctrlId == IDM_FILE_SAVE) {
                if (g_loadedFile.empty() || g_originalFile.empty()) break;
                ShowProgressDialogAndSave(hwnd);
            } else if (ctrlId == IDM_FILE_SAVEAS) {
                if (g_loadedFile.empty()) break;
                wchar_t szFile[MAX_PATH] = { 0 };
                OPENFILENAMEW ofn = { sizeof(ofn) };
                ofn.hwndOwner = hwnd;
                ofn.lpstrFile = szFile;
                ofn.nMaxFile = MAX_PATH;
                ofn.lpstrFilter = L"Executable Files (*.exe;*.dll)\0*.exe;*.dll\0All Files (*.*)\0*.*\0";
                ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST;
                if (GetSaveFileNameW(&ofn)) {
                    if (CopyFileW(g_loadedFile.c_str(), szFile, FALSE)) {
                        MessageBoxW(hwnd, L"Copy saved successfully!", L"Success", MB_OK | MB_ICONINFORMATION);
                        SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"File saved as copy.");
                    } else {
                        MessageBoxW(hwnd, L"Failed to save copy.", L"Error", MB_OK | MB_ICONERROR);
                    }
                }
            } else if (ctrlId == IDM_FILE_EXPORT_MONOLITHIC) {
                if (g_loadedFile.empty()) break;
                if (g_loadedFileMUN.empty() && g_loadedFileMUI.empty()) {
                    MessageBoxW(hwnd, L"This binary has no associated .mun or .mui files to flatten. Use regular Save As.", L"Info", MB_OK | MB_ICONINFORMATION);
                    break;
                }
                wchar_t szFile[MAX_PATH] = { 0 };
                OPENFILENAMEW ofn = { sizeof(ofn) };
                ofn.hwndOwner = hwnd;
                ofn.lpstrFile = szFile;
                ofn.nMaxFile = MAX_PATH;
                ofn.lpstrFilter = L"Executable Files (*.exe;*.dll)\0*.exe;*.dll\0All Files (*.*)\0*.*\0";
                ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST;
                if (GetSaveFileNameW(&ofn)) {
                    if (!CopyFileW(g_loadedFile.c_str(), szFile, FALSE)) {
                        MessageBoxW(hwnd, L"Failed to copy base binary.", L"Error", MB_OK | MB_ICONERROR);
                        break;
                    }
                    std::wstring munArg = g_loadedFileMUN.empty() ? L"NONE" : g_loadedFileMUN;
                    std::wstring muiArg = g_loadedFileMUI.empty() ? L"NONE" : g_loadedFileMUI;
                    
                    if (RunCLIAction(L"/flatten", szFile, munArg, muiArg, L"0")) {
                        MessageBoxW(hwnd, L"Exported monolithic binary successfully!", L"Success", MB_OK | MB_ICONINFORMATION);
                    } else {
                        MessageBoxW(hwnd, L"Failed to flatten monolithic binary.", L"Error", MB_OK | MB_ICONERROR);
                    }
                }
            } else if (ctrlId == IDC_BTN_EXTRACT) {
                if (g_loadedFile.empty()) break;
                std::wstring rType, rName, rLang;
                int rOrigin = 0;
                if (!GetSelectedResourceInfo(hwnd, rType, rName, rLang, &rOrigin) || rName.empty()) {
                    MessageBoxW(hwnd, L"Please select a specific resource to extract.", L"Select Resource", MB_ICONWARNING);
                    break;
                }
                std::wstring outPath;
                wchar_t szFile[MAX_PATH] = { 0 };
                OPENFILENAMEW ofn = { sizeof(ofn) };
                ofn.hwndOwner = hwnd;
                ofn.lpstrFile = szFile;
                ofn.nMaxFile = MAX_PATH;
                ofn.lpstrFilter = L"All Files (*.*)\0*.*\0";
                ofn.Flags = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST;
                if (GetSaveFileNameW(&ofn)) {
                    outPath = szFile;
                    if (RunCLIAction(L"/extract", GetFileFromOrigin(rOrigin), rType, rName, rLang, outPath)) {
                        MessageBoxW(hwnd, L"Resource extracted successfully!", L"Success", MB_OK | MB_ICONINFORMATION);
                    } else {
                        MessageBoxW(hwnd, L"Failed to extract resource.", L"Error", MB_OK | MB_ICONERROR);
                    }
                }
            } else if (ctrlId == IDC_BTN_DELETE) {
                if (g_loadedFile.empty()) break;
                std::wstring rType, rName, rLang;
                int rOrigin = 0;
                if (!GetSelectedResourceInfo(hwnd, rType, rName, rLang, &rOrigin) || rName.empty()) {
                    MessageBoxW(hwnd, L"Please select a specific resource to delete.", L"Select Resource", MB_ICONWARNING);
                    break;
                }
                if (MessageBoxW(hwnd, L"Are you sure you want to delete this resource?", L"Confirm Delete", MB_YESNO | MB_ICONWARNING) == IDYES) {
                    if (g_bSafetyBackup) BackupFile(g_originalFile);
                    if (RunCLIAction(L"/delete", GetFileFromOrigin(rOrigin), rType, rName, rLang)) {
                        MessageBoxW(hwnd, L"Resource deleted successfully! (Virtual Changes - Save to write)", L"Success", MB_OK | MB_ICONINFORMATION);
                        GuiListResources(g_loadedFile, g_hwndListBox);
                    } else {
                        MessageBoxW(hwnd, L"Failed to delete resource.", L"Error", MB_OK | MB_ICONERROR);
                    }
                }
            } else if (ctrlId == IDC_BTN_SETTINGS) {
                ShowCustomModalDialog(hwnd, SettingsDlgProc, L"Settings Dialog", 450, 380);
            } else if (ctrlId == IDM_HELP_CONTENTS) {
                ShowCustomModalDialog(hwnd, HelpDlgProc, L"Help & Documentation", 500, 440);
            } else if (ctrlId == IDM_HELP_WHATSNEW) {
                ShowCustomModalDialog(hwnd, WhatsNewDlgProc, L"What's New in Resource Alchemy Hacker", 500, 420);
            } else if (ctrlId == IDM_HELP_ABOUT) {
                ShowCustomModalDialog(hwnd, AboutDlgProc, L"About Resource Alchemy Hacker", 416, 270);
            } else if (ctrlId == IDC_LOGS_LINK) {
                wchar_t sysDrive[MAX_PATH];
                GetEnvironmentVariableW(L"SystemDrive", sysDrive, MAX_PATH);
                std::wstring logFile = std::wstring(sysDrive) + L"\\EliteSoftware\\Logs\\ResourceAlchemist.log";
                ShellExecuteW(NULL, L"open", L"notepad.exe", logFile.c_str(), NULL, SW_SHOWNORMAL);
            }
        }
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    case WM_CTLCOLORSTATIC:
        {
            HDC hdcStatic = (HDC)wParam;
            HWND hwndStatic = (HWND)lParam;
            if (GetDlgCtrlID(hwndStatic) == IDC_LOGS_LINK) {
                SetTextColor(hdcStatic, RGB(0, 102, 204));
            }
            SetBkMode(hdcStatic, TRANSPARENT);
            return (INT_PTR)GetSysColorBrush(COLOR_BTNFACE);
        }
        break;

    case WM_SETCURSOR:
        {
            HWND hwndTarget = (HWND)wParam;
            if (GetDlgCtrlID(hwndTarget) == IDC_LOGS_LINK) {
                SetCursor(LoadCursorW(NULL, IDC_HAND));
                return TRUE;
            }
        }
        break;

    case WM_MENUSELECT:
        {
            UINT uItem = (UINT)LOWORD(wParam);
            UINT Flags = (UINT)HIWORD(wParam);
            if (Flags == 0xFFFF && lParam == NULL) {
                SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Ready.");
            } else {
                switch (uItem) {
                case IDM_FILE_EXIT:
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Terminate the application. Don't worry, your progress is... probably safe.");
                    PostMessageW(hwnd, WM_CLOSE, 0, 0);
                    break;
                case IDM_HELP_CONTENTS:
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Display instructions. Because reading the documentation is always a last resort.");
                    break;
                case IDM_HELP_WHATSNEW:
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"See what's new in this version.");
                    break;
                case IDM_HELP_ABOUT:
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Display system details and credentials of the grand alchemists.");
                    break;
                default:
                    SendMessageW(g_hwndStatus, SB_SETTEXTW, 0, (LPARAM)L"Navigate through the arcane paths of Resource Alchemy.");
                    break;
                }
            }
        }
        break;

    case WM_DESTROY:
        SaveSettings(hwnd);
        if (g_hLinkFont) DeleteObject(g_hLinkFont);
        if (g_hAppIconLarge) DestroyIcon(g_hAppIconLarge);
        if (g_hAppIconSmall) DestroyIcon(g_hAppIconSmall);
        PostQuitMessage(0);
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }
    return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

void LoadTargetPE(HWND hwnd, const std::wstring& path) {
    g_originalFile = path;
    g_originalFileMUN = L"";
    g_originalFileMUI = L"";
    g_loadedFileMUN = L"";
    g_loadedFileMUI = L"";
    
    wchar_t tempPath[MAX_PATH], tempFile[MAX_PATH];
    GetTempPathW(MAX_PATH, tempPath);
    GetTempFileNameW(tempPath, L"RAH", 0, tempFile);
    CopyFileW(g_originalFile.c_str(), tempFile, FALSE);
    g_loadedFile = tempFile;

    DWORD attrs = GetFileAttributesW(tempFile);
    if (attrs != INVALID_FILE_ATTRIBUTES) {
        SetFileAttributesW(tempFile, attrs & ~FILE_ATTRIBUTE_READONLY);
    }
    
    // Check for MUN
    wchar_t drive[_MAX_DRIVE], dir[_MAX_DIR], fname[_MAX_FNAME], ext[_MAX_EXT];
    _wsplitpath_s(g_originalFile.c_str(), drive, _MAX_DRIVE, dir, _MAX_DIR, fname, _MAX_FNAME, ext, _MAX_EXT);
    std::wstring baseName = std::wstring(fname) + ext;
    
    std::wstring sysResPath = std::wstring(drive) + L"\\Windows\\SystemResources\\" + baseName + L".mun";
    std::wstring directMun = g_originalFile + L".mun";
    if (GetFileAttributesW(sysResPath.c_str()) != INVALID_FILE_ATTRIBUTES) {
        g_originalFileMUN = sysResPath;
    } else if (GetFileAttributesW(directMun.c_str()) != INVALID_FILE_ATTRIBUTES) {
        g_originalFileMUN = directMun;
    }
    
    // Check for MUI
    std::wstring enUsMui = std::wstring(drive) + dir + L"en-US\\" + baseName + L".mui";
    std::wstring directMui = g_originalFile + L".mui";
    if (GetFileAttributesW(enUsMui.c_str()) != INVALID_FILE_ATTRIBUTES) {
        g_originalFileMUI = enUsMui;
    } else if (GetFileAttributesW(directMui.c_str()) != INVALID_FILE_ATTRIBUTES) {
        g_originalFileMUI = directMui;
    }
    
    if (!g_originalFileMUN.empty()) {
        wchar_t tMun[MAX_PATH];
        GetTempFileNameW(tempPath, L"RAHMUN", 0, tMun);
        CopyFileW(g_originalFileMUN.c_str(), tMun, FALSE);
        g_loadedFileMUN = tMun;
        SetFileAttributesW(tMun, GetFileAttributesW(tMun) & ~FILE_ATTRIBUTE_READONLY);
    }
    if (!g_originalFileMUI.empty()) {
        wchar_t tMui[MAX_PATH];
        GetTempFileNameW(tempPath, L"RAHMUI", 0, tMui);
        CopyFileW(g_originalFileMUI.c_str(), tMui, FALSE);
        g_loadedFileMUI = tMui;
        SetFileAttributesW(tMui, GetFileAttributesW(tMui) & ~FILE_ATTRIBUTE_READONLY);
    }

    GuiListResources(g_loadedFile, g_hwndListBox);
    EliteLog(L"GUI: Loaded target file: " + g_originalFile + L" into temp file " + g_loadedFile);
}

// Entry Point
int APIENTRY wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow) {
    INITCOMMONCONTROLSEX icex;
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_WIN95_CLASSES | ICC_STANDARD_CLASSES | ICC_COOL_CLASSES | ICC_BAR_CLASSES;
    InitCommonControlsEx(&icex);
    
    Gdiplus::GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    Gdiplus::GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

    const wchar_t CLASS_NAME[] = L"ResourceAlchemyHackerGUI";
    WNDCLASSW wc = { 0 };
    wc.style         = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.lpszClassName = CLASS_NAME;
    wc.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wc.hCursor       = LoadCursorW(NULL, IDC_ARROW);
    RegisterClassW(&wc);

    WNDCLASSW wcInset = { 0 };
    wcInset.style = CS_HREDRAW | CS_VREDRAW;
    wcInset.lpfnWndProc = InsetWndProc;
    wcInset.hInstance = hInstance;
    wcInset.lpszClassName = L"ResourceAlchemyHackerInset";
    wcInset.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
    wcInset.hCursor       = LoadCursorW(NULL, IDC_ARROW);
    RegisterClassW(&wcInset);

    HKEY hKeyTmp;
    if (RegOpenKeyExW(HKEY_CURRENT_USER, L"Software\\EliteSoftware\\ResourceAlchemyHacker", 0, KEY_READ, &hKeyTmp) == ERROR_SUCCESS) {
        DWORD type = REG_DWORD, size = sizeof(g_bToolbarLocked);
        RegQueryValueExW(hKeyTmp, L"ToolbarLocked", NULL, &type, (LPBYTE)&g_bToolbarLocked, &size);
        RegCloseKey(hKeyTmp);
    }

    g_hwndMain = CreateWindowExW(
        0,
        CLASS_NAME,
        L"Resource Alchemy Hacker",
        WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
        CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
        NULL,
        NULL,
        hInstance,
        NULL
    );

    if (g_hwndMain == NULL) {
        if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
        return 0;
    }

    if (!LoadSettings(g_hwndMain)) {
        ShowWindow(g_hwndMain, nCmdShow);
    }
    UpdateWindow(g_hwndMain);

    RECT rcInset;
    GetClientRect(g_hwndInset, &rcInset);
    if (rcInset.right > 0 && rcInset.bottom > 0) {
        SendMessageW(g_hwndInset, WM_SIZE, 0, MAKELPARAM(rcInset.right, rcInset.bottom));
    }
    
    // Fix UI Scaling Bug: Force a full layout cascade after all elements are created
    RECT rcMain;
    GetClientRect(g_hwndMain, &rcMain);
    PostMessageW(g_hwndMain, WM_SIZE, SIZE_RESTORED, MAKELPARAM(rcMain.right, rcMain.bottom));

    MSG msg = { };
    
    ACCEL accels[4] = {
        { FCONTROL | FVIRTKEY, 'R', IDC_BTN_REPLACE },
          { FCONTROL | FVIRTKEY, 'E', 5401 },
          { FCONTROL | FVIRTKEY, 'C', 5402 },
        { FVIRTKEY, VK_F1, IDM_HELP_CONTENTS }
    };
    HACCEL hAccel = CreateAcceleratorTableW(accels, 4);
    
    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        if (msg.message == WM_KEYDOWN && msg.wParam == VK_F1) {
            SendMessageW(g_hwndMain, WM_COMMAND, IDM_HELP_CONTENTS, 0);
            continue;
        }
        if (!TranslateAcceleratorW(g_hwndMain, hAccel, &msg)) {
            TranslateMessage(&msg);
            DispatchMessageW(&msg);
        }
    }
    Gdiplus::GdiplusShutdown(gdiplusToken);

    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }

    return 0;
}












