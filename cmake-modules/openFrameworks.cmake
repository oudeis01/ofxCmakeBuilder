# ================================================================================
# openFrameworks CMake Module
# 
# This file provides a centralized configuration for all openFrameworks projects.
# It dramatically simplifies individual project CMakeLists.txt files.
#
# Usage in project CMakeLists.txt:
#   include(path/to/openFrameworks.cmake)
#   of_setup_project()
# ================================================================================

cmake_minimum_required(VERSION 3.10)

# Prevent multiple inclusions
if(DEFINED OF_CMAKE_LOADED)
    return()
endif()
set(OF_CMAKE_LOADED TRUE)

message(STATUS "🚀 Loading openFrameworks CMake Module...")

# ================================================================================
# Core Configuration
# ================================================================================

# Find openFrameworks root directory
if(NOT DEFINED OF_ROOT)
    get_filename_component(OF_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
endif()

message(STATUS "📁 openFrameworks root: ${OF_ROOT}")

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ================================================================================
# Platform Detection
# ================================================================================

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
        set(OF_PLATFORM "linux64")
    else()
        set(OF_PLATFORM "linux")
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(OF_PLATFORM "osx")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(OF_PLATFORM "vs")
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
endif()

message(STATUS "🔧 Platform: ${OF_PLATFORM}")

# ================================================================================
# Precompiled Library Detection
# ================================================================================

set(OF_CORE_LIB_PATH "${OF_ROOT}/libs/openFrameworksCompiled/lib/${OF_PLATFORM}")
set(OF_CORE_LIB_DEBUG "${OF_CORE_LIB_PATH}/libopenFrameworksDebug.a")
set(OF_CORE_LIB_RELEASE "${OF_CORE_LIB_PATH}/libopenFrameworks.a")

# Smart library selection (Debug preferred for better debugging)
if(EXISTS ${OF_CORE_LIB_DEBUG})
    set(OF_CORE_LIB "${OF_CORE_LIB_DEBUG}")
    set(OF_USING_DEBUG TRUE)
    message(STATUS "📦 Using Debug openFrameworks library")
elseif(EXISTS ${OF_CORE_LIB_RELEASE})
    set(OF_CORE_LIB "${OF_CORE_LIB_RELEASE}")
    set(OF_USING_DEBUG FALSE)
    message(STATUS "📦 Using Release openFrameworks library")
else()
    message(FATAL_ERROR 
        "❌ openFrameworks library not found!\n"
        "Expected location: ${OF_CORE_LIB_PATH}\n"
        "Please run: scripts/linux/compileOF.sh")
endif()

# ================================================================================
# Include Platform-Specific Configuration
# ================================================================================

include("${CMAKE_CURRENT_LIST_DIR}/platform/${CMAKE_SYSTEM_NAME}.cmake")

# ================================================================================
# Core Functions
# ================================================================================

# Main setup function that projects call
function(of_setup_project)
    message(STATUS "⚙️  Setting up openFrameworks project: ${PROJECT_NAME}")
    
    # Collect project sources
    file(GLOB_RECURSE PROJECT_SOURCES "src/*.cpp" "src/*.c" "src/*.cc")
    if(NOT PROJECT_SOURCES)
        message(WARNING "No source files found in src/ directory")
    endif()
    
    # Create executable
    add_executable(${PROJECT_NAME} ${PROJECT_SOURCES})
    
    # Apply core configuration
    of_configure_target(${PROJECT_NAME})
    
    # Process addons automatically
    of_process_addons(${PROJECT_NAME})
    
    # Setup build output
    of_setup_build_output(${PROJECT_NAME})
    
    message(STATUS "✅ ${PROJECT_NAME} configured successfully!")
    message(STATUS "   📚 Using precompiled library: ${OF_CORE_LIB}")
    message(STATUS "   ⚡ Build should complete in < 1 second!")
endfunction()

# Configure target with openFrameworks settings
function(of_configure_target target_name)
    # Core openFrameworks headers
    target_include_directories(${target_name} PRIVATE
        "src"
        "${OF_ROOT}/libs/openFrameworks"
        "${OF_ROOT}/libs/openFrameworks/3d"
        "${OF_ROOT}/libs/openFrameworks/app"
        "${OF_ROOT}/libs/openFrameworks/communication"
        "${OF_ROOT}/libs/openFrameworks/events"
        "${OF_ROOT}/libs/openFrameworks/gl"
        "${OF_ROOT}/libs/openFrameworks/graphics"
        "${OF_ROOT}/libs/openFrameworks/math"
        "${OF_ROOT}/libs/openFrameworks/sound"
        "${OF_ROOT}/libs/openFrameworks/types"
        "${OF_ROOT}/libs/openFrameworks/utils"
        "${OF_ROOT}/libs/openFrameworks/video"
        
        # Third-party library headers
        "${OF_ROOT}/libs/glm/include"
        "${OF_ROOT}/libs/kiss/include"
        "${OF_ROOT}/libs/tess2/include"
        "${OF_ROOT}/libs/utf8/include"
        "${OF_ROOT}/libs/pugixml/src"
        "${OF_ROOT}/libs/FreeImage/include"
        "${OF_ROOT}/libs/freetype/include"
        "${OF_ROOT}/libs/fmod/include"
    )
    
    # Link precompiled openFrameworks library (FIRST!)
    target_link_libraries(${target_name} PRIVATE ${OF_CORE_LIB})
    
    # Apply platform-specific configuration
    of_configure_platform(${target_name})
endfunction()

# Process addons.make file automatically
function(of_process_addons target_name)
    set(addons_file "${CMAKE_CURRENT_SOURCE_DIR}/addons.make")
    if(EXISTS ${addons_file})
        message(STATUS "📋 Processing addons.make...")
        file(STRINGS ${addons_file} ADDON_LINES)
        
        foreach(LINE ${ADDON_LINES})
            string(STRIP "${LINE}" TRIMMED_LINE)
            if(NOT "${TRIMMED_LINE}" STREQUAL "" AND NOT "${TRIMMED_LINE}" MATCHES "^#")
                of_add_addon(${target_name} ${TRIMMED_LINE})
            endif()
        endforeach()
    endif()
endfunction()

# Add a single addon
function(of_add_addon target_name addon_name)
    set(addon_path "${OF_ROOT}/addons/${addon_name}")
    if(EXISTS ${addon_path})
        message(STATUS "  📦 Adding addon: ${addon_name}")
        
        # Add addon source files recursively
        file(GLOB_RECURSE ADDON_SOURCES "${addon_path}/src/*.cpp" "${addon_path}/src/*.c")
        if(ADDON_SOURCES)
            target_sources(${target_name} PRIVATE ${ADDON_SOURCES})
            
            # Add main src directory
            target_include_directories(${target_name} PRIVATE "${addon_path}/src")
            
            # Add all subdirectories in src/ as include paths
            file(GLOB_RECURSE ADDON_HEADERS "${addon_path}/src/*.h" "${addon_path}/src/*.hpp")
            foreach(HEADER ${ADDON_HEADERS})
                get_filename_component(HEADER_DIR ${HEADER} DIRECTORY)
                target_include_directories(${target_name} PRIVATE ${HEADER_DIR})
            endforeach()
        endif()
        
        # Add addon library files (if any)
        if(EXISTS "${addon_path}/libs")
            file(GLOB_RECURSE ADDON_LIB_SOURCES "${addon_path}/libs/*.cpp" "${addon_path}/libs/*.c")
            
            # Filter out platform-specific files for current platform
            if(UNIX AND NOT APPLE)  # Linux
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/android/.*")
            elseif(APPLE)  # macOS
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/posix/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/linux/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/android/.*")
            elseif(WIN32)  # Windows
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/posix/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*/android/.*")
            endif()
            
            if(ADDON_LIB_SOURCES)
                target_sources(${target_name} PRIVATE ${ADDON_LIB_SOURCES})
            endif()
            
            # Add all libs subdirectories as include paths (recursively)
            target_include_directories(${target_name} PRIVATE "${addon_path}/libs")
            
            # Special handling for common library structures
            # Add common src directories that are often needed
            if(EXISTS "${addon_path}/libs/oscpack/src")
                target_include_directories(${target_name} PRIVATE "${addon_path}/libs/oscpack/src")
            endif()
            
            # Add all subdirectories in libs/ that might contain headers
            file(GLOB_RECURSE ADDON_LIB_DIRS LIST_DIRECTORIES true "${addon_path}/libs/*")
            foreach(LIB_DIR ${ADDON_LIB_DIRS})
                if(IS_DIRECTORY ${LIB_DIR})
                    target_include_directories(${target_name} PRIVATE ${LIB_DIR})
                endif()
            endforeach()
            
            # Also add specific header directories
            file(GLOB_RECURSE ADDON_LIB_HEADERS "${addon_path}/libs/*.h" "${addon_path}/libs/*.hpp")
            foreach(LIB_HEADER ${ADDON_LIB_HEADERS})
                get_filename_component(LIB_HEADER_DIR ${LIB_HEADER} DIRECTORY)
                target_include_directories(${target_name} PRIVATE ${LIB_HEADER_DIR})
            endforeach()
        endif()
        
        # Process addon_config.mk if exists (enhanced for dependencies)
        if(EXISTS "${addon_path}/addon_config.mk")
            message(STATUS "    🔧 Processing addon_config.mk for ${addon_name}")
            
            # Parse addon_config.mk for platform-specific exclusions
            file(STRINGS "${addon_path}/addon_config.mk" CONFIG_LINES)
            set(exclude_patterns "")
            
            foreach(LINE ${CONFIG_LINES})
                string(STRIP "${LINE}" TRIMMED_LINE)
                # Look for ADDON_SOURCES_EXCLUDE or ADDON_INCLUDES_EXCLUDE for current platform
                if("${TRIMMED_LINE}" MATCHES "^[ \t]*ADDON_SOURCES_EXCLUDE[ \t]*=[ \t]*(.+)$")
                    set(exclude_pattern "${CMAKE_MATCH_1}")
                    string(STRIP "${exclude_pattern}" exclude_pattern)
                    list(APPEND exclude_patterns "${exclude_pattern}")
                elseif("${TRIMMED_LINE}" MATCHES "^[ \t]*ADDON_INCLUDES_EXCLUDE[ \t]*=[ \t]*(.+)$")
                    set(exclude_pattern "${CMAKE_MATCH_1}")
                    string(STRIP "${exclude_pattern}" exclude_pattern)
                    list(APPEND exclude_patterns "${exclude_pattern}")
                endif()
            endforeach()
            
            # Apply exclusions - remove files/paths that match exclude patterns
            if(exclude_patterns)
                foreach(exclude_pattern ${exclude_patterns})
                    # Convert addon-relative path to absolute path for comparison
                    set(full_exclude_pattern "${addon_path}/${exclude_pattern}")
                    
                    # Remove matching source files
                    if(ADDON_LIB_SOURCES)
                        list(LENGTH ADDON_LIB_SOURCES orig_count)
                        list(FILTER ADDON_LIB_SOURCES EXCLUDE REGEX ".*${exclude_pattern}.*")
                        list(LENGTH ADDON_LIB_SOURCES new_count)
                        math(EXPR excluded_count "${orig_count} - ${new_count}")
                        if(excluded_count GREATER 0)
                            message(STATUS "    🚫 Excluded ${excluded_count} files matching: ${exclude_pattern}")
                        endif()
                    endif()
                endforeach()
                
                # Update target sources with filtered list
                if(ADDON_LIB_SOURCES)
                    target_sources(${target_name} PRIVATE ${ADDON_LIB_SOURCES})
                endif()
            endif()
        endif()
        
        message(STATUS "    ✅ Successfully added addon: ${addon_name}")
    else()
        message(WARNING "⚠️  Addon not found: ${addon_name} (${addon_path})")
    endif()
endfunction()

# Setup build output (copy to bin folder and clean build)
function(of_setup_build_output target_name)
    # Create bin directory
    add_custom_command(TARGET ${target_name} PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_SOURCE_DIR}/bin"
        COMMENT "📁 Creating bin directory"
    )
    
    # Copy executable to bin folder and remove from build folder
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:${target_name}>"
        "${CMAKE_CURRENT_SOURCE_DIR}/bin/$<TARGET_FILE_NAME:${target_name}>"
        COMMENT "📋 Copying executable to bin folder"
    )
    
    # Remove executable from build folder (keep build clean)
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E remove "$<TARGET_FILE:${target_name}>"
        COMMENT "🧹 Cleaning build folder (removing executable)"
    )
    
    # Print completion message with run instructions
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMAND ${CMAKE_COMMAND} -E echo "🎉 ============================================="
        COMMAND ${CMAKE_COMMAND} -E echo "✅ Build completed successfully!"
        COMMAND ${CMAKE_COMMAND} -E echo "📁 Executable: bin/${target_name}"
        COMMAND ${CMAKE_COMMAND} -E echo "🚀 To run: make run"
        COMMAND ${CMAKE_COMMAND} -E echo "🚀 Or directly: ./bin/${target_name}"
        COMMAND ${CMAKE_COMMAND} -E echo "============================================="
        COMMAND ${CMAKE_COMMAND} -E echo ""
        COMMENT "🎯 Build completion message"
    )
    
    # Add 'run' target for convenience
    add_custom_target(run
        COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/bin/${target_name}"
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
        COMMENT "🏃 Running ${target_name}..."
        USES_TERMINAL
    )
    
    # Ensure run target depends on the build completion, not the executable file
    add_dependencies(run ${target_name})
endfunction()

# ================================================================================
# Convenience Functions for External Libraries
# ================================================================================

# Easy way to add external libraries
function(of_add_library target_name library_name)
    if(${library_name} STREQUAL "OpenCV")
        find_package(OpenCV REQUIRED)
        target_link_libraries(${target_name} PRIVATE ${OpenCV_LIBS})
        target_include_directories(${target_name} PRIVATE ${OpenCV_INCLUDE_DIRS})
        message(STATUS "  📚 Added OpenCV library")
        
    elseif(${library_name} STREQUAL "Boost")
        find_package(Boost REQUIRED COMPONENTS ${ARGN})
        target_link_libraries(${target_name} PRIVATE ${Boost_LIBRARIES})
        target_include_directories(${target_name} PRIVATE ${Boost_INCLUDE_DIRS})
        message(STATUS "  📚 Added Boost library")
        
    elseif(${library_name} STREQUAL "SQLite")
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(SQLITE REQUIRED sqlite3)
        target_link_libraries(${target_name} PRIVATE ${SQLITE_LIBRARIES})
        target_include_directories(${target_name} PRIVATE ${SQLITE_INCLUDE_DIRS})
        message(STATUS "  📚 Added SQLite library")
        
    else()
        # Try pkg-config as fallback
        find_package(PkgConfig QUIET)
        if(PkgConfig_FOUND)
            string(TOLOWER ${library_name} lib_name_lower)
            pkg_check_modules(${library_name} QUIET ${lib_name_lower})
            if(${library_name}_FOUND)
                target_link_libraries(${target_name} PRIVATE ${${library_name}_LIBRARIES})
                target_include_directories(${target_name} PRIVATE ${${library_name}_INCLUDE_DIRS})
                message(STATUS "  📚 Added ${library_name} library (via pkg-config)")
            else()
                message(WARNING "⚠️  Library not found: ${library_name}")
            endif()
        else()
            message(WARNING "⚠️  Library not found: ${library_name} (no pkg-config)")
        endif()
    endif()
endfunction()

# Add custom library with explicit paths
function(of_add_custom_library target_name lib_name lib_path include_path)
    if(EXISTS ${lib_path})
        target_link_libraries(${target_name} PRIVATE ${lib_path})
        if(EXISTS ${include_path})
            target_include_directories(${target_name} PRIVATE ${include_path})
        endif()
        message(STATUS "  📚 Added custom library: ${lib_name}")
    else()
        message(WARNING "⚠️  Custom library not found: ${lib_path}")
    endif()
endfunction()

message(STATUS "✅ openFrameworks CMake Module loaded successfully!")
