#!/bin/bash
# set -e  # Exit on any error (disabled for cleaner output)

# ===================================
# openFrameworks CMake Build & Test All Script
# 
# This script builds all openFrameworks examples and tests them
# by running each binary for 4 seconds then killing it.
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
OF_ROOT="${OF_ROOT:-$(dirname $(dirname $(realpath $0)))}"
TEST_DURATION=4  # seconds to run each test
PARALLEL_JOBS=4

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}openFrameworks CMake Build & Test All${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${CYAN}openFrameworks root: ${OF_ROOT}${NC}"
echo -e "${CYAN}Test duration per app: ${TEST_DURATION} seconds${NC}"
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
successful_tests=0
failed_builds=0
failed_tests=0
FAILED_EXAMPLES=()
FAILED_TESTS=()

echo -e "${PURPLE}Found ${total_examples} examples to build and test${NC}"
echo ""

# Build and test each example
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
        echo -e "${GREEN}[OK] Build: $category_name/$example_name${NC}"
        ((successful_builds++))
        
        # Test the executable
        pushd "$example_dir" > /dev/null 2>&1
        executable=$(find . -name "$example_name" -type f -executable 2>/dev/null | head -1)
        if [ -n "$executable" ] && [ -f "$executable" ]; then
            # Run the executable in background for TEST_DURATION seconds
            timeout $TEST_DURATION "$executable" > /dev/null 2>&1 &
            test_pid=$!
            wait $test_pid 2>/dev/null
            test_exit_code=$?
            
            # Check if test was successful (timeout exit code is 124)
            if [ $test_exit_code -eq 124 ] || [ $test_exit_code -eq 0 ]; then
                echo -e "${GREEN}[OK] Test: $category_name/$example_name${NC}"
                ((successful_tests++))
            else
                echo -e "${RED}[Fail] Test: $category_name/$example_name${NC}"
                ((failed_tests++))
                FAILED_TESTS+=("$category_name/$example_name")
            fi
        else
            echo -e "${RED}[Fail] Test: $category_name/$example_name (executable not found)${NC}"
            ((failed_tests++))
            FAILED_TESTS+=("$category_name/$example_name")
        fi
        popd > /dev/null 2>&1
    else
        echo -e "${RED}[Fail] Build: $category_name/$example_name${NC}"
        ((failed_builds++))
        ((failed_tests++))
        FAILED_EXAMPLES+=("$category_name/$example_name")
        FAILED_TESTS+=("$category_name/$example_name")
    fi

done

echo ""
# Summary
echo -e "${PURPLE}Build & Test Summary:${NC}"
echo -e "${GREEN}Successful builds: $successful_builds${NC}"
echo -e "${GREEN}Successful tests: $successful_tests${NC}"
echo -e "${RED}Failed builds: $failed_builds${NC}"
echo -e "${RED}Failed tests: $failed_tests${NC}"

if [ $failed_builds -gt 0 ]; then
    echo -e "${RED}Failed builds:${NC}"
    for failed in "${FAILED_EXAMPLES[@]}"; do
        echo -e "  $failed"
    done
fi

if [ $failed_tests -gt 0 ]; then
    echo -e "${RED}Failed tests:${NC}"
    for failed in "${FAILED_TESTS[@]}"; do
        echo -e "  $failed"
    done
fi
