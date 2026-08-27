# Icon Image Management CLI Tool (icon_maker.exe)

**Version:** 1.0.0
**Architecture:** Win32 C++ (Native)
**Graphics Subsystem:** GDI+ / Win32 Shell API

---

## 1. Overview
The **Icon Image Management CLI Tool** (`icon_maker.exe`) is a high-performance, native C++ Win32 command-line utility built to handle the end-to-end process of generating, extracting, and standardizing `.ico` (Windows Icon) files. 

Traditionally, Icon generation and extraction inside this project relied on a disparate collection of PowerShell and Python scripts (`Fix-IconHalo.ps1`, `ExtractIcon.ps1`, `resize_icons.py`, etc.). This CLI tool unifies the entire logic of those scripts into a single compiled executable with zero third-party dependencies (no libpng, no Qt, etc.).

---

## 2. Features Deep-Dive

### 2.1. Unified Image Format Parsing
At its core, the application uses **GDI+** (`gdiplus.dll`) to interface directly with the Windows graphics subsystem. This provides native, zero-dependency parsing of all common image formats.
* **Supported Formats:** `.png`, `.jpg`, `.jpeg`, `.bmp`, `.gif`, `.tiff`, and more.
* **How it works:** GDI+ reads the bitstream and decodes the image into a raw 32-bit ARGB `Bitmap` object in memory.

### 2.2. Executable & DLL Icon Extraction & Drag-and-Drop
Instead of just processing flat images, the tool can crack open compiled Windows binaries and rip the icons directly from their resource sections.
* **How it works:** When the tool detects an input file ending in `.exe` or `.dll`, it bypasses GDI+ file loading and invokes native APIs to extract the resources. 
* **Drag-and-Drop Extraction Mode:** If you do not provide an output path, the tool defaults into Batch Extraction mode. It automatically creates a subfolder in the same directory (e.g., `Photoshop_Extracted/`). 
* **The technicals:** In Batch mode, it uses `PrivateExtractIconsW` to query the total icon count and extracts the massive 256x256 frame for *every single icon group* in the executable! It also uses `EnumResourceNamesW` and `LoadResource` to dynamically rip all `RT_BITMAP`, `RT_RCDATA`, `PNG`, and `IMAGE` resource types out of the executable, attempting to parse them with GDI+ and reconstructing raw `BITMAPFILEHEADER` blocks if necessary. This entirely replaces the `IconExtractor_Master.PS1` and Python shell extraction scripts.

### 2.3. Advanced Magenta Halo Removal (Color Keying)
Legacy icons and game assets are often distributed with a pure magenta/pink background (`#FF00FF` / `RGB(255, 0, 255)`) representing the transparent color key. Because simple antialiasing blends the foreground image with this background, a "pink halo" often surrounds the edges of the image.
* **How it works:** If the `--remove-halo` flag is thrown, the tool locks the memory of the `Bitmap` (`LockBits`) and iterates over every single pixel. 
* **The Math:** For each pixel, it calculates the **Euclidean Distance** in 3D color space between the pixel's RGB values and pure magenta:
  ```cpp
  double dist = std::sqrt(std::pow(255.0 - r, 2) + std::pow(g, 2) + std::pow(255.0 - b, 2));
  ```
* If the distance is `< 160`, the pixel is considered part of the "halo blend" and its Alpha channel is forcefully set to `0` (Fully Transparent). This replicates and drastically accelerates the math formerly found in `Fix-IconHalo.ps1`.

### 2.4. Smart Background Flood-Fill Removal
Many images contain solid color backgrounds that need to be dropped without affecting the central subject. 
* **How it works:** By passing specific background removal flags, the tool automatically executes an edge flood-fill algorithm that recursively searches using a Depth-First Search (DFS) stack. Pixels matching the targeted background color (within a `30.0` Euclidean distance) are safely converted to transparent.
* **Targeting Methods:**
  - `--remove-bg`: The default auto-removal logic. It samples all 8 edges and corners, flood-filling any matching background areas.
  - `--remove-bg-white`: Specifically searches the perimeter for white pixels (`#FFFFFF`) and clears out white backgrounds.
  - `--remove-bg-black`: Specifically searches the perimeter for black pixels (`#000000`) and clears out black backgrounds.
  - `--remove-bg-tl`, `--remove-bg-tr`, `--remove-bg-bl`, `--remove-bg-br`: Pins the exact background color to only one specific corner pixel (Top-Left, Top-Right, Bottom-Left, Bottom-Right) and flood-fills it.

### 2.5. High-Quality Scaling Engine
A proper Windows `.ico` container must hold multiple resolutions of the same image so the OS can swap between them based on display scaling (DPI) and folder view settings.
* **How it works:** The tool loops through an array of required standard sizes: `16x16`, `24x24`, `32x32`, `48x48`, `64x64`, `96x96`, `128x128`, and `256x256`.
* **The Graphics Engine:** For each size, a new 32-bit ARGB canvas is allocated. The graphics context is cleared with absolute zero `Color(0,0,0,0)` to ensure background transparency. The original image is then drawn onto this canvas using `InterpolationModeHighQualityBicubic` and `PixelOffsetModeHighQuality`. This guarantees perfectly smooth anti-aliased downscaling without pixelation. (Replaces `resize_icons.py`).

### 2.6. Smart Multi-Format Encoding (ICO, PNG, JPG, BMP, TIFF, WebP)
The tool can intuitively output to either an `.ico` binary or a suite of scaled flat files based entirely on your output extension!
* **Standard `.ico` Outputs**: 
  - Sizes `16x16` to `128x128` are encoded as raw Device Independent Bitmaps (DIBs). The tool generates a `BITMAPINFOHEADER`, writes the pixels in a bottom-up structure, and appends a 1bpp AND mask padded to 4-byte boundaries. Because Windows XP and above support the XOR mask's 8-bit alpha channel, the AND mask is zeroed out to ensure perfectly smooth, anti-aliased transparency.
  - Jumbo Size `256x256`: Writing a 256x256 raw DIB would waste over 262KB per file. Since Windows Vista, the OS supports PNG payloads inside `.ico` containers. For the 256x256 resolution, the tool dynamically summons a PNG encoder CLSID (`image/png`), encodes the image directly to an in-memory `IStream`, and injects the compressed PNG bitstream into the ICO container. 
* **Flat Scaled Outputs (`.png`, `.jpg`, `.jpeg`, `.bmp`, `.tiff`, `.webp`)**: 
  - If your output file ends in one of these standard image formats, the tool bypasses the ICO container logic entirely. It runs the High-Quality Scaling Engine on the image and uses the native GDI+ `GetEncoderClsid` to export 8 distinct files appended with their dimensions (e.g., `output_256x256.jpg`, `output_128x128.jpg`, etc.). This acts as a blazing fast, multi-format batch-resizer!

---

## 3. Usage Guide

### Basic Command Line Syntax
```cmd
icon_maker.exe <input_file(s)> [output_file] [options]
```

*Note: The tool now supports ingesting multiple input files simultaneously. If multiple input files are provided, or if the `output_file` parameter is completely omitted, the tool acts as an autonomous **Batch Processor**!*
* *For an `.exe` or `.dll`, it creates a subfolder and extracts **all** embedded icons, bitmaps, and raw payloads!*
* *For standard images (or an `.ico`), it automatically converts the image and generates **1 file in every supported format** (.ico, .png, .jpg, .bmp, .tiff, .webp) directly into the originating directory!*

### Options
* `--remove-halo` : Strips magenta/pink backgrounds (Legacy color key)
* `--remove-bg` : Auto-removes background by sampling all 8 edges
* `--remove-bg-white` : Removes solid white backgrounds
* `--remove-bg-black` : Removes solid black backgrounds
* `--remove-bg-tl` : Removes background using the Top-Left pixel color
* `--remove-bg-tr` : Removes background using the Top-Right pixel color
* `--remove-bg-bl` : Removes background using the Bottom-Left pixel color
* `--remove-bg-br` : Removes background using the Bottom-Right pixel color

### Examples

**1. Converting a standard PNG to an Icon**
Automatically reads `logo.png`, scales it to all 8 resolutions, and packages it into `app.ico`.
```cmd
icon_maker.exe logo.png app.ico
```

**2. Specific Background Removal & JPEG Export**
Reads an image, explicitly targets the bottom-left corner's pixel color for the background flood-fill, and exports all 8 scaled variants as JPEG files.
```cmd
icon_maker.exe product.png output.jpg --remove-bg-bl
```

**2. Extracting an Icon from an Executable**
Reads `Photoshop.exe`, locates the highest quality embedded icon in its resources, extracts it, and creates a standalone `.ico` container.
```cmd
icon_maker.exe "C:\Program Files\Adobe\Photoshop.exe" extracted_ps.ico
```

**4. Batch Extraction from a DLL (Drag-and-Drop Mode)**
Extracts all icons, bitmaps, and image payloads natively embedded inside `shell32.dll` directly to a `shell32_Extracted` subfolder.
```cmd
icon_maker.exe C:\Windows\System32\shell32.dll
```

---

## 4. Building from Source

The source code (`main.cpp`) is entirely self-contained. 

**Using MinGW / GCC (Recommended via build.bat):**
A `build.bat` file is included which will compile the code using `g++`.
```cmd
.\build.bat
```

**Using Microsoft Visual C++ (MSVC):**
If you prefer the Microsoft compiler (`cl.exe`), ensure you are running from a Developer Command Prompt.
```cmd
cl.exe /O2 /EHsc main.cpp /Fe"icon_maker.exe" /link gdiplus.lib ole32.lib user32.lib
```

---

## 5. Replaced Legacy Scripts
By utilizing this native CLI tool, the following disparate scripts have now been successfully deleted from the repository and their logic safely integrated into `icon_maker.exe`:
* `Convert-Icon.ps1`, `Fix-Icon32.ps1`, `Fix-IconHalo.ps1`
* `resize_icons.py`, `icon_handler.py`
* `ExtractIcon.ps1`, `IconExtractor_Master.PS1`
* `IconManager.ps1` (and all V3/New variants)
* `GUI_IconExtractor_v1.0.py`, `IconExtractor_v1.1.py`, `IconExtractionScript.py`
* `Icon_Explorer_BACKUP_WORKING.PS1`, `extract_icon_temp.ps1`
* `IconSetter.PS1`
* Legacy python scrapers (`adsicon.py`, `isapicon.py`, `sspicon.py`, `unicon.py`)
