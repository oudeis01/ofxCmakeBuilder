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
SCRIPTS_DIR="$OF_ROOT/scripts/linux"
mkdir -p "$SCRIPTS_DIR"

echo "Installing utility scripts..."
cp "$SCRIPT_DIR/scripts/generateCMake.sh" "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR/generateCMake.sh"
echo "Installed: generateCMake.sh"

# 3. Create buildAllExamples script
echo "Creating buildAllExamples_cmake.sh..."
cat > "$SCRIPTS_DIR/buildAllExamples_cmake.sh" << 'EOF'
#!/bin/bash

# Build all openFrameworks examples using CMake

export LC_ALL=C

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
OF_ROOT="$(cd $(dirname $0)/../..; pwd -P)"

echo "Building all openFrameworks examples with CMake..."
echo "openFrameworks root: $OF_ROOT"

TOTAL=0
SUCCESS=0
FAILED=0

for category in $(find "$OF_ROOT/examples" -maxdepth 1 -type d); do
    if [ "$(basename $category)" = "examples" ] || [ "$(basename $category)" = "android" ] || [ "$(basename $category)" = "ios" ] || [ "$(basename $category)" = "tvOS" ]; then
        continue
    fi
    
    echo "Processing category: $(basename $category)"
    
    for example in $(find "$category" -maxdepth 1 -type d); do
        if [ "$example" = "$category" ]; then
            continue
        fi
        
        if [ -d "$example/src" ]; then
            EXAMPLE_NAME="$(basename $example)"
            echo "  Building: $EXAMPLE_NAME"
            
            cd "$example"
            
            # Generate CMakeLists.txt if not exists
            if [ ! -f "CMakeLists.txt" ]; then
                "$SCRIPT_DIR/generateCMake.sh" "." > /dev/null
            fi
            
            # Build
            mkdir -p build
            cd build
            if cmake .. > /dev/null 2>&1 && make -j$(nproc) > /dev/null 2>&1; then
                echo "    Success: $EXAMPLE_NAME"
                SUCCESS=$((SUCCESS + 1))
            else
                echo "    Failed: $EXAMPLE_NAME"
                FAILED=$((FAILED + 1))
            fi
            
            TOTAL=$((TOTAL + 1))
        fi
    done
done

echo ""
echo "Build Summary:"
echo "   Total: $TOTAL"
echo "   Success: $SUCCESS"
echo "   Failed: $FAILED"
echo "   Success Rate: $(( SUCCESS * 100 / TOTAL ))%"
EOF

chmod +x "$SCRIPTS_DIR/buildAllExamples_cmake.sh"
echo "Created: buildAllExamples_cmake.sh"

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
echo "Next Steps:"
echo "1. Generate CMakeLists.txt for existing projects:"
echo "   cd $OF_ROOT"
echo "   scripts/linux/generateCMake.sh examples/3d/3DPrimitivesExample"
echo "   # or for all examples:"
echo "   scripts/linux/generateCMake.sh all"
echo ""
echo "2. Build a project:"
echo "   cd examples/3d/3DPrimitivesExample"
echo "   mkdir build && cd build"
echo "   cmake .. && make -j$(nproc)"
echo "   make run"
echo ""
echo "3. Test all examples:"
echo "   scripts/linux/buildAllExamples_cmake.sh"
echo ""
