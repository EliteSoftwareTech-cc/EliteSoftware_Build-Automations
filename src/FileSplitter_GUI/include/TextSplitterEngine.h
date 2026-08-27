/**
 * @file TextSplitterEngine.h
 * @brief Native C++ stream-based text file splitter engine.
 * @author EliteSoftwareTech Co.
 */

#pragma once

#include <string>
#include <vector>
#include <cstdint>
#include <functional>
#include <atomic>
#include <filesystem>
#include <sstream>
#include <iomanip>
#include <algorithm>

namespace FileSplitter {

/**
 * @brief Splitting operation mode.
 */
enum class SplitMode {
    ByCharacters = 0,  ///< Split based on maximum UTF-8 codepoints/characters per chunk file
    ByLines = 1        ///< Split based on maximum line count per chunk file
};

/**
 * @brief Configuration options for file splitting operations.
 */
struct SplitOptions {
    std::wstring inputFilePath;       ///< Absolute path to input text file
    std::wstring outputDir;           ///< Optional root output directory (uses input file parent dir if empty)
    SplitMode mode = SplitMode::ByCharacters; ///< Splitting mode (ByCharacters or ByLines)
    uint64_t maxLimit = 3000;         ///< Character limit or line limit per chunk
    bool overwriteExisting = true;    ///< Overwrite existing chunk files in subfolder

    /**
     * @brief Thread-safe progress callback.
     * @param currentFile Index of current file being processed (1-based for batch)
     * @param totalFiles Total files in batch
     * @param bytesProcessed Bytes processed so far for current file
     * @param totalBytes Total size in bytes of current file
     */
    std::function<void(size_t currentFile, size_t totalFiles, uint64_t bytesProcessed, uint64_t totalBytes)> progressCallback = nullptr;

    /**
     * @brief Pointer to thread-safe cancellation flag.
     */
    const std::atomic<bool>* cancelToken = nullptr;
};

/**
 * @brief Result metadata for a single file splitting operation.
 */
struct FileSplitResult {
    bool success = false;                     ///< True if file was split successfully without errors/cancellation
    size_t chunksCreated = 0;                 ///< Total number of chunk files created
    uint64_t totalBytesProcessed = 0;         ///< Total bytes read from input file
    uint64_t totalUnitsProcessed = 0;         ///< Total characters or lines counted
    std::wstring inputFilePath;               ///< Input file path processed
    std::wstring outputFolderPath;            ///< Output subfolder path containing chunk files
    std::vector<std::wstring> generatedChunkPaths; ///< List of absolute paths to generated chunk files
    std::wstring errorMessage;                ///< Detailed error description if success == false
};

/**
 * @brief Result metadata for a batch file splitting operation.
 */
struct BatchSplitResult {
    size_t totalFiles = 0;                    ///< Total input files requested
    size_t successfulFiles = 0;               ///< Number of successfully split files
    size_t failedFiles = 0;                   ///< Number of failed files
    bool wasCancelled = false;                ///< True if batch processing was cancelled early
    std::vector<FileSplitResult> results;     ///< Per-file result structures

    /// Implicit conversion operator to std::vector<FileSplitResult> for API convenience
    operator std::vector<FileSplitResult>() const {
        return results;
    }
};

/**
 * @brief Core engine class for single and batch text file splitting.
 */
class TextSplitterEngine {
public:
    /// @brief Streaming buffer size in bytes (64 KB)
    static constexpr size_t BUFFER_SIZE = 64 * 1024;

    /**
     * @brief Splits a single input file into chunk files based on provided options.
     * @param options Execution parameters and callbacks
     * @return FileSplitResult detailing success, chunk count, and output paths
     */
    static FileSplitResult SplitFile(const SplitOptions& options);

    /**
     * @brief Alias for SplitFile accepting input file path and options.
     */
    static FileSplitResult SplitSingleFile(const std::wstring& inputFilePath, const SplitOptions& options);

    /**
     * @brief Processes a batch of input files sequentially using base options.
     * @param inputFiles Vector of input file paths
     * @param baseOptions Template options (inputFilePath overridden per file)
     * @return BatchSplitResult detailing batch statistics and individual file results
     */
    static BatchSplitResult SplitBatch(const std::vector<std::wstring>& inputFiles, const SplitOptions& baseOptions);

    /**
     * @brief Processes a batch of SplitOptions objects sequentially.
     * @param batchOptions Vector of individual file options
     * @return BatchSplitResult detailing batch statistics and individual file results
     */
    static BatchSplitResult SplitBatch(const std::vector<SplitOptions>& batchOptions);

    /**
     * @brief Alias for SplitBatch accepting vector of input file paths and options.
     */
    static BatchSplitResult SplitBatchFiles(const std::vector<std::wstring>& inputFiles, const SplitOptions& baseOptions);

    // --- Auxiliary UTF-8 and Path Utilities ---

    /**
     * @brief Determines if a byte is a UTF-8 lead byte (start of a codepoint).
     * In UTF-8, any byte where (byte & 0xC0) != 0x80 is a lead byte (ASCII or multi-byte start).
     */
    static inline bool IsUtf8LeadByte(unsigned char b) {
        return (b & 0xC0) != 0x80;
    }

    /**
     * @brief Determines if a byte is a UTF-8 continuation byte (10xxxxxx).
     */
    static inline bool IsUtf8ContinuationByte(unsigned char b) {
        return (b & 0xC0) == 0x80;
    }

    /**
     * @brief Sanitizes a filename stem by replacing invalid Windows characters with underscores.
     */
    static std::wstring SanitizeFileName(const std::wstring& name);

    /**
     * @brief Generates standard output subfolder path named after original file stem.
     * @param inputPath Input file path
     * @param outputDirOverride User-specified output folder or empty
     * @return Output subfolder path (e.g. C:\Data\report_parts)
     */
    static std::wstring GenerateSubfolderPath(const std::wstring& inputPath, const std::wstring& outputDirOverride);

    /**
     * @brief Alias for GenerateSubfolderPath.
     */
    static std::wstring DetermineSubfolderPath(const std::wstring& inputPath, const std::wstring& outputDirOverride);

    /**
     * @brief Formats chunk file name with zero-padded index.
     * @param stem Base name of file without extension
     * @param partIndex 1-based index of chunk
     * @param paddingWidth Minimum zero-padding width (default 3)
     * @return Formatted filename (e.g., "report_part_001.txt")
     */
    static std::wstring GenerateChunkFileName(const std::wstring& stem, size_t partIndex, size_t paddingWidth = 3);

    /**
     * @brief Alias for GenerateChunkFileName.
     */
    static std::wstring FormatChunkFilename(const std::wstring& stem, size_t partIndex, size_t paddingWidth = 3);
};

} // namespace FileSplitter
