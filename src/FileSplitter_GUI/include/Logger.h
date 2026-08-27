/**
 * @file Logger.h
 * @brief System logging facility for File Splitter GUI (EliteSoftware standard).
 * @author EliteSoftwareTech Co.
 */

#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <string>
#include <fstream>
#include <mutex>

namespace FileSplitter {

enum class LogLevel {
    Info,
    Warning,
    Error
};

class Logger {
public:
    /**
     * @brief Gets the full log file path (%SystemDrive%\EliteSoftware\Logs\FileSplitter.log).
     */
    static std::wstring GetLogFilePath();

    /**
     * @brief Initializes the log file, creating directories if needed and appending a session header.
     */
    static void Initialize();

    /**
     * @brief Writes a message to the log file with timestamp and log level.
     */
    static void Log(LogLevel level, const std::wstring& message);

    /**
     * @brief Convenient helper for Info level.
     */
    static void LogInfo(const std::wstring& message);

    /**
     * @brief Convenient helper for Warning level.
     */
    static void LogWarning(const std::wstring& message);

    /**
     * @brief Convenient helper for Error level.
     */
    static void LogError(const std::wstring& message);

    /**
     * @brief Launches Notepad to view the log file.
     * @param hWndParent Parent window handle for error dialogs.
     */
    static void OpenLogFileInNotepad(HWND hWndParent);

private:
    static std::mutex s_logMutex;
    static std::wstring GetCurrentTimestamp();
};

} // namespace FileSplitter
