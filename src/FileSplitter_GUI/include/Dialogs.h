/**
 * @file Dialogs.h
 * @brief Custom Win32 dialogs (About, Help, Settings) adhering to EliteSoftware standards.
 * @author EliteSoftwareTech Co.
 */

#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <string>
#include "TextSplitterEngine.h"

namespace FileSplitter {

struct AppSettings {
    SplitMode defaultMode = SplitMode::ByCharacters;
    uint64_t defaultCharLimit = 3000;
    uint64_t defaultLineLimit = 1000;
    bool autoOpenFolder = true;
    int logLevel = 0; // 0=Info, 1=Warn, 2=Error
    std::wstring subfolderPattern = L"[filename]_parts";
};

class Dialogs {
public:
    /**
     * @brief Shows the custom About Dialog with info icon and dynamic expander.
     */
    static void ShowAbout(HWND hWndParent, HINSTANCE hInstance);

    /**
     * @brief Shows the custom Help Dialog with question icon and detailed documentation.
     */
    static void ShowHelp(HWND hWndParent, HINSTANCE hInstance);

    /**
     * @brief Shows the Settings Dialog to adjust preferences.
     * @return true if user clicked Okay or Apply and settings were changed.
     */
    static bool ShowSettings(HWND hWndParent, HINSTANCE hInstance, AppSettings& settings);

    /**
     * @brief Registers custom dialog window classes.
     */
    static void RegisterClasses(HINSTANCE hInstance);
};

} // namespace FileSplitter
