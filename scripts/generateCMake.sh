#!/bin/bash

# CMakeLists.txt Generator for openFrameworks Projects
# Cross-platform compatible version with improved macOS support
# This script generates optimized CMakeLists.txt files for existing projects

export LC_ALL=C

SCRIPT_DIR="$(cd $(dirname $0); pwd)"

# auto detect OF_ROOT
if [ -f "$(dirname $0)/../../libs/openFrameworks/cmake/openFrameworks.cmake" ]; then
    OF_ROOT="$(cd $(dirname $0)/../..; pwd -P)"
elif [ -f "$(dirname $0)/../../../libs/openFrameworks/cmake/openFrameworks.cmake" ]; then
    OF_ROOT="$(cd $(dirname $0)/../../..; pwd -P)"
else
    # Try to find a sibling directory that looks like OF
    PARENT_DIR="$(cd $(dirname $0)/../..; pwd -P)"
    for dir in "$PARENT_DIR"/*; do
        if [ -d "$dir/libs/openFrameworks/cmake" ]; then
            OF_ROOT="$(cd "$dir"; pwd -P)"
            break
        fi
    done
    
    if [ -z "$OF_ROOT" ]; then
        if [ -n "$OF_ROOT" ] && [ -f "$OF_ROOT/libs/openFrameworks/cmake/openFrameworks.cmake" ]; then
            OF_ROOT="$(cd "$OF_ROOT"; pwd -P)"
        else
            echo "[Error] Cannot find openFrameworks installation"
            echo "   Currently detected OF_ROOT: $OF_ROOT"
            echo "   Please set OF_ROOT environment variable: export OF_ROOT=/path/to/of"
            exit 1
        fi
    fi
fi

echo "   openFrameworks CMakeLists.txt Generator (Cross-Platform)"
echo "   openFrameworks root: $OF_ROOT"

# calculate the relative path cross platform
calculate_relative_path() {
    local target="$1"
    local base="$2"
    
    # return absolute path
    target="$(cd "$target" && pwd -P)"
    base="$(cd "$base" && pwd -P)"
    
    # simple case: target is a parent directory of base
    local temp_base="$base"
    local depth=0
    
    while [ "$temp_base" != "/" ] && [ "$temp_base" != "$target" ]; do
        temp_base="$(dirname "$temp_base")"
        depth=$((depth + 1))
        if [ $depth -gt 10 ]; then  # prevent infinite loop
            break
        fi
    done
    
    if [ "$temp_base" = "$target" ]; then
        # if target is a parent directory of base
        local relative_path=""
        for ((i=0; i<depth; i++)); do
            if [ -z "$relative_path" ]; then
                relative_path=".."
            else
                relative_path="$relative_path/.."
            fi
        done
        echo "$relative_path"
        return
    fi
    
    # headacke: find common path
    local common=""
    local target_parts=()
    local base_parts=()
    
    # split path by '/'
    IFS='/' read -ra target_parts <<< "$target"
    IFS='/' read -ra base_parts <<< "$base"
    
    # find common prefix
    local i=0
    while [ $i -lt ${#target_parts[@]} ] && [ $i -lt ${#base_parts[@]} ]; do
        if [ "${target_parts[$i]}" = "${base_parts[$i]}" ]; then
            ((i++))
        else
            break
        fi
    done
    
    # build relative path from base to target
    local relative_path=""
    
    # trace back from base to common
    local j=$((${#base_parts[@]} - 1))
    while [ $j -gt $i ]; do
        if [ -n "$relative_path" ]; then
            relative_path="../$relative_path"
        else
            relative_path=".."
        fi
        ((j--))
    done
    
    # trace forward from common to target
    j=$i
    while [ $j -lt ${#target_parts[@]} ]; do
        if [ -n "$relative_path" ]; then
            relative_path="$relative_path/${target_parts[$j]}"
        else
            relative_path="${target_parts[$j]}"
        fi
        ((j++))
    done
    
    # if empty, set to current directory
    if [ -z "$relative_path" ]; then
        relative_path="."
    fi
    
    echo "$relative_path"
}

# for macOS and Linux compatibility
get_absolute_path() {
    local path="$1"
    
    if [ -d "$path" ]; then
        cd "$path" && pwd -P
    elif [ -f "$path" ]; then
        cd "$(dirname "$path")" && echo "$(pwd -P)/$(basename "$path")"
    else
        echo "Error: Path does not exist: $path" >&2
        return 1
    fi
}

# detects platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)    echo "macOS" ;;
        Linux*)     echo "Linux" ;;
        CYGWIN*|MINGW*|MSYS*)    echo "Windows" ;;
        *)          echo "Unknown" ;;
    esac
}


# Generates CMakeLists.txt for a given project directory
generate_cmakelists() {
    local PROJECT_DIR="$1"
    local PROJECT_NAME
    local RELATIVE_OF_ROOT
    local PLATFORM
    
    PLATFORM=$(detect_platform)
    echo "     Detected platform: $PLATFORM"
    
    # use basename to get the project name
    if [ "$PROJECT_DIR" = "." ]; then
        PROJECT_NAME="$(basename "$PWD")"
        PROJECT_DIR="$PWD"
    else
        PROJECT_NAME="$(basename "$PROJECT_DIR")"
        PROJECT_DIR="$(get_absolute_path "$PROJECT_DIR")"
    fi
    
    # get the relative path
    RELATIVE_OF_ROOT=$(calculate_relative_path "$OF_ROOT" "$PROJECT_DIR")
    
    echo "     Project: $PROJECT_NAME"
    echo "     Project Dir: $PROJECT_DIR"
    echo "     Relative OF Root: $RELATIVE_OF_ROOT"
    echo "     Generating cross-platform CMakeLists.txt..."
    
    cat > "$PROJECT_DIR/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.10)

# set project name
project($PROJECT_NAME)

# Cross-platform path handling
if(WIN32)
    # Windows path separator handling
    string(REPLACE "\\\\" "/" CMAKE_CURRENT_SOURCE_DIR_NORMALIZED "\${CMAKE_CURRENT_SOURCE_DIR}")
    set(OF_CMAKE_PATH "\${CMAKE_CURRENT_SOURCE_DIR_NORMALIZED}/$RELATIVE_OF_ROOT/libs/openFrameworks/cmake/openFrameworks.cmake")
else()
    # Unix-like systems (Linux, macOS)
    set(OF_CMAKE_PATH "\${CMAKE_CURRENT_SOURCE_DIR}/$RELATIVE_OF_ROOT/libs/openFrameworks/cmake/openFrameworks.cmake")
endif()

# Load openFrameworks core settings
include("\${OF_CMAKE_PATH}")

# openFrameworks project setup
of_setup_project()

# ========================================
# External Libraries (Optional)
# ========================================

# Example: Add custom library
# of_add_custom_library(\${PROJECT_NAME} "MyLib" "/path/to/lib.a" "/path/to/headers")

# Example: Add compile definitions
# target_compile_definitions(\${PROJECT_NAME} PRIVATE MY_CUSTOM_DEFINE=1)

# Example: Add include directories
# target_include_directories(\${PROJECT_NAME} PRIVATE "custom_headers/")

# Platform-specific configurations
if(APPLE)
    # macOS specific settings
    message(STATUS "Configuring for macOS")
    # Add macOS specific flags if needed
elseif(UNIX AND NOT APPLE)
    # Linux specific settings
    message(STATUS "Configuring for Linux")
    # Add Linux specific flags if needed
elseif(WIN32)
    # Windows specific settings
    message(STATUS "Configuring for Windows")
    # Add Windows specific flags if needed
endif()
EOF

    echo "     [Success] Generated CMakeLists.txt for $PROJECT_NAME"
}

# Validates all built-in examples
validate_examples() {
    echo "Validating all examples..."
    local TOTAL=0
    local SUCCESS=0
    local FAILED=0
    
    for category in $(find "$OF_ROOT/examples" -maxdepth 1 -type d); do
        if [ "$(basename $category)" = "examples" ] || [ "$(basename $category)" = "android" ] || [ "$(basename $category)" = "ios" ] || [ "$(basename $category)" = "tvOS" ]; then
            continue
        fi
        
        echo "   Validating category: $(basename $category)"
        
        for example in $(find "$category" -maxdepth 1 -type d); do
            if [ "$example" = "$category" ]; then
                continue
            fi
            
            if [ -d "$example/src" ]; then
                EXAMPLE_NAME="$(basename $example)"
                
                # Test relative path calculation
                RELATIVE_TEST=$(calculate_relative_path "$OF_ROOT" "$example")
                CMAKE_FILE="$RELATIVE_TEST/libs/openFrameworks/cmake/openFrameworks.cmake"
                
                if [ -f "$example/$CMAKE_FILE" ]; then
                    echo "    [OK] $EXAMPLE_NAME: Path calculation OK"
                    SUCCESS=$((SUCCESS + 1))
                else
                    echo "    [Fail] $EXAMPLE_NAME: Path calculation failed ($CMAKE_FILE)"
                    FAILED=$((FAILED + 1))
                fi
                
                TOTAL=$((TOTAL + 1))
            fi
        done
    done
    
    echo ""
    echo "Validation Summary:"
    echo "   Total: $TOTAL"
    echo "   Success: $SUCCESS"
    echo "   Failed: $FAILED"
    if [ $TOTAL -gt 0 ]; then
        echo "   Success Rate: $(( SUCCESS * 100 / TOTAL ))%"
    fi
}

# main script execution starts here
if [ $# -eq 0 ]; then
    echo "Usage: $0 [project_directory|'all'|'validate']"
    echo ""
    echo "Examples:"
    echo "  $0 ../../examples/3d/3DPrimitivesExample"
    echo "  $0 .                                      # Current directory"
    echo "  $0 all                                    # Generate for all examples"
    echo "  $0 validate                               # Test path calculations"
    echo ""
    echo "Platform Support: macOS, Linux, Windows (MSYS2/MinGW)"
    exit 1
fi

if [ "$1" = "validate" ]; then
    validate_examples
    exit 0
elif [ "$1" = "all" ]; then
    echo "Generating CMakeLists.txt for all examples..."
    TOTAL=0
    
    for category in $(find "$OF_ROOT/examples" -maxdepth 1 -type d); do
        if [ "$(basename $category)" = "examples" ] || [ "$(basename $category)" = "android" ] || [ "$(basename $category)" = "ios" ] || [ "$(basename $category)" = "tvOS" ]; then
            continue
        fi
        
        echo "   Processing category: $(basename $category)"
        
        for example in $(find "$category" -maxdepth 1 -type d); do
            if [ "$example" = "$category" ]; then
                continue
            fi
            
            if [ -d "$example/src" ]; then
                generate_cmakelists "$example"
                TOTAL=$((TOTAL + 1))
            fi
        done
    done
    
    echo ""
    echo "   [Success] Generated CMakeLists.txt for $TOTAL projects!"
    echo "   Ready for build"
else
    PROJECT_DIR="$1"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "[Error] Directory not found: $PROJECT_DIR"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_DIR/src" ]; then
        echo "[Error] No src directory found in: $PROJECT_DIR"
        echo "   This doesn't appear to be an openFrameworks project"
        exit 1
    fi
    
    generate_cmakelists "$PROJECT_DIR"
    echo ""
    echo "   [Done] You can now build with:"
    echo "   cd $PROJECT_DIR && mkdir -p build && cd build"
    echo "   cmake .. && make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
    echo ""
    echo "   Platform detected: $(detect_platform)"
fi
