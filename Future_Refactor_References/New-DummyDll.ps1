function New-DummyDll {
    param(
        [string]$Path
    )

    $dosStub = [System.Text.Encoding]::ASCII.GetBytes(
        "MZ" + # Signature
        [char]0x90 + [char]0x00 + [char]0x03 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x04 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0xFF + [char]0xFF + [char]0x00 + [char]0x00 +
        [char]0xB8 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x40 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x80 + [char]0x00 + [char]0x00 + [char]0x00 +
        [char]0x0E + [char]0x1F + [char]0xBA + [char]0x0E + [char]0x00 + [char]0xB4 + [char]0x09 + [char]0xCD +
        [char]0x21 + [char]0xB8 + [char]0x01 + [char]0x4C + [char]0xCD + [char]0x21 +
        "This program cannot be run in DOS mode.`r`n$" +
        [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00 + [char]0x00
    )

    $peSignature = [System.Text.Encoding]::ASCII.GetBytes("PE" + [char]0x00 + [char]0x00)

    # COFF Header
    $coffHeader = New-Object byte[] 20
    # Machine = I386
    [System.BitConverter]::GetBytes([UInt16]0x14c).CopyTo($coffHeader, 0)
    # NumberOfSections = 0
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($coffHeader, 2)
    # TimeDateStamp
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($coffHeader, 4)
    # PointerToSymbolTable
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($coffHeader, 8)
    # NumberOfSymbols
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($coffHeader, 12)
    # SizeOfOptionalHeader
    [System.BitConverter]::GetBytes([UInt16]224).CopyTo($coffHeader, 16)
    # Characteristics
    [System.BitConverter]::GetBytes([UInt16]0x2102).CopyTo($coffHeader, 18) # DLL, Executable

    # PE Optional Header
    $peOptionalHeader = New-Object byte[] 224
    # Magic
    [System.BitConverter]::GetBytes([UInt16]0x10b).CopyTo($peOptionalHeader, 0)
    # MajorLinkerVersion
    $peOptionalHeader[2] = 0
    # MinorLinkerVersion
    $peOptionalHeader[3] = 0
    # SizeOfCode
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 4)
    # SizeOfInitializedData
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 8)
    # SizeOfUninitializedData
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 12)
    # AddressOfEntryPoint
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 16)
    # BaseOfCode
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 20)
    # BaseOfData
    [System.BitConverter]::GetBytes([UInt32]0x1000).CopyTo($peOptionalHeader, 24)
    # ImageBase
    [System.BitConverter]::GetBytes([UInt32]0x10000000).CopyTo($peOptionalHeader, 28)
    # SectionAlignment
    [System.BitConverter]::GetBytes([UInt32]0x1000).CopyTo($peOptionalHeader, 32)
    # FileAlignment
    [System.BitConverter]::GetBytes([UInt32]0x200).CopyTo($peOptionalHeader, 36)
    # MajorOperatingSystemVersion
    [System.BitConverter]::GetBytes([UInt16]4).CopyTo($peOptionalHeader, 40)
    # MinorOperatingSystemVersion
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($peOptionalHeader, 42)
    # MajorImageVersion
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($peOptionalHeader, 44)
    # MinorImageVersion
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($peOptionalHeader, 46)
    # MajorSubsystemVersion
    [System.BitConverter]::GetBytes([UInt16]4).CopyTo($peOptionalHeader, 48)
    # MinorSubsystemVersion
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($peOptionalHeader, 50)
    # Win32VersionValue
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 52)
    # SizeOfImage
    [System.BitConverter]::GetBytes([UInt32]0x1000).CopyTo($peOptionalHeader, 56)
    # SizeOfHeaders
    [System.BitConverter]::GetBytes([UInt32]0x200).CopyTo($peOptionalHeader, 60)
    # CheckSum
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 64)
    # Subsystem
    [System.BitConverter]::GetBytes([UInt16]2).CopyTo($peOptionalHeader, 68)
    # DllCharacteristics
    [System.BitConverter]::GetBytes([UInt16]0).CopyTo($peOptionalHeader, 70)
    # SizeOfStackReserve
    [System.BitConverter]::GetBytes([UInt32]0x100000).CopyTo($peOptionalHeader, 72)
    # SizeOfStackCommit
    [System.BitConverter]::GetBytes([UInt32]0x1000).CopyTo($peOptionalHeader, 76)
    # SizeOfHeapReserve
    [System.BitConverter]::GetBytes([UInt32]0x100000).CopyTo($peOptionalHeader, 80)
    # SizeOfHeapCommit
    [System.BitConverter]::GetBytes([UInt32]0x1000).CopyTo($peOptionalHeader, 84)
    # LoaderFlags
    [System.BitConverter]::GetBytes([UInt32]0).CopyTo($peOptionalHeader, 88)
    # NumberOfRvaAndSizes
    [System.BitConverter]::GetBytes([UInt32]16).CopyTo($peOptionalHeader, 92)

    # Data Directories
    $dataDirectories = New-Object byte[] 128
    
    # Combine all parts
    $peHeader = $peSignature + $coffHeader + $peOptionalHeader + $dataDirectories
    
    # DOS Header needs the address of the PE Header
    [System.BitConverter]::GetBytes([UInt32]$dosStub.Length).CopyTo($dosStub, 0x3c)

    $dllBytes = $dosStub + $peHeader
    
    [System.IO.File]::WriteAllBytes($Path, $dllBytes)
}
