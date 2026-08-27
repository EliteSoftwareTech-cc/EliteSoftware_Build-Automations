# ==============================================================================
# MinGW Makefile for File Splitter Application & C++ Unit Test Runner
# Target Compiler: MinGW-w64 g++ (C++17)
# ==============================================================================

# Toolchain Definitions
CXX      := g++
WINDRES  := windres
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -DUNICODE -D_UNICODE -Iinclude
LDFLAGS  := -mwindows -municode -lcomctl32 -lcomdlg32 -lgdi32 -luser32 -luxtheme -lshell32 -lshlwapi -lpsapi -lole32 -loleaut32

# Directory Definitions
SRC_DIR  := src
INC_DIR  := include
RES_DIR  := res

# Executable Targets
TEST_TARGET := test_engine.exe
GUI_TARGET  := FileSplitter.exe
RES_OBJ     := $(RES_DIR)/FileSplitter.res.o

# Source Files for GUI Target
GUI_SRCS    := $(SRC_DIR)/main.cpp \
               $(SRC_DIR)/AppWindow.cpp \
               $(SRC_DIR)/Dialogs.cpp \
               $(SRC_DIR)/Logger.cpp \
               $(SRC_DIR)/TextSplitterEngine.cpp

# Header Files
GUI_HDRS    := $(INC_DIR)/AppWindow.h \
               $(INC_DIR)/Dialogs.h \
               $(INC_DIR)/Logger.h \
               $(INC_DIR)/Resource.h \
               $(INC_DIR)/TextSplitterEngine.h

# Shell Compatibility Helper
ifeq ($(OS),Windows_NT)
    RM_CMD = del /Q /F test_engine.exe FileSplitter.exe res\FileSplitter.res.o 2>NUL || exit 0
else
    RM_CMD = rm -f $(TEST_TARGET) $(GUI_TARGET) $(RES_OBJ)
endif

# Phony Targets
.PHONY: all test gui clean help

# Default Target
all: gui test

# ------------------------------------------------------------------------------
# M1 Unit Test Binary Target
# Compiles src/TextSplitterEngine.cpp and src/test_main.cpp into test_engine.exe
# ------------------------------------------------------------------------------
$(TEST_TARGET): $(SRC_DIR)/TextSplitterEngine.cpp $(SRC_DIR)/test_main.cpp $(INC_DIR)/TextSplitterEngine.h
	@echo [BUILD] Compiling C++ Unit Test Runner: $(TEST_TARGET)...
	$(CXX) -std=c++17 -O2 -Wall -Wextra -Iinclude $(SRC_DIR)/TextSplitterEngine.cpp $(SRC_DIR)/test_main.cpp -o $(TEST_TARGET)
	@echo [BUILD] Successfully built $(TEST_TARGET).

# ------------------------------------------------------------------------------
# Resource Compilation Target
# ------------------------------------------------------------------------------
$(RES_OBJ): $(RES_DIR)/FileSplitter.rc $(RES_DIR)/FileSplitter.manifest $(RES_DIR)/FileSplitter.ico $(INC_DIR)/Resource.h
	@echo [BUILD] Compiling Win32 Resources: $(RES_OBJ)...
	$(WINDRES) $(RES_DIR)/FileSplitter.rc -O coff -o $(RES_OBJ)

# ------------------------------------------------------------------------------
# M3/M4 Win32 GUI Executable Target
# Compiles full Win32 GUI application adhering to EliteSoftware guidelines
# ------------------------------------------------------------------------------
$(GUI_TARGET): $(GUI_SRCS) $(GUI_HDRS) $(RES_OBJ)
	@echo [BUILD] Compiling Win32 GUI Executable: $(GUI_TARGET)...
	$(CXX) $(CXXFLAGS) $(GUI_SRCS) $(RES_OBJ) -o $(GUI_TARGET) $(LDFLAGS)
	@echo [BUILD] Successfully built $(GUI_TARGET).

gui: $(GUI_TARGET)

# Automated Test Execution Target
test: $(TEST_TARGET)
	@echo [TEST] Executing C++ Engine Unit Tests...
	./$(TEST_TARGET)

# Clean Build Artifacts
clean:
	@echo [CLEAN] Removing build artifacts and test executables...
	-$(RM_CMD)
	@echo [CLEAN] Clean complete.

# Help Target
help:
	@echo File Splitter Makefile Targets:
	@echo   make gui    - Build M3/M4 Win32 GUI application (FileSplitter.exe)
	@echo   make test   - Build and run M1 C++ engine unit tests
	@echo   make all    - Build GUI and run unit tests
	@echo   make clean  - Remove built executables and object files
