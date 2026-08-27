/**
 * @file AppWindow.h
 * @brief Main Win32 GUI window class adhering to EliteSoftware guidelines v1.2.0.0.
 * @author EliteSoftwareTech Co.
 */

#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <shellapi.h>
#include <string>
#include <vector>
#include <thread>
#include <atomic>
#include <memory>
#include "Resource.h"
#include "TextSplitterEngine.h"
#include "Dialogs.h"

namespace FileSplitter {

struct ProgressInfo {
    size_t currentFile = 1;
    size_t totalFiles = 1;
    uint64_t bytesProcessed = 0;
    uint64_t totalBytes = 0;
    int percent = 0;
};

class AppWindow {
public:
    AppWindow();
    ~AppWindow();

    /**
     * @brief Registers main window class and creates the window instance.
     */
    bool Create(HINSTANCE hInstance, int nCmdShow);

    /**
     * @brief Window procedure dispatcher.
     */
    static LRESULT CALLBACK WindowProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

private:
    HWND m_hWnd = NULL;
    HINSTANCE m_hInstance = NULL;
    HICON m_hAppIcon = NULL;

    // Controls
    HWND m_hToolbar = NULL;
    HWND m_hStatusBar = NULL;
    HWND m_hProgressBar = NULL;
    HWND m_hTxtFilePath = NULL;
    HWND m_hBtnBrowse = NULL;
    HWND m_hRadChars = NULL;
    HWND m_hRadLines = NULL;
    HWND m_hTxtLimit = NULL;
    HWND m_hSpnLimit = NULL;
    HWND m_hChkSubfolder = NULL;
    HWND m_hLstBatchFiles = NULL;
    HWND m_hBtnAddBatch = NULL;
    HWND m_hBtnRemoveBatch = NULL;
    HWND m_hBtnClearBatch = NULL;
    HWND m_hLnkLogFile = NULL;
    HWND m_hBtnOkay = NULL;
    HWND m_hBtnApply = NULL;
    HWND m_hBtnCancel = NULL;
    HWND m_hBtnExit = NULL;
    HWND m_hToolTip = NULL;

    // Fonts
    HFONT m_hFontTitle = NULL;
    HFONT m_hFontSub = NULL;
    HFONT m_hFontBody = NULL;
    HFONT m_hFontUnderline = NULL;

    // Background Threading & State
    std::thread m_workerThread;
    std::atomic<bool> m_cancelToken{ false };
    bool m_isSplitting = false;
    AppSettings m_settings;
    std::vector<std::wstring> m_batchFiles;

    // Helper Initialization Methods
    void CreateFonts();
    void InitializeMenuBar();
    void CreateToolbarControls();
    void CreateMainControls();
    void CreateTooltips();
    void LayoutControls();
    HICON LoadDynamicIcon();
    void AddTooltip(HWND hControl, const wchar_t* tipText);

    // Event Handlers
    LRESULT HandleMessage(UINT uMsg, WPARAM wParam, LPARAM lParam);
    void OnPaint(HDC hdc);
    void OnCommand(WORD wId, WORD wEvent, HWND hCtrl);
    void OnDropFiles(HDROP hDrop);
    void OnResize(int width, int height);

    // Operational Methods
    void BrowseInputFile();
    void AddBatchFiles();
    void RemoveSelectedBatchFile();
    void ClearBatchQueue();
    void StartSplitOperation();
    void CancelSplitOperation();
    void UpdateControlsState(bool isSplitting);
    void FormatFileSize(uint64_t bytes, wchar_t* outBuf, size_t bufLen);
};

} // namespace FileSplitter
