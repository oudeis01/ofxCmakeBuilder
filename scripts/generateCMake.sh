#!/bin/bash

# CMakeLists.txt Generator for openFrameworks Projects
# This script generates optimized CMakeLists.txt files for existing projects

export LC_ALL=C

SCRIPT_DIR="$(cd $(dirname $0); pwd)"
OF_ROOT="$(cd $(dirname $0)/../..; pwd -P)"

echo "🔧 openFrameworks CMakeLists.txt Generator"
echo "📁 openFrameworks root: $OF_ROOT"

# 함수: CMakeLists.txt 생성
generate_cmakelists() {
    local PROJECT_DIR="$1"
    local PROJECT_NAME
    local RELATIVE_OF_ROOT
    
    # 프로젝트 이름 계산 (현재 디렉토리인 경우 실제 폴더명 사용)
    if [ "$PROJECT_DIR" = "." ]; then
        PROJECT_NAME="$(basename "$PWD")"
    else
        PROJECT_NAME="$(basename "$PROJECT_DIR")"
    fi
    
    # 상대 경로 계산
    RELATIVE_OF_ROOT=$(realpath --relative-to="$PROJECT_DIR" "$OF_ROOT")
    
    echo "  📝 Generating ultra-minimal CMakeLists.txt for $PROJECT_NAME..."
    
    cat > "$PROJECT_DIR/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.10)

# set project name
project($PROJECT_NAME)

# load openFrameworks core settings
include("\${CMAKE_CURRENT_SOURCE_DIR}/$RELATIVE_OF_ROOT/libs/openFrameworks/cmake/openFrameworks.cmake")

# openFrameworks 프로젝트 설정 (한 줄이면 끝!)
of_setup_project()

# ========================================
# 외부 라이브러리 추가 (선택사항)
# ========================================
# 예시: OpenCV 추가
# of_add_library(\${PROJECT_NAME} OpenCV)

# 예시: Boost 라이브러리 추가
# of_add_library(\${PROJECT_NAME} Boost system filesystem)

# 예시: 커스텀 라이브러리 추가
# of_add_custom_library(\${PROJECT_NAME} "MyLib" "/path/to/lib.a" "/path/to/headers")

# 예시: 추가 컴파일 정의
# target_compile_definitions(\${PROJECT_NAME} PRIVATE MY_CUSTOM_DEFINE=1)

# 예시: 추가 헤더 경로
# target_include_directories(\${PROJECT_NAME} PRIVATE "custom_headers/")
EOF

    echo "  ✅ Generated ultra-minimal CMakeLists.txt for $PROJECT_NAME (only 8 essential lines!)"
}

# 메인 실행 부분
if [ $# -eq 0 ]; then
    echo "Usage: $0 [project_directory|'all']"
    echo "Examples:"
    echo "  $0 ../../examples/3d/3DPrimitivesExample"
    echo "  $0 all    # Generate for all examples"
    exit 1
fi

if [ "$1" = "all" ]; then
    echo "🔄 Generating CMakeLists.txt for all examples..."
    TOTAL=0
    
    for category in $(find "$OF_ROOT/examples" -maxdepth 1 -type d); do
        if [ "$(basename $category)" = "examples" ] || [ "$(basename $category)" = "android" ] || [ "$(basename $category)" = "ios" ] || [ "$(basename $category)" = "tvOS" ]; then
            continue
        fi
        
        echo "📁 Processing category: $(basename $category)"
        
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
    
    echo "🎉 Generated CMakeLists.txt for $TOTAL projects!"
else
    PROJECT_DIR="$1"
    if [ ! -d "$PROJECT_DIR" ]; then
        echo "❌ Directory not found: $PROJECT_DIR"
        exit 1
    fi
    
    if [ ! -d "$PROJECT_DIR/src" ]; then
        echo "❌ No src directory found in: $PROJECT_DIR"
        echo "   This doesn't appear to be an openFrameworks project"
        exit 1
    fi
    
    generate_cmakelists "$PROJECT_DIR"
    echo "🎉 Done! You can now build with:"
    echo "   cd $PROJECT_DIR && mkdir -p build && cd build"
    echo "   cmake .. && make -j$(nproc)"
fi
