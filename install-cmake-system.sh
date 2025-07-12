#!/bin/bash

# openFrameworks CMake System Installer
# Installs modular CMake build system for openFrameworks

set -e

# Check if argument provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <openframeworks_root_path>"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/of_v20250319_linux64_gcc6_release"
    echo "  $0 ~/openframeworks"
    echo "  $0 ."
    exit 1
fi

# Get and validate openFrameworks root path
OF_ROOT="$(cd "$1" && pwd -P 2>/dev/null)" || {
    echo "Error: Invalid path: $1"
    exit 1
}

echo "Target openFrameworks root: $OF_ROOT"

# Validate openFrameworks installation
if [ ! -d "$OF_ROOT/libs/openFrameworks" ]; then
    echo "Error: Invalid openFrameworks installation!"
    echo "libs/openFrameworks directory not found in: $OF_ROOT"
    exit 1
fi

if [ ! -d "$OF_ROOT/examples" ]; then
    echo "Error: Invalid openFrameworks installation!"
    echo "examples directory not found in: $OF_ROOT"
    exit 1
fi

echo "Valid openFrameworks installation detected"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing CMake System..."

# 1. Install main CMake module
CMAKE_MODULE_DIR="$OF_ROOT/libs/openFrameworks/cmake"
mkdir -p "$CMAKE_MODULE_DIR"
mkdir -p "$CMAKE_MODULE_DIR/platform"

echo "Installing main CMake module..."
cp "$SCRIPT_DIR/cmake-modules/openFrameworks.cmake" "$CMAKE_MODULE_DIR/"
echo "Installed: openFrameworks.cmake"

echo "Installing platform modules..."
cp "$SCRIPT_DIR/cmake-modules/platform/"*.cmake "$CMAKE_MODULE_DIR/platform/"
echo "Installed: Platform-specific modules"

# 2. Install scripts
# Detect platform for script directory naming
case "$(uname -s)" in
    Darwin*)    SCRIPTS_DIR="$OF_ROOT/scripts/macos" ;;
    Linux*)     SCRIPTS_DIR="$OF_ROOT/scripts/linux" ;;
    CYGWIN*|MINGW*|MSYS*)    SCRIPTS_DIR="$OF_ROOT/scripts/windows" ;;
    *)          SCRIPTS_DIR="$OF_ROOT/scripts/linux" ;;  # fallback
esac

mkdir -p "$SCRIPTS_DIR"

echo "Installing utility scripts for $(uname -s)..."
cp "$SCRIPT_DIR/scripts/generateCMake.sh" "$SCRIPTS_DIR/generateCMake.sh"
chmod +x "$SCRIPTS_DIR/generateCMake.sh"
echo "Installed: generateCMake.sh (cross-platform compatible)"

# 3. Install improved build and test scripts
echo "Installing improved build scripts..."
cp "$SCRIPT_DIR/scripts/buildAll.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/buildAll.sh"
echo "Installed: buildAll.sh (colored output, detailed error reporting)"

cp "$SCRIPT_DIR/scripts/buildAndTestAll.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/buildAndTestAll.sh"
echo "Installed: buildAndTestAll.sh (automated build and test runner)"

echo "Testing Installation..."

# Test with a simple example
TEST_EXAMPLE="$OF_ROOT/examples/3d/3DPrimitivesExample"
if [ -d "$TEST_EXAMPLE" ]; then
    echo "Testing installation with 3DPrimitivesExample..."
    
    cd "$TEST_EXAMPLE"
    
    # Generate CMakeLists.txt
    "$SCRIPTS_DIR/generateCMake.sh" "." > /dev/null 2>&1
    
    # Try to configure
    mkdir -p build
    cd build
    if cmake .. > /dev/null 2>&1; then
        echo "CMake configuration test passed"
    else
        echo "Warning: CMake configuration test failed, but installation completed"
    fi
else
    echo "Warning: Test example not found, skipping test"
fi

echo "Installation Complete"

echo ""
echo "openFrameworks CMake System installed successfully"
echo ""
echo "Installed Components:"
echo "  - openFrameworks.cmake (main CMake module with cross-platform support)"
echo "  - Platform-specific modules (Darwin.cmake, Linux.cmake, Windows.cmake)"
echo "  - generateCMake.sh (cross-platform CMakeLists.txt generator)"
echo "  - buildAll.sh (build all examples with colored error output)"
echo "  - buildAndTestAll.sh (build and test all examples automatically)"
echo ""
echo "Next Steps:"
echo "1. Generate CMakeLists.txt for existing projects:"
echo "   cd $OF_ROOT"
case "$(uname -s)" in
    Darwin*)    PLATFORM_DIR="macos" ;;
    Linux*)     PLATFORM_DIR="linux" ;;
    CYGWIN*|MINGW*|MSYS*)    PLATFORM_DIR="windows" ;;
    *)          PLATFORM_DIR="linux" ;;
esac
echo "   scripts/$PLATFORM_DIR/generateCMake.sh examples/3d/3DPrimitivesExample"
echo "   # or for all examples:"
echo "   scripts/$PLATFORM_DIR/generateCMake.sh all"
echo ""
echo "2. Build a project:"
echo "   cd examples/3d/3DPrimitivesExample"
echo "   mkdir build && cd build"
echo "   cmake .. && make -j4"
echo "   make run"
echo ""
echo "3. Build all examples (with colored error output):"
echo "   scripts/$PLATFORM_DIR/buildAll.sh"
echo ""
echo "4. Build and test all examples (automated):"
echo "   scripts/$PLATFORM_DIR/buildAndTestAll.sh"
echo ""
