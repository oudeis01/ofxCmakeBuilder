#!/bin/bash

# ===================================
# openFrameworks CMake Build All Script
# 
# This script builds all openFrameworks examples using CMake
# with colored output for errors and detailed reporting.
# ===================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
OF_ROOT="${OF_ROOT:-$(dirname $(dirname $(dirname $(realpath $0))))}"
PARALLEL_JOBS=4

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}openFrameworks CMake Build All${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${CYAN}openFrameworks root: ${OF_ROOT}${NC}"
echo -e "${CYAN}Parallel build jobs: ${PARALLEL_JOBS}${NC}"
echo ""

# Find all example directories
EXAMPLE_DIRS=()
for category in "$OF_ROOT/examples"/*; do
    if [ -d "$category" ]; then
        for example in "$category"/*; do
            if [ -d "$example" ]; then
                # Check if it has src directory (indicating it's a project)
                if [ -d "$example/src" ]; then
                    EXAMPLE_DIRS+=("$example")
                fi
            fi
        done
    fi
done

# Sort examples for consistent order
IFS=$'\n' EXAMPLE_DIRS=($(sort <<<"${EXAMPLE_DIRS[*]}"))
unset IFS

total_examples=${#EXAMPLE_DIRS[@]}
successful_builds=0
failed_builds=0
FAILED_EXAMPLES=()

echo -e "${PURPLE}Found ${total_examples} examples to build${NC}"
echo ""

# Function to build a single example
build_example() {
    local example_dir="$1"
    local example_name=$(basename "$example_dir")
    local category_name=$(basename $(dirname "$example_dir"))
    local index="$2"
    
    echo -e "${BLUE}[$index/$total_examples] Building: ${category_name}/${example_name}${NC}"
    
    cd "$example_dir"
    
    # Clean any existing build
    rm -rf build
    
    # Create temporary files for capturing output
    local cmake_output=$(mktemp)
    local build_output=$(mktemp)
    
    # Configure with CMake
    if ! cmake -B build . > "$cmake_output" 2>&1; then
        echo -e "${RED}   ❌ CMake configuration failed${NC}"
        echo -e "${RED}   📋 Configuration output:${NC}"
        while IFS= read -r line; do
            echo -e "${RED}      $line${NC}"
        done < "$cmake_output"
        rm -f "$cmake_output" "$build_output"
        return 1
    fi
    
    # Build
    if ! cmake --build build -j$PARALLEL_JOBS > "$build_output" 2>&1; then
        echo -e "${RED}   ❌ Build failed${NC}"
        echo -e "${RED}   🔨 Build output:${NC}"
        while IFS= read -r line; do
            # Highlight error lines in red
            if [[ "$line" =~ ^.*error:.*$ ]] || [[ "$line" =~ ^.*Error.*$ ]] || [[ "$line" =~ ^.*failed.*$ ]]; then
                echo -e "${RED}      $line${NC}"
            elif [[ "$line" =~ ^.*warning:.*$ ]] || [[ "$line" =~ ^.*Warning.*$ ]]; then
                echo -e "${YELLOW}      $line${NC}"
            else
                echo "      $line"
            fi
        done < "$build_output"
        rm -f "$cmake_output" "$build_output"
        return 1
    fi
    
    echo -e "${GREEN}   ✅ Build successful${NC}"
    rm -f "$cmake_output" "$build_output"
    return 0
}

# Main build loop
for i in "${!EXAMPLE_DIRS[@]}"; do
    example_dir="${EXAMPLE_DIRS[$i]}"
    example_name=$(basename "$example_dir")
    category_name=$(basename $(dirname "$example_dir"))
    index=$((i + 1))
    
    if build_example "$example_dir" "$index"; then
        ((successful_builds++))
    else
        ((failed_builds++))
        FAILED_EXAMPLES+=("$category_name/$example_name")
    fi
    
    echo ""
done

# Final summary
echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}Build Summary${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}✅ Successful builds: $successful_builds${NC}"
echo -e "${RED}❌ Failed builds: $failed_builds${NC}"
echo -e "${PURPLE}📊 Total examples: $total_examples${NC}"

if [ $failed_builds -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ Failed examples:${NC}"
    for failed_example in "${FAILED_EXAMPLES[@]}"; do
        echo -e "${RED}   - $failed_example${NC}"
    done
fi

# Calculate success rate
if [ $total_examples -gt 0 ]; then
    success_rate=$((successful_builds * 100 / total_examples))
    echo -e "${CYAN}📈 Success rate: ${success_rate}%${NC}"
fi

echo ""

# Exit with appropriate code
if [ $failed_builds -eq 0 ]; then
    echo -e "${GREEN}🎉 All builds successful!${NC}"
    exit 0
else
    echo -e "${RED}💥 Some builds failed${NC}"
    exit 1
fi
