#!/bin/bash
# set -x  # Enable shell debugging (disabled for cleaner output)

# ===================================
# openFrameworks CMake Build All Script
# 
# This script builds all openFrameworks examples using CMake
# with colored output for errors and detailed reporting.
# ===================================

# Remove set -e to prevent premature exit

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

# Build each example
for i in "${!EXAMPLE_DIRS[@]}"; do
    example_dir="${EXAMPLE_DIRS[$i]}"
    example_name=$(basename "$example_dir")
    category_name=$(basename $(dirname "$example_dir"))
    index=$((i + 1))

    # Create build directory
    build_dir="$example_dir/build"
    mkdir -p "$build_dir"

    # Run CMake configuration and build
    pushd "$build_dir" > /dev/null 2>&1
    cmake .. > /dev/null 2>&1 && make -j$PARALLEL_JOBS > /dev/null 2>&1
    build_status=$?
    popd > /dev/null 2>&1

    if [ $build_status -eq 0 ]; then
        echo -e "${GREEN}[OK] $category_name/$example_name${NC}"
        successful_builds=$((successful_builds + 1))
    else
        echo -e "${RED}[Fail] $category_name/$example_name${NC}"
        failed_builds=$((failed_builds + 1))
        FAILED_EXAMPLES+=("$category_name/$example_name")
    fi

done

echo ""
# Summary
echo -e "${PURPLE}Build Summary:${NC}"
echo -e "${GREEN}Successful builds: $successful_builds${NC}"
echo -e "${RED}Failed builds: $failed_builds${NC}"

if [ $failed_builds -gt 0 ]; then
    echo -e "${RED}Failed examples:${NC}"
    for failed in "${FAILED_EXAMPLES[@]}"; do
        echo -e "  $failed"
    done
fi


## TODO: check the failing examples and fix it in the main core cmake module