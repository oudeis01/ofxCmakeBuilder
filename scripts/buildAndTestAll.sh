#!/bin/bash

# ===================================
# openFrameworks CMake Build & Test All Script
# 
# This script builds all openFrameworks examples and tests them
# by running each binary for 4 seconds then killing it.
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

echo -e "${PURPLE}Found ${total_examples} examples to build and test${NC}"
echo ""

# Function to run a single test
run_test() {
    local example_dir="$1"
    local example_name=$(basename "$example_dir")
    local category_name=$(basename $(dirname "$example_dir"))
    
    echo -e "${YELLOW}🧪 Testing: ${category_name}/${example_name}${NC}"
    
    cd "$example_dir"
    
    # Check if binary exists
    if [ ! -f "bin/$example_name" ]; then
        echo -e "${RED}   ❌ Binary not found: bin/$example_name${NC}"
        return 1
    fi
    
    # Run the binary in background for specified duration
    echo -e "${CYAN}   🏃 Running for ${TEST_DURATION} seconds...${NC}"
    
    # Start the process in background, capture its PID
    "./bin/$example_name" > /dev/null 2>&1 &
    local pid=$!
    
    # Wait for specified duration
    sleep $TEST_DURATION
    
    # Kill the process if it's still running
    if kill -0 $pid 2>/dev/null; then
        kill $pid 2>/dev/null
        wait $pid 2>/dev/null || true  # Ignore exit code from killed process
        echo -e "${GREEN}   ✅ Test completed (process terminated cleanly)${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Process crashed or exited early${NC}"
        return 1
    fi
}

# Function to build and test a single example
build_and_test_example() {
    local example_dir="$1"
    local example_name=$(basename "$example_dir")
    local category_name=$(basename $(dirname "$example_dir"))
    local index="$2"
    
    echo -e "${BLUE}[$index/$total_examples] Building: ${category_name}/${example_name}${NC}"
    
    cd "$example_dir"
    
    # Clean any existing build
    rm -rf build
    
    # Configure with CMake
    if ! cmake -B build . > /dev/null 2>&1; then
        echo -e "${RED}   ❌ CMake configuration failed${NC}"
        return 1
    fi
    
    # Build
    if ! cmake --build build -j$PARALLEL_JOBS > /dev/null 2>&1; then
        echo -e "${RED}   ❌ Build failed${NC}"
        return 1
    fi
    
    # Copy required dynamic libraries for macOS (manual fix for library paths)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local project_name=$(basename "$example_dir")
        local bin_path="$example_dir/bin"
        local executable_path="$bin_path/$project_name"
        
        # Copy FMOD library if executable exists
        if [ -f "$executable_path" ]; then
            local fmod_lib="$OF_ROOT/libs/fmod/lib/osx/libfmod.dylib"
            if [ -f "$fmod_lib" ]; then
                cp "$fmod_lib" "$bin_path/libfmod.dylib" 2>/dev/null || true
                
                # Fix library paths using install_name_tool
                install_name_tool -change "@executable_path/../Frameworks/libfmod.dylib" "@executable_path/libfmod.dylib" "$executable_path" 2>/dev/null || true
            fi
        fi
    fi
    
    echo -e "${GREEN}   ✅ Build successful${NC}"
    
    # Test the binary
    if run_test "$example_dir"; then
        echo -e "${GREEN}   ✅ Test successful${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Test failed${NC}"
        return 2  # Different return code for test failure vs build failure
    fi
}

# Main build and test loop
for i in "${!EXAMPLE_DIRS[@]}"; do
    example_dir="${EXAMPLE_DIRS[$i]}"
    index=$((i + 1))
    
    if build_and_test_example "$example_dir" "$index"; then
        ((successful_builds++))
        ((successful_tests++))
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            ((failed_builds++))
        else
            ((successful_builds++))
            ((failed_tests++))
        fi
    fi
    
    echo ""
done

# Final summary
echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}Build & Test Summary${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${GREEN}✅ Successful builds: $successful_builds${NC}"
echo -e "${GREEN}✅ Successful tests: $successful_tests${NC}"
echo -e "${RED}❌ Failed builds: $failed_builds${NC}"
echo -e "${RED}❌ Failed tests: $failed_tests${NC}"
echo -e "${PURPLE}📊 Total examples: $total_examples${NC}"

# Calculate success rates
if [ $total_examples -gt 0 ]; then
    build_success_rate=$((successful_builds * 100 / total_examples))
    test_success_rate=$((successful_tests * 100 / total_examples))
    echo -e "${CYAN}📈 Build success rate: ${build_success_rate}%${NC}"
    echo -e "${CYAN}📈 Test success rate: ${test_success_rate}%${NC}"
fi

echo ""

# Exit with appropriate code
if [ $failed_builds -eq 0 ] && [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All builds and tests successful!${NC}"
    exit 0
elif [ $failed_builds -eq 0 ]; then
    echo -e "${YELLOW}⚠️  All builds successful, but some tests failed${NC}"
    exit 1
else
    echo -e "${RED}💥 Some builds failed${NC}"
    exit 2
fi
