#!/bin/bash

# openFrameworks CMake System Installer
# Installs modular CMake build system for openFrameworks

set -e

# Check if argument provided
if [ $# -eq 0 ]; then
    printf "Usage: $0 <openframeworks_root_path>\n"
    printf "\n"
    printf "Examples:\n"
    printf "  $0 /path/to/of_v20250319_linux64_gcc6_release\n"
    printf "  $0 ~/openframeworks\n"
    printf "  $0 .\n"
    exit 1
fi

# Get and validate openFrameworks root path
OF_ROOT="$(cd "$1" && pwd -P 2>/dev/null)" || {
    printf "Error: Invalid path: $1\n"
    exit 1
}

printf "Target openFrameworks root: $OF_ROOT\n"

# Validate openFrameworks installation
if [ ! -d "$OF_ROOT/libs/openFrameworks" ]; then
    printf "Error: Invalid openFrameworks installation!\n"
    printf "libs/openFrameworks directory not found in: $OF_ROOT\n"
    exit 1
fi

if [ ! -d "$OF_ROOT/examples" ]; then
    printf "Error: Invalid openFrameworks installation!\n"
    printf "examples directory not found in: $OF_ROOT\n"
    exit 1
fi

printf "Valid openFrameworks installation detected\n"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf "Installing CMake System...\n"

# Update installation paths
CMAKE_MODULE_DIR="$OF_ROOT/libs/openFrameworks/cmake"
SCRIPTS_DIR="$OF_ROOT/scripts/cmake-scripts"

# Create necessary directories
mkdir -p "$CMAKE_MODULE_DIR"
mkdir -p "$SCRIPTS_DIR"

# 1. Install main CMake module
printf "Installing main CMake module...\n"
cp "$SCRIPT_DIR/cmake-modules/openFrameworks.cmake" "$CMAKE_MODULE_DIR/"
printf "Installed: $CMAKE_MODULE_DIR/openFrameworks.cmake\n"

printf "Installing platform modules...\n"
mkdir -p "$CMAKE_MODULE_DIR/platform"
cp "$SCRIPT_DIR/cmake-modules/platform/"*.cmake "$CMAKE_MODULE_DIR/platform/"
printf "Installed: Platform-specific modules\n"
printf "\t $CMAKE_MODULE_DIR/platform/*\n"

# 2. Install scripts
printf "Installing utility scripts...\n"
cp "$SCRIPT_DIR/scripts/generateCMake.sh" "$SCRIPTS_DIR/generateCMake.sh"
chmod +x "$SCRIPTS_DIR/generateCMake.sh"
printf "Installed: $SCRIPTS_DIR/generateCMake.sh\n"

cp "$SCRIPT_DIR/scripts/buildAll.sh" "$SCRIPTS_DIR/buildAll.sh"
chmod +x "$SCRIPTS_DIR/buildAll.sh"
printf "Installed: buildAll.sh\n"

cp "$SCRIPT_DIR/scripts/buildAndTestAll.sh" "$SCRIPTS_DIR/buildAndTestAll.sh"
chmod +x "$SCRIPTS_DIR/buildAndTestAll.sh"
printf "Installed: buildAndTestAll.sh\n"

printf "Testing Installation...\n"

# Test with a simple example
TEST_EXAMPLE="$OF_ROOT/examples/3d/3DPrimitivesExample"
if [ -d "$TEST_EXAMPLE" ]; then
    printf "Testing installation with 3DPrimitivesExample...\n"
    cd "$TEST_EXAMPLE"

    # Generate CMakeLists.txt
    "$SCRIPTS_DIR/generateCMake.sh" "." > /dev/null 2>&1

    # Try to configure
    mkdir -p build
    cd build
    if cmake -DCMAKE_MODULE_PATH="$CMAKE_MODULE_DIR" .. > /dev/null 2>&1; then
        printf "CMake configuration test passed\n"
    else
        printf "Warning: CMake configuration test failed, but installation completed\n"
    fi
else
    printf "Warning: Test example not found, skipping test\n"
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
echo "   scripts/cmake-scripts/generateCMake.sh examples/3d/3DPrimitivesExample"
echo "   # or for all examples:"
echo "   scripts/cmake-scripts/generateCMake.sh all"
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
