#include "..\EliteLogger.h"
#include <windows.h>
#include <gdiplus.h>
#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <cstdint>
#include <cmath>
#include <algorithm>

#pragma pack(push, 1)
struct ICONDIR {
    uint16_t idReserved;
    uint16_t idType;
    uint16_t idCount;
};

struct ICONDIRENTRY {
    uint8_t bWidth;
    uint8_t bHeight;
    uint8_t bColorCount;
    uint8_t bReserved;
    uint16_t wPlanes;
    uint16_t wBitCount;
    uint32_t dwBytesInRes;
    uint32_t dwImageOffset;
};

struct BITMAPINFOHEADER_ICO {
    uint32_t biSize;
    int32_t  biWidth;
    int32_t  biHeight;
    uint16_t biPlanes;
    uint16_t biBitCount;
    uint32_t biCompression;
    uint32_t biSizeImage;
    int32_t  biXPelsPerMeter;
    int32_t  biYPelsPerMeter;
    uint32_t biClrUsed;
    uint32_t biClrImportant;
};
#pragma pack(pop)

using namespace Gdiplus;

extern "C" UINT WINAPI PrivateExtractIconsW(LPCWSTR szFileName, int nIconIndex, int cxIcon, int cyIcon, HICON *phicon, UINT *piconid, UINT nIcons, UINT flags);

std::wstring Utf8ToUtf16(const std::string& str) {
    if (str.empty()) return std::wstring();
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), NULL, 0);
    std::wstring wstrTo(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, &str[0], (int)str.size(), &wstrTo[0], size_needed);
    return wstrTo;
}

int GetEncoderClsid(const WCHAR* format, CLSID* pClsid) {
    UINT num = 0, size = 0;
    GetImageEncodersSize(&num, &size);
    if (size == 0) return -1;
    ImageCodecInfo* pImageCodecInfo = (ImageCodecInfo*)(malloc(size));
    if (pImageCodecInfo == NULL) return -1;
    GetImageEncoders(num, size, pImageCodecInfo);
    for (UINT j = 0; j < num; ++j) {
        if (wcscmp(pImageCodecInfo[j].MimeType, format) == 0) {
            *pClsid = pImageCodecInfo[j].Clsid;
            free(pImageCodecInfo);
            return j;
        }
    }
    free(pImageCodecInfo);
    if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
    return -1;
}

struct ExtractContext {
    std::wstring outDir;
    int counter;
    CLSID pngClsid;
};

BOOL CALLBACK EnumResNameProc(HMODULE hModule, LPCWSTR lpszType, LPWSTR lpszName, LONG_PTR lParam) {
    ExtractContext* ctx = (ExtractContext*)lParam;
    
    HRSRC hRes = FindResourceW(hModule, lpszName, lpszType);
    if (!hRes) return TRUE;
    HGLOBAL hGlob = LoadResource(hModule, hRes);
    if (!hGlob) return TRUE;
    DWORD size = SizeofResource(hModule, hRes);
    void* data = LockResource(hGlob);
    if (!data || size == 0) return TRUE;

    std::wstring resName;
    if (IS_INTRESOURCE(lpszName)) resName = std::to_wstring((uintptr_t)lpszName);
    else resName = lpszName;
    
    std::wstring typeName;
    if (IS_INTRESOURCE(lpszType)) {
        if (lpszType == (LPCWSTR)RT_BITMAP) typeName = L"BMP";
        else if (lpszType == (LPCWSTR)RT_RCDATA) typeName = L"RCDATA";
        else typeName = L"RES";
    } else {
        typeName = lpszType;
    }

    HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, size);
    void* pMem = GlobalLock(hMem);
    memcpy(pMem, data, size);
    GlobalUnlock(hMem);
    IStream* pStream = nullptr;
    CreateStreamOnHGlobal(hMem, TRUE, &pStream);
    
    Bitmap* bmp = Bitmap::FromStream(pStream);
    if (bmp && bmp->GetLastStatus() == Ok) {
        std::wstring outPath = ctx->outDir + L"\\" + typeName + L"_" + resName + L"_" + std::to_wstring(ctx->counter++) + L".png";
        bmp->Save(outPath.c_str(), &ctx->pngClsid, NULL);
    } else if (IS_INTRESOURCE(lpszType) && lpszType == (LPCWSTR)RT_BITMAP) {
        BITMAPINFOHEADER* bmi = (BITMAPINFOHEADER*)data;
        DWORD fileHeaderSize = sizeof(BITMAPFILEHEADER);
        DWORD totalSize = fileHeaderSize + size;
        HGLOBAL hMemBmp = GlobalAlloc(GMEM_MOVEABLE, totalSize);
        void* pMemBmp = GlobalLock(hMemBmp);
        
        BITMAPFILEHEADER bfh = {};
        bfh.bfType = 0x4D42; // 'BM'
        bfh.bfSize = totalSize;
        bfh.bfOffBits = fileHeaderSize + bmi->biSize;
        if (bmi->biBitCount <= 8) {
            if (bmi->biClrUsed == 0) bfh.bfOffBits += (1 << bmi->biBitCount) * sizeof(RGBQUAD);
            else bfh.bfOffBits += bmi->biClrUsed * sizeof(RGBQUAD);
        } else if (bmi->biCompression == BI_BITFIELDS) {
            bfh.bfOffBits += 3 * sizeof(DWORD);
        }
        
        memcpy(pMemBmp, &bfh, fileHeaderSize);
        memcpy((uint8_t*)pMemBmp + fileHeaderSize, data, size);
        GlobalUnlock(hMemBmp);
        
        IStream* pStreamBmp = nullptr;
        CreateStreamOnHGlobal(hMemBmp, TRUE, &pStreamBmp);
        Bitmap* bmp2 = Bitmap::FromStream(pStreamBmp);
        if (bmp2 && bmp2->GetLastStatus() == Ok) {
            std::wstring outPath = ctx->outDir + L"\\BMP_" + resName + L"_" + std::to_wstring(ctx->counter++) + L".png";
            bmp2->Save(outPath.c_str(), &ctx->pngClsid, NULL);
            delete bmp2;
        }
        pStreamBmp->Release();
        GlobalFree(hMemBmp);
    }
    
    if (bmp) delete bmp;
    pStream->Release();
    GlobalFree(hMem);
    return TRUE;
}

enum class BgRemovalMethod { None, AutoEdge, White, Black, TopLeft, TopRight, BottomLeft, BottomRight };

struct Options {
    bool removeHalo = false;
    BgRemovalMethod bgMethod = BgRemovalMethod::None;
};

void FloodFillRemoveBg(Bitmap* bmp, double tolerance, BgRemovalMethod method) {
    if (method == BgRemovalMethod::None) return;

    int width = bmp->GetWidth();
    int height = bmp->GetHeight();
    Rect rect(0, 0, width, height);
    BitmapData bmpData;
    bmp->LockBits(&rect, ImageLockModeRead | ImageLockModeWrite, PixelFormat32bppARGB, &bmpData);

    uint8_t* pixels = (uint8_t*)bmpData.Scan0;
    std::vector<bool> visited(width * height, false);
    
    auto getPixel = [&](int x, int y, uint8_t& r, uint8_t& g, uint8_t& b, uint8_t& a) {
        uint8_t* row = pixels + y * bmpData.Stride;
        b = row[x * 4 + 0];
        g = row[x * 4 + 1];
        r = row[x * 4 + 2];
        a = row[x * 4 + 3];
    };
    
    auto setTransparent = [&](int x, int y) {
        uint8_t* row = pixels + y * bmpData.Stride;
        row[x * 4 + 3] = 0; 
    };

    struct ColorTarget { uint8_t r, g, b, a; };
    std::vector<ColorTarget> bgColors;
    std::vector<std::pair<int, int>> startPoints;
    
    auto colorAt = [&](int x, int y) -> ColorTarget {
        uint8_t r, g, b, a;
        getPixel(x, y, r, g, b, a);
        return {r, g, b, a};
    };

    if (method == BgRemovalMethod::TopLeft) startPoints.push_back({0, 0});
    else if (method == BgRemovalMethod::TopRight) startPoints.push_back({width - 1, 0});
    else if (method == BgRemovalMethod::BottomLeft) startPoints.push_back({0, height - 1});
    else if (method == BgRemovalMethod::BottomRight) startPoints.push_back({width - 1, height - 1});

    if (!startPoints.empty()) {
        auto c = colorAt(startPoints[0].first, startPoints[0].second);
        if (c.a > 0) bgColors.push_back(c);
    } else {
        if (method == BgRemovalMethod::White) bgColors.push_back({255, 255, 255, 255});
        else if (method == BgRemovalMethod::Black) bgColors.push_back({0, 0, 0, 255});
        else if (method == BgRemovalMethod::AutoEdge) {
            std::vector<std::pair<int, int>> corners = {
                {0, 0}, {width - 1, 0}, {0, height - 1}, {width - 1, height - 1},
                {width / 2, 0}, {width / 2, height - 1}, {0, height / 2}, {width - 1, height / 2}
            };
            for (auto& p : corners) {
                auto c = colorAt(p.first, p.second);
                if (c.a > 0) bgColors.push_back(c);
            }
        }
        
        auto addIfMatch = [&](int x, int y) {
            auto c = colorAt(x, y);
            if (c.a == 0) return;
            for (auto& bg : bgColors) {
                double dist = std::sqrt(std::pow(bg.r - c.r, 2) + std::pow((double)bg.g - c.g, 2) + std::pow(bg.b - c.b, 2));
                if (dist <= tolerance) {
                    startPoints.push_back({x, y});
                    break;
                }
            }
        };

        for (int x = 0; x < width; ++x) { addIfMatch(x, 0); addIfMatch(x, height - 1); }
        for (int y = 0; y < height; ++y) { addIfMatch(0, y); addIfMatch(width - 1, y); }
    }

    std::vector<std::pair<int, int>> q;
    for (auto& p : startPoints) {
        if (!visited[p.second * width + p.first]) {
            q.push_back(p);
            visited[p.second * width + p.first] = true;
        }
    }
    
    while(!q.empty()) {
        auto p = q.back();
        q.pop_back();
        
        int px = p.first;
        int py = p.second;
        
        uint8_t r, g, b, a;
        getPixel(px, py, r, g, b, a);
        
        if (a == 0) continue; 
        
        bool match = false;
        for(auto& bg : bgColors) {
            double dist = std::sqrt(std::pow(bg.r - r, 2) + std::pow((double)bg.g - g, 2) + std::pow(bg.b - b, 2));
            if (dist <= tolerance) {
                match = true;
                break;
            }
        }
        
        if (match) {
            setTransparent(px, py);
            int dx[] = {0, 0, 1, -1};
            int dy[] = {1, -1, 0, 0};
            for(int i = 0; i < 4; ++i) {
                int nx = px + dx[i];
                int ny = py + dy[i];
                if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                    if (!visited[ny * width + nx]) {
                        visited[ny * width + nx] = true;
                        q.push_back({nx, ny});
                    }
                }
            }
        }
    }
    
    bmp->UnlockBits(&bmpData);
}

void RemoveMagentaHalo(Bitmap* bmp) {
    int width = bmp->GetWidth();
    int height = bmp->GetHeight();
    Rect rect(0, 0, width, height);
    BitmapData bmpData;
    bmp->LockBits(&rect, ImageLockModeRead | ImageLockModeWrite, PixelFormat32bppARGB, &bmpData);

    uint8_t* pixels = (uint8_t*)bmpData.Scan0;
    for (int y = 0; y < height; ++y) {
        uint8_t* row = pixels + y * bmpData.Stride;
        for (int x = 0; x < width; ++x) {
            uint8_t b = row[x * 4 + 0];
            uint8_t g = row[x * 4 + 1];
            uint8_t r = row[x * 4 + 2];
            uint8_t a = row[x * 4 + 3];

            if (a > 0) {
                double dist = std::sqrt(std::pow(255.0 - r, 2) + std::pow((double)g, 2) + std::pow(255.0 - b, 2));
                if (dist < 160.0) {
                    row[x * 4 + 3] = 0; 
                }
            }
        }
    }
    bmp->UnlockBits(&bmpData);
}

Bitmap* ResizeImage(Image* original, int width, int height) {
    Bitmap* resized = new Bitmap(width, height, PixelFormat32bppARGB);
    Graphics* g = Graphics::FromImage(resized);
    g->Clear(Color(0, 0, 0, 0));
    g->SetInterpolationMode(InterpolationModeHighQualityBicubic);
    g->SetSmoothingMode(SmoothingModeHighQuality);
    g->SetPixelOffsetMode(PixelOffsetModeHighQuality);
    ImageAttributes attr;
    attr.SetWrapMode(WrapModeTileFlipXY);
    g->DrawImage(original, Rect(0, 0, width, height), 0, 0, original->GetWidth(), original->GetHeight(), UnitPixel, &attr, nullptr, nullptr);
    delete g;
    return resized;
}

std::vector<uint8_t> EncodeAsPNG(Bitmap* bmp) {
    CLSID pngClsid;
    GetEncoderClsid(L"image/png", &pngClsid);
    IStream* pStream = nullptr;
    CreateStreamOnHGlobal(NULL, TRUE, &pStream);
    bmp->Save(pStream, &pngClsid, NULL);

    LARGE_INTEGER liZero = {};
    ULARGE_INTEGER pos = {};
    pStream->Seek(liZero, STREAM_SEEK_CUR, &pos);
    std::vector<uint8_t> buffer(pos.QuadPart);
    pStream->Seek(liZero, STREAM_SEEK_SET, NULL);
    ULONG bytesRead = 0;
    pStream->Read(buffer.data(), (ULONG)buffer.size(), &bytesRead);
    pStream->Release();
    return buffer;
}

std::vector<uint8_t> EncodeAsDIB(Bitmap* bmp, int width, int height) {
    Rect rect(0, 0, width, height);
    BitmapData bmpData;
    bmp->LockBits(&rect, ImageLockModeRead, PixelFormat32bppARGB, &bmpData);

    BITMAPINFOHEADER_ICO bmih = {};
    bmih.biSize = sizeof(BITMAPINFOHEADER_ICO);
    bmih.biWidth = width;
    bmih.biHeight = height * 2;
    bmih.biPlanes = 1;
    bmih.biBitCount = 32;
    bmih.biCompression = 0; 
    bmih.biSizeImage = width * height * 4;

    int andStride = ((width + 31) / 32) * 4;
    int andSize = andStride * height;

    std::vector<uint8_t> buffer;
    buffer.reserve(sizeof(BITMAPINFOHEADER_ICO) + bmih.biSizeImage + andSize);

    uint8_t* hdr = (uint8_t*)&bmih;
    buffer.insert(buffer.end(), hdr, hdr + sizeof(bmih));

    uint8_t* pixels = (uint8_t*)bmpData.Scan0;
    for (int y = height - 1; y >= 0; --y) {
        uint8_t* row = pixels + y * bmpData.Stride;
        buffer.insert(buffer.end(), row, row + width * 4);
    }
    bmp->UnlockBits(&bmpData);

    std::vector<uint8_t> andMask(andSize, 0);
    buffer.insert(buffer.end(), andMask.begin(), andMask.end());
    return buffer;
}

std::string GetSizedFilename(const std::string& path, int size) {
    size_t dotPos = path.find_last_of('.');
    if (dotPos == std::string::npos || dotPos == 0) {
        return path + "_" + std::to_string(size) + "x" + std::to_string(size) + ".png";
    } else {
        return path.substr(0, dotPos) + "_" + std::to_string(size) + "x" + std::to_string(size) + path.substr(dotPos);
    }
}

std::wstring GetMimeTypeFromExt(const std::string& ext) {
    if (ext == ".bmp") return L"image/bmp";
    if (ext == ".jpg" || ext == ".jpeg") return L"image/jpeg";
    if (ext == ".gif") return L"image/gif";
    if (ext == ".tiff" || ext == ".tif") return L"image/tiff";
    if (ext == ".webp") return L"image/webp";
    return L"image/png"; 
}

void SaveSingleImage(Bitmap* bmp, const std::string& outPath, const std::wstring& mimeType) {
    CLSID clsid;
    if (GetEncoderClsid(mimeType.c_str(), &clsid) != -1) {
        std::wstring wOut = Utf8ToUtf16(outPath);
        bmp->Save(wOut.c_str(), &clsid, NULL);
        std::cout << "Saved: " << outPath << "\n";
    }
}

void SaveMultiResIco(Bitmap* sourceBmp, const std::string& outputPath) {
    std::vector<int> sizes = { 16, 24, 32, 48, 64, 96, 128, 256 };
    std::vector<std::vector<uint8_t>> imageDataList;
    ICONDIR iconDir = {};
    iconDir.idReserved = 0;
    iconDir.idType = 1;
    iconDir.idCount = sizes.size();
    
    std::vector<ICONDIRENTRY> entries;
    uint32_t currentOffset = sizeof(ICONDIR) + sizeof(ICONDIRENTRY) * sizes.size();

    for (int size : sizes) {
        Bitmap* resized = ResizeImage(sourceBmp, size, size);
        std::vector<uint8_t> data = (size == 256) ? EncodeAsPNG(resized) : EncodeAsDIB(resized, size, size);
        delete resized;
        imageDataList.push_back(data);

        ICONDIRENTRY entry = {};
        entry.bWidth = (size == 256) ? 0 : (uint8_t)size;
        entry.bHeight = (size == 256) ? 0 : (uint8_t)size;
        entry.bColorCount = 0;
        entry.bReserved = 0;
        entry.wPlanes = 1;
        entry.wBitCount = 32;
        entry.dwBytesInRes = (uint32_t)data.size();
        entry.dwImageOffset = currentOffset;
        entries.push_back(entry);
        currentOffset += (uint32_t)data.size();
    }

    std::ofstream outFile(outputPath, std::ios::binary);
    if (outFile) {
        outFile.write((const char*)&iconDir, sizeof(iconDir));
        for (const auto& entry : entries) {
            outFile.write((const char*)&entry, sizeof(entry));
        }
        for (const auto& data : imageDataList) {
            outFile.write((const char*)data.data(), data.size());
        }
        std::cout << "Successfully created " << outputPath << " with " << sizes.size() << " resolutions.\n";
    }
}

void SaveMultiScaledImages(Bitmap* sourceBmp, const std::string& outputPath, const std::string& outExt) {
    std::vector<int> sizes = { 16, 24, 32, 48, 64, 96, 128, 256 };
    std::wstring mimeType = GetMimeTypeFromExt(outExt);
    CLSID encoderClsid;
    if (GetEncoderClsid(mimeType.c_str(), &encoderClsid) != -1) {
        for (int size : sizes) {
            Bitmap* resized = ResizeImage(sourceBmp, size, size);
            std::string sizedName = GetSizedFilename(outputPath, size);
            std::wstring wSizedName = Utf8ToUtf16(sizedName);
            resized->Save(wSizedName.c_str(), &encoderClsid, NULL);
            delete resized;
        }
        std::cout << "Successfully generated " << sizes.size() << " scaled " << outExt << " files.\n";
    } else {
        std::cerr << "Encoder not found for format: " << outExt << "\nFallback to PNG.\n";
        GetEncoderClsid(L"image/png", &encoderClsid);
        for (int size : sizes) {
            Bitmap* resized = ResizeImage(sourceBmp, size, size);
            std::string sizedName = GetSizedFilename(outputPath, size);
            std::wstring wSizedName = Utf8ToUtf16(sizedName);
            resized->Save(wSizedName.c_str(), &encoderClsid, NULL);
            delete resized;
        }
    }
}

void ProcessFile(const std::string& inputPath8, const std::string& outputPath, const Options& opt) {
    std::wstring inputPath = Utf8ToUtf16(inputPath8);
    size_t slashPos = inputPath8.find_last_of("\\/");
    size_t dotPos = inputPath8.find_last_of(".");
    
    std::string dir = ".";
    if (slashPos != std::string::npos) {
        dir = inputPath8.substr(0, slashPos);
    }
    
    std::string name = inputPath8;
    if (slashPos != std::string::npos) {
        name = inputPath8.substr(slashPos + 1);
    }
    
    // Now strip extension from name if present
    size_t nameDotPos = name.find_last_of(".");
    if (nameDotPos != std::string::npos) {
        name = name.substr(0, nameDotPos);
    }

    std::string ext = "";
    if (dotPos != std::string::npos && (slashPos == std::string::npos || dotPos > slashPos)) {
        ext = inputPath8.substr(dotPos);
    }
    std::transform(ext.begin(), ext.end(), ext.begin(), ::tolower);

    if (outputPath.empty() && (ext == ".exe" || ext == ".dll")) {
        std::string outDirStr = dir + "\\" + name + "_Extracted";
        CreateDirectoryA(outDirStr.c_str(), NULL);
        std::wstring outDir = Utf8ToUtf16(outDirStr);

        CLSID pngClsid;
        GetEncoderClsid(L"image/png", &pngClsid);

        UINT count = PrivateExtractIconsW(inputPath.c_str(), 0, 0, 0, NULL, NULL, 0, 0);
        int iconCount = 0;
        for (UINT i = 0; i < count; ++i) {
            HICON hIcon = NULL;
            PrivateExtractIconsW(inputPath.c_str(), i, 256, 256, &hIcon, NULL, 1, 0);
            if (hIcon) {
                Bitmap bmp(hIcon);
                std::wstring outPath = outDir + L"\\ICON_" + std::to_wstring(i) + L".png";
                bmp.Save(outPath.c_str(), &pngClsid, NULL);
                DestroyIcon(hIcon);
                iconCount++;
            }
        }
        std::cout << "Extracted " << iconCount << " icons to " << outDirStr << ".\n";

        HMODULE hMod = LoadLibraryExW(inputPath.c_str(), NULL, LOAD_LIBRARY_AS_DATAFILE | LOAD_LIBRARY_AS_IMAGE_RESOURCE);
        if (hMod) {
            ExtractContext ctx = { outDir, 0, pngClsid };
            EnumResourceNamesW(hMod, (LPCWSTR)RT_BITMAP, EnumResNameProc, (LONG_PTR)&ctx);
            EnumResourceNamesW(hMod, (LPCWSTR)RT_RCDATA, EnumResNameProc, (LONG_PTR)&ctx);
            EnumResourceNamesW(hMod, L"PNG", EnumResNameProc, (LONG_PTR)&ctx);
            EnumResourceNamesW(hMod, L"IMAGE", EnumResNameProc, (LONG_PTR)&ctx);
            FreeLibrary(hMod);
            std::cout << "Extracted " << ctx.counter << " additional resources (Bitmaps/PNGs/RCDATA).\n";
        }
        return;
    }

    Bitmap* sourceBmp = nullptr;
    if (ext == ".exe" || ext == ".dll" || ext == ".ico") {
        HICON hIcon = NULL;
        PrivateExtractIconsW(inputPath.c_str(), 0, 256, 256, &hIcon, NULL, 1, 0);
        if (hIcon) {
            sourceBmp = new Bitmap(hIcon);
            DestroyIcon(hIcon);
        }
    }

    if (!sourceBmp) {
        sourceBmp = Bitmap::FromFile(inputPath.c_str());
        if (!sourceBmp || sourceBmp->GetLastStatus() != Ok) {
            std::cerr << "Failed to load image or extract icon from: " << inputPath8 << "\n";
            if (sourceBmp) delete sourceBmp;
            return;
        }
    }

    if (opt.removeHalo) RemoveMagentaHalo(sourceBmp);
    if (opt.bgMethod != BgRemovalMethod::None) FloodFillRemoveBg(sourceBmp, 30.0, opt.bgMethod);

    if (!outputPath.empty()) {
        std::string lowerOut = outputPath;
        std::transform(lowerOut.begin(), lowerOut.end(), lowerOut.begin(), ::tolower);
        size_t outExtPos = lowerOut.find_last_of('.');
        std::string outExt = (outExtPos != std::string::npos) ? lowerOut.substr(outExtPos) : "";
        
        if (outExt == ".ico") {
            SaveMultiResIco(sourceBmp, outputPath);
        } else {
            SaveMultiScaledImages(sourceBmp, outputPath, outExt);
        }
    } else {
        std::cout << "No explicit output path provided for " << inputPath8 << ". Generating 1 file in every format...\n";
        
        Bitmap* finalBmp = sourceBmp;
        bool deleteFinal = false;
        
        if (ext == ".ico") {
            if (sourceBmp->GetWidth() != 256 || sourceBmp->GetHeight() != 256) {
                finalBmp = ResizeImage(sourceBmp, 256, 256);
                deleteFinal = true;
            }
        }

        std::vector<std::string> formats = {".png", ".jpg", ".bmp", ".tiff", ".webp"};
        
        if (ext != ".ico") {
            SaveMultiResIco(finalBmp, dir + "\\" + name + ".ico");
        }
        
        for (const auto& f : formats) {
            if (f != ext) {
                SaveSingleImage(finalBmp, dir + "\\" + name + f, GetMimeTypeFromExt(f));
            }
        }
        
        if (deleteFinal) delete finalBmp;
    }

    delete sourceBmp;
}

int main(int argc, char* argv[]) {
    EliteInit("IconManager_CLI", argc, argv);

    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <input_file(s)> [output_file] [options]\n";
        std::cerr << "If multiple inputs are provided or no output is given, generates 1 file in every format.\n";
        if (!strstr(GetCommandLineA(), " --ai-mode")) { system("pause"); }
        return 1;
    }

    GdiplusStartupInput gdiplusStartupInput;
    ULONG_PTR gdiplusToken;
    GdiplusStartup(&gdiplusToken, &gdiplusStartupInput, NULL);

    std::vector<std::string> inputs;
    Options opt;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--remove-halo") opt.removeHalo = true;
        else if (arg == "--remove-bg") opt.bgMethod = BgRemovalMethod::AutoEdge;
        else if (arg == "--remove-bg-white") opt.bgMethod = BgRemovalMethod::White;
        else if (arg == "--remove-bg-black") opt.bgMethod = BgRemovalMethod::Black;
        else if (arg == "--remove-bg-tl") opt.bgMethod = BgRemovalMethod::TopLeft;
        else if (arg == "--remove-bg-tr") opt.bgMethod = BgRemovalMethod::TopRight;
        else if (arg == "--remove-bg-bl") opt.bgMethod = BgRemovalMethod::BottomLeft;
        else if (arg == "--remove-bg-br") opt.bgMethod = BgRemovalMethod::BottomRight;
        else inputs.push_back(arg);
    }

    std::string explicitOutput = "";
    if (inputs.size() == 2) {
        std::string outArg = inputs[1];
        std::transform(outArg.begin(), outArg.end(), outArg.begin(), ::tolower);
        size_t dotPos = outArg.find_last_of('.');
        if (dotPos != std::string::npos) {
            std::string outExt = outArg.substr(dotPos);
            if (outExt == ".ico" || outExt == ".png" || outExt == ".jpg" || outExt == ".jpeg" || outExt == ".bmp" || outExt == ".tiff" || outExt == ".webp") {
                explicitOutput = inputs[1];
                inputs.pop_back();
            }
        }
    }

    for (const auto& in : inputs) {
        ProcessFile(in, explicitOutput, opt);
    }

    GdiplusShutdown(gdiplusToken);
    if (!strstr(GetCommandLineA(), " --ai-mode")) { std::cout << "\nPress any key to exit...\n"; system("pause"); }
    return 0;
}

