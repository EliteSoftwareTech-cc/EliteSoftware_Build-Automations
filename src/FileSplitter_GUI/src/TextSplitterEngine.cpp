/**
 * @file TextSplitterEngine.cpp
 * @brief Native C++ stream-based text file splitter engine implementation.
 * @author EliteSoftwareTech Co.
 */

#include "TextSplitterEngine.h"
#include <fstream>
#include <iostream>

namespace FileSplitter {

std::wstring TextSplitterEngine::SanitizeFileName(const std::wstring& name) {
    std::wstring sanitized = name;
    for (auto& ch : sanitized) {
        if (ch == L'\\' || ch == L'/' || ch == L':' || ch == L'*' || 
            ch == L'?'  || ch == L'"' || ch == L'<' || ch == L'>' || ch == L'|' || ch < 32) {
            ch = L'_';
        }
    }
    return sanitized;
}

std::wstring TextSplitterEngine::GenerateSubfolderPath(const std::wstring& inputPath, const std::wstring& outputDirOverride) {
    std::filesystem::path input(inputPath);
    std::wstring stem = input.stem().wstring();
    stem = SanitizeFileName(stem);

    std::filesystem::path baseDir;
    if (!outputDirOverride.empty()) {
        baseDir = std::filesystem::path(outputDirOverride);
    } else {
        baseDir = input.parent_path();
    }

    std::wstring folderName = stem + L"_parts";
    return (baseDir / folderName).wstring();
}

std::wstring TextSplitterEngine::DetermineSubfolderPath(const std::wstring& inputPath, const std::wstring& outputDirOverride) {
    return GenerateSubfolderPath(inputPath, outputDirOverride);
}

std::wstring TextSplitterEngine::GenerateChunkFileName(const std::wstring& stem, size_t partIndex, size_t paddingWidth) {
    std::wstring sanitizedStem = SanitizeFileName(stem);
    std::wstringstream ss;
    ss << sanitizedStem << L"_part_" << std::setw(static_cast<int>(paddingWidth)) << std::setfill(L'0') << partIndex << L".txt";
    return ss.str();
}

std::wstring TextSplitterEngine::FormatChunkFilename(const std::wstring& stem, size_t partIndex, size_t paddingWidth) {
    return GenerateChunkFileName(stem, partIndex, paddingWidth);
}

FileSplitResult TextSplitterEngine::SplitFile(const SplitOptions& options) {
    FileSplitResult result;
    result.inputFilePath = options.inputFilePath;

    // Validate limit
    if (options.maxLimit == 0) {
        result.success = false;
        result.errorMessage = L"Invalid split limit: maxLimit must be greater than 0.";
        return result;
    }

    // Validate input file path
    if (options.inputFilePath.empty() || !std::filesystem::exists(options.inputFilePath) || std::filesystem::is_directory(options.inputFilePath)) {
        result.success = false;
        result.errorMessage = L"Input file does not exist or is a directory.";
        return result;
    }

    // Check cancellation prior to work
    if (options.cancelToken && options.cancelToken->load()) {
        result.success = false;
        result.errorMessage = L"Splitting operation cancelled by user.";
        return result;
    }

    std::error_code ec;
    uint64_t totalBytes = std::filesystem::file_size(options.inputFilePath, ec);

    std::ifstream input(options.inputFilePath.c_str(), std::ios::binary);
    if (!input.is_open()) {
        result.success = false;
        result.errorMessage = L"Failed to open input file for reading.";
        return result;
    }

    result.outputFolderPath = GenerateSubfolderPath(options.inputFilePath, options.outputDir);
    std::filesystem::create_directories(result.outputFolderPath, ec);

    std::wstring stem = std::filesystem::path(options.inputFilePath).stem().wstring();

    std::vector<char> buffer(BUFFER_SIZE);
    std::ofstream currentStream;

    size_t chunkIndex = 0;
    uint64_t currentChunkUnitCount = 0;
    uint64_t totalBytesProcessed = 0;
    uint64_t totalUnitsProcessed = 0;
    bool lastByteWasNewline = false;

    auto handleCancellation = [&]() -> FileSplitResult {
        if (currentStream.is_open()) {
            currentStream.close();
        }
        for (const auto& chunkPathStr : result.generatedChunkPaths) {
            std::filesystem::remove(chunkPathStr, ec);
        }
        result.generatedChunkPaths.clear();
        result.success = false;
        result.errorMessage = L"Splitting operation cancelled by user.";
        return result;
    };

    auto openNextChunk = [&]() -> bool {
        if (currentStream.is_open()) {
            currentStream.close();
        }
        chunkIndex++;
        std::wstring chunkName = GenerateChunkFileName(stem, chunkIndex);
        std::filesystem::path chunkPath = std::filesystem::path(result.outputFolderPath) / chunkName;

        if (!options.overwriteExisting && std::filesystem::exists(chunkPath)) {
            result.errorMessage = L"File already exists: " + chunkPath.wstring();
            return false;
        }

        currentStream.open(chunkPath.c_str(), std::ios::binary);
        if (!currentStream.is_open()) {
            result.errorMessage = L"Failed to create chunk file: " + chunkPath.wstring();
            return false;
        }
        result.generatedChunkPaths.push_back(chunkPath.wstring());
        currentChunkUnitCount = 0;
        lastByteWasNewline = false;
        return true;
    };

    if (options.mode == SplitMode::ByCharacters) {
        while (input.read(buffer.data(), buffer.size()) || input.gcount() > 0) {
            std::streamsize bytesRead = input.gcount();

            for (std::streamsize i = 0; i < bytesRead; ++i) {
                unsigned char b = static_cast<unsigned char>(buffer[i]);

                if (!currentStream.is_open()) {
                    if (!openNextChunk()) {
                        result.success = false;
                        if (result.errorMessage.empty()) {
                            result.errorMessage = L"Failed to create chunk file.";
                        }
                        return result;
                    }
                }

                if (IsUtf8LeadByte(b)) {
                    if (currentChunkUnitCount >= options.maxLimit) {
                        if (!openNextChunk()) {
                            result.success = false;
                            if (result.errorMessage.empty()) {
                                result.errorMessage = L"Failed to create chunk file.";
                            }
                            return result;
                        }
                    }
                    currentChunkUnitCount++;
                    totalUnitsProcessed++;
                }

                currentStream.write(reinterpret_cast<const char*>(&b), 1);
                totalBytesProcessed++;
            }

            if (options.cancelToken && options.cancelToken->load()) {
                return handleCancellation();
            }

            if (options.progressCallback) {
                options.progressCallback(1, 1, totalBytesProcessed, totalBytes);
                if (options.cancelToken && options.cancelToken->load()) {
                    return handleCancellation();
                }
            }
        }
    } else { // SplitMode::ByLines
        while (input.read(buffer.data(), buffer.size()) || input.gcount() > 0) {
            std::streamsize bytesRead = input.gcount();

            for (std::streamsize i = 0; i < bytesRead; ++i) {
                char b = buffer[i];

                if (!currentStream.is_open()) {
                    if (!openNextChunk()) {
                        result.success = false;
                        if (result.errorMessage.empty()) {
                            result.errorMessage = L"Failed to create chunk file.";
                        }
                        return result;
                    }
                }

                if (lastByteWasNewline && currentChunkUnitCount >= options.maxLimit) {
                    if (!openNextChunk()) {
                        result.success = false;
                        if (result.errorMessage.empty()) {
                            result.errorMessage = L"Failed to create chunk file.";
                        }
                        return result;
                    }
                }

                currentStream.write(&b, 1);
                totalBytesProcessed++;
                lastByteWasNewline = false;

                if (b == '\n') {
                    currentChunkUnitCount++;
                    totalUnitsProcessed++;
                    lastByteWasNewline = true;
                }
            }

            if (options.cancelToken && options.cancelToken->load()) {
                return handleCancellation();
            }

            if (options.progressCallback) {
                options.progressCallback(1, 1, totalBytesProcessed, totalBytes);
                if (options.cancelToken && options.cancelToken->load()) {
                    return handleCancellation();
                }
            }
        }

        if (totalBytesProcessed > 0 && !lastByteWasNewline) {
            totalUnitsProcessed++;
        }
    }

    if (options.cancelToken && options.cancelToken->load()) {
        return handleCancellation();
    }

    if (currentStream.is_open()) {
        currentStream.close();
    }

    result.success = true;
    result.chunksCreated = chunkIndex;
    result.totalBytesProcessed = totalBytesProcessed;
    result.totalUnitsProcessed = totalUnitsProcessed;
    return result;
}

FileSplitResult TextSplitterEngine::SplitSingleFile(const std::wstring& inputFilePath, const SplitOptions& options) {
    SplitOptions opt = options;
    opt.inputFilePath = inputFilePath;
    return SplitFile(opt);
}

BatchSplitResult TextSplitterEngine::SplitBatch(const std::vector<std::wstring>& inputFiles, const SplitOptions& baseOptions) {
    BatchSplitResult batchResult;
    batchResult.totalFiles = inputFiles.size();

    for (size_t i = 0; i < inputFiles.size(); ++i) {
        if (baseOptions.cancelToken && baseOptions.cancelToken->load()) {
            batchResult.wasCancelled = true;
            break;
        }

        SplitOptions opts = baseOptions;
        opts.inputFilePath = inputFiles[i];

        // Wrap progress callback for batch context if provided
        if (baseOptions.progressCallback) {
            opts.progressCallback = [i, total = inputFiles.size(), &baseOptions](size_t, size_t, uint64_t bytesProcessed, uint64_t totalBytes) {
                baseOptions.progressCallback(i + 1, total, bytesProcessed, totalBytes);
            };
        }

        FileSplitResult res = SplitFile(opts);
        if (res.success) {
            batchResult.successfulFiles++;
        } else {
            batchResult.failedFiles++;
        }
        batchResult.results.push_back(res);
    }

    return batchResult;
}

BatchSplitResult TextSplitterEngine::SplitBatch(const std::vector<SplitOptions>& batchOptions) {
    BatchSplitResult batchResult;
    batchResult.totalFiles = batchOptions.size();

    for (size_t i = 0; i < batchOptions.size(); ++i) {
        const auto& opts = batchOptions[i];
        if (opts.cancelToken && opts.cancelToken->load()) {
            batchResult.wasCancelled = true;
            break;
        }

        FileSplitResult res = SplitFile(opts);
        if (res.success) {
            batchResult.successfulFiles++;
        } else {
            batchResult.failedFiles++;
        }
        batchResult.results.push_back(res);
    }

    return batchResult;
}

BatchSplitResult TextSplitterEngine::SplitBatchFiles(const std::vector<std::wstring>& inputFiles, const SplitOptions& baseOptions) {
    return SplitBatch(inputFiles, baseOptions);
}

} // namespace FileSplitter
