# Icon Image Management CLI Tool

A native Win32 C++ CLI utility for pragmatically converting images into high-quality `.ico` icon containers with multiple resolutions and proper transparency.

## Features
- **Supported Formats**: Reads any image format supported by Windows GDI+ (PNG, JPG, BMP, GIF, TIFF, etc.).
- **Multiple Resolutions**: Automatically scales the input image to standard icon sizes: `16x16`, `24x24`, `32x32`, `48x48`, `64x64`, `96x96`, `128x128`, and `256x256` (replacing the batch resizing logic found in `resize_icons.py`).
- **High-Quality Scaling**: Uses GDI+ HighQualityBicubic interpolation to scale down the image, preserving sharp details and smooth edges.
- **Advanced Background Removal**:
  - `--remove-halo`: Automatically identify and strip out magenta/pink backgrounds by calculating the Euclidean distance from pure magenta (consolidating the logic from `Convert-Icon.ps1` and `Fix-IconHalo.ps1`).
  - `--remove-bg`: Smart flood-fill algorithm that samples all 8 edges/corners to remove solid backgrounds while preserving the center subject.
  - Target specific background colors with `--remove-bg-white`, `--remove-bg-black`, or pin it to a corner with `--remove-bg-tl` (Top-Left), `--remove-bg-tr`, `--remove-bg-bl`, or `--remove-bg-br`.
- **Direct EXE/DLL Extraction & Drag-and-Drop**: If the input file is an `.exe` or `.dll` and no output path is provided, the tool enters **Batch Extraction** mode! It will automatically create a `<filename>_Extracted` subfolder and use `PrivateExtractIconsW` and `EnumResourceNamesW` to recursively pull out *every single icon*, `RT_BITMAP`, `RT_RCDATA`, `PNG`, and `IMAGE` payload embedded in the binary (replacing the extraction logic in `ExtractIcon.ps1`, `IconExtractor_Master.PS1` and the various `.py` extractor scripts). If an output `.ico` is provided, it extracts just the single highest-resolution icon.
- **Multi-Format Output (ICO, PNG, JPG, BMP, TIFF, WebP)**:
  - If output is `.ico`, generates a multi-resolution icon container (DIB payloads for `<= 128x128` and PNG payload for `256x256`).
  - If output is `.png`, `.jpg`, `.bmp`, `.tiff`, or `.webp`, generates all 8 scaled resolutions as separate files (e.g., `output_256x256.jpg`, `output_128x128.jpg`).
- **Native execution**: Written in pure C++ Win32 using GDI+, with zero external third-party dependencies (no libpng, no Qt, etc.).

## Usage

Run the executable from the command line. You can pass a single input file, multiple input files, or an explicit input and output file pairing!

```cmd
icon_maker.exe <input_file(s)> [output_file] [options]
```

*Note: If multiple input files are provided, or if the `output_file` is completely omitted, the tool automatically acts as a **Batch Processor**. For executable files, it extracts all embedded resources to a subfolder. For image files, it outputs 1 file in every supported format (ICO, PNG, JPG, BMP, TIFF, WebP) directly into the originating directory!*

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

**1. Converting a standard PNG to a Multi-Res ICO**
```cmd
icon_maker.exe logo.png app_icon.ico
```

**2. Smart Background Removal & PNG Export**
```cmd
icon_maker.exe flat_logo.jpg output.png --remove-bg
```

**3. Specific Background Removal & JPEG Export**
```cmd
icon_maker.exe product.png output.jpg --remove-bg-bl
```

## Compilation

A `build.bat` script is provided which uses `g++` (MinGW) to compile the tool.

```cmd
.\build.bat
```

Alternatively, if you're using Microsoft Visual Studio, you can compile it using `cl.exe`:
```cmd
cl.exe /O2 main.cpp /Fe"icon_maker.exe" /link gdiplus.lib ole32.lib user32.lib
```
