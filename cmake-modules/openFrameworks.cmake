# ===================================
# openFrameworks CMake Module
# 
# This file provides a centralized configuration for all openFrameworks projects.
# It dramatically simplifies individual project CMakeLists.txt files.
#
# Usage in project CMakeLists.txt:
#   include(path/to/openFrameworks.cmake)
#   of_setup_project()
# ===================================

cmake_minimum_required(VERSION 3.10)

# Prevent multiple inclusions
if(DEFINED OF_CMAKE_LOADED)
    return()
endif()
set(OF_CMAKE_LOADED TRUE)

message(STATUS "Loading openFrameworks CMake Module...")

# ===================================
# Core Configuration
# ===================================

# Find openFrameworks root directory
if(NOT DEFINED OF_ROOT)
    get_filename_component(OF_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
endif()

message(STATUS "openFrameworks root: ${OF_ROOT}")

# C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ===================================
# Platform Detection
# ===================================

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

message(STATUS "Platform: ${OF_PLATFORM}")

# ===================================
# Precompiled Library Detection
# ===================================

set(OF_CORE_LIB_PATH "${OF_ROOT}/libs/openFrameworksCompiled/lib/${OF_PLATFORM}")
set(OF_CORE_LIB_DEBUG "${OF_CORE_LIB_PATH}/libopenFrameworksDebug.a")
set(OF_CORE_LIB_RELEASE "${OF_CORE_LIB_PATH}/libopenFrameworks.a")

# Smart library selection (Debug preferred for better debugging)
if(EXISTS ${OF_CORE_LIB_DEBUG})
    set(OF_CORE_LIB "${OF_CORE_LIB_DEBUG}")
    set(OF_USING_DEBUG TRUE)
    message(STATUS "Using Debug openFrameworks library")
elseif(EXISTS ${OF_CORE_LIB_RELEASE})
    set(OF_CORE_LIB "${OF_CORE_LIB_RELEASE}")
    set(OF_USING_DEBUG FALSE)
    message(STATUS "Using Release openFrameworks library")
else()
    message(FATAL_ERROR 
        "❌ openFrameworks library not found!\n"
        "Expected location: ${OF_CORE_LIB_PATH}\n"
        "Please run: scripts/linux/compileOF.sh")
endif()

# ===================================
# Include Platform-Specific Configuration
# ===================================

include("${CMAKE_CURRENT_LIST_DIR}/platform/${CMAKE_SYSTEM_NAME}.cmake")

# ===================================
# Core Functions
# ===================================

# Main setup function that projects call
function(of_setup_project)
    message(STATUS "Setting up openFrameworks project: ${PROJECT_NAME}")
    
    # Set parallel build jobs for faster compilation
    if(NOT DEFINED CMAKE_BUILD_PARALLEL_LEVEL)
        set(CMAKE_BUILD_PARALLEL_LEVEL 4)
        message(STATUS "   Setting parallel build jobs: 4")
    endif()
    
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
    
    message(STATUS "${PROJECT_NAME} configured successfully!")
    message(STATUS "   Using precompiled library: ${OF_CORE_LIB}")
    message(STATUS "   Build should complete in < 1 second!")
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
    )
    
    # Add third-party library headers dynamically (only if they exist)
    message(STATUS "     Adding include directories:")
    
    # Add library includes with their subdirectories (matching traditional Makefile)
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/FreeImage/include")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/boost/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/boost/include/boost")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/cairo/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/cairo/include/cairo")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/curl/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/curl/include/curl")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/fmod/include")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include/freetype2")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include/freetype2/freetype")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include/freetype2/freetype/config")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include/freetype2/freetype/internal")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/freetype/include/freetype2/freetype/internal/services")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glew/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glew/include/GL")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glfw/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glfw/include/GLFW")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm/ext")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm/simd")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm/detail")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm/gtc")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/glm/include/glm/gtx")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/json/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/pugixml/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/rtAudio/include")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/tess2/include")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/uriparser/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/uriparser/include/uriparser")
    
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/utf8/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/utf8/include/utf8")
    
    # Legacy compatibility includes
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/kiss/include")
    of_add_include_if_exists(${target_name} "${OF_ROOT}/libs/poco/include")
    
    # Link precompiled openFrameworks library (FIRST!)
    target_link_libraries(${target_name} PRIVATE ${OF_CORE_LIB})
    
    # Apply platform-specific configuration
    of_configure_platform(${target_name})
endfunction()

# Helper function to safely add include directories (only if they exist)
function(of_add_include_if_exists target_name include_path)
    if(EXISTS ${include_path})
        target_include_directories(${target_name} PRIVATE ${include_path})
        # Extract meaningful path info relative to OF_ROOT
        string(REPLACE "${OF_ROOT}/" "" relative_path "${include_path}")
        message(STATUS "       ✅ Include: ${relative_path}")
    else()
        string(REPLACE "${OF_ROOT}/" "" relative_path "${include_path}")
        message(STATUS "       ⚠️  Skipped missing: ${relative_path}")
    endif()
endfunction()

# Process addons.make file automatically
function(of_process_addons target_name)
    set(addons_file "${CMAKE_CURRENT_SOURCE_DIR}/addons.make")
    if(EXISTS ${addons_file})
        message(STATUS "Processing addons.make...")
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
        message(STATUS "     Adding addon: ${addon_name}")
        
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
            file(GLOB_RECURSE ADDON_LIB_CPP_SOURCES "${addon_path}/libs/*.cpp")
            file(GLOB_RECURSE ADDON_LIB_C_SOURCES "${addon_path}/libs/*.c")
            
            # Filter out platform-specific files for current platform
            if(UNIX AND NOT APPLE)  # Linux
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/windows/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/android/.*")
                
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/windows/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/android/.*")
            elseif(APPLE)  # macOS (Unix-like, use posix)
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/windows/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/linux/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/android/.*")
                
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/win32/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/windows/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/linux/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/android/.*")
                # Note: Keep posix files for macOS as it's Unix-like
            elseif(WIN32)  # Windows
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/posix/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*/android/.*")
                
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/posix/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/osx/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/macos/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/ios/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/tvos/.*")
                list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*/android/.*")
            endif()
            
            # Combine and add sources
            set(ADDON_LIB_SOURCES ${ADDON_LIB_CPP_SOURCES} ${ADDON_LIB_C_SOURCES})
            
            if(ADDON_LIB_SOURCES)
                # Add C++ sources normally
                if(ADDON_LIB_CPP_SOURCES)
                    target_sources(${target_name} PRIVATE ${ADDON_LIB_CPP_SOURCES})
                endif()
                
                # Add C sources with C-specific flags
                if(ADDON_LIB_C_SOURCES)
                    target_sources(${target_name} PRIVATE ${ADDON_LIB_C_SOURCES})
                    # Set C standard for C files instead of C++
                    set_source_files_properties(${ADDON_LIB_C_SOURCES} PROPERTIES
                        LANGUAGE C
                        COMPILE_FLAGS "-std=c99"
                    )
                endif()
                
                list(LENGTH ADDON_LIB_SOURCES lib_source_count)
                message(STATUS "          📁 Added ${lib_source_count} library source files")
                
                # Debug: show first few files
                list(LENGTH ADDON_LIB_SOURCES total_count)
                if(total_count GREATER 0)
                    math(EXPR show_count "${total_count}")
                    if(show_count GREATER 5)
                        set(show_count 5)
                    endif()
                    foreach(i RANGE 0 ${show_count})
                        if(i LESS total_count)
                            list(GET ADDON_LIB_SOURCES ${i} source_file)
                            get_filename_component(file_name ${source_file} NAME)
                            get_filename_component(file_ext ${source_file} EXT)
                            if("${file_ext}" STREQUAL ".c")
                                message(STATUS "             - ${file_name} (C)")
                            else()
                                message(STATUS "             - ${file_name} (C++)")
                            endif()
                        endif()
                    endforeach()
                    if(total_count GREATER 5)
                        math(EXPR remaining "${total_count} - 5")
                        message(STATUS "             ... and ${remaining} more")
                    endif()
                endif()
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
            
            # Link addon libraries (platform-specific)
            if(EXISTS "${addon_path}/libs")
                set(addon_lib_path "")
                if(APPLE)
                    set(addon_lib_path "${addon_path}/libs/*/lib/osx")
                elseif(UNIX)
                    if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
                        set(addon_lib_path "${addon_path}/libs/*/lib/linux64")
                    else()
                        set(addon_lib_path "${addon_path}/libs/*/lib/linux")
                    endif()
                elseif(WIN32)
                    set(addon_lib_path "${addon_path}/libs/*/lib/vs")
                endif()
                
                if(addon_lib_path)
                    file(GLOB_RECURSE ADDON_STATIC_LIBS "${addon_lib_path}/*.a")
                    file(GLOB_RECURSE ADDON_DYNAMIC_LIBS "${addon_lib_path}/*.dylib" "${addon_lib_path}/*.so" "${addon_lib_path}/*.dll")
                    
                    if(ADDON_STATIC_LIBS OR ADDON_DYNAMIC_LIBS)
                        message(STATUS "          🔗 Linking addon libraries:")
                        
                        foreach(LIB ${ADDON_STATIC_LIBS})
                            target_link_libraries(${target_name} PRIVATE ${LIB})
                            get_filename_component(lib_name ${LIB} NAME)
                            message(STATUS "             ✅ Static: ${lib_name}")
                        endforeach()
                        
                        foreach(LIB ${ADDON_DYNAMIC_LIBS})
                            target_link_libraries(${target_name} PRIVATE ${LIB})
                            get_filename_component(lib_name ${LIB} NAME)
                            message(STATUS "             ✅ Dynamic: ${lib_name}")
                        endforeach()
                    endif()
                endif()
            endif()
        endif()
        
        # Process addon_config.mk if exists (enhanced for platform-specific dependencies)
        if(EXISTS "${addon_path}/addon_config.mk")
            message(STATUS "       Processing addon_config.mk for ${addon_name}")
            
            # Parse addon_config.mk for platform-specific exclusions
            file(STRINGS "${addon_path}/addon_config.mk" CONFIG_LINES)
            set(exclude_patterns "")
            set(current_section "common")
            
            # Determine current platform section name
            set(platform_section "common")
            if(UNIX AND NOT APPLE)
                set(platform_section "linux")
            elseif(APPLE)
                set(platform_section "osx")
            elseif(WIN32)
                set(platform_section "vs")
            endif()
            
            foreach(LINE ${CONFIG_LINES})
                string(STRIP "${LINE}" TRIMMED_LINE)
                
                # Detect section headers (e.g., "common:", "vs:", "osx:", "linux:")
                if("${TRIMMED_LINE}" MATCHES "^([a-zA-Z0-9_]+):[ \t]*$")
                    set(current_section "${CMAKE_MATCH_1}")
                # Look for ADDON_SOURCES_EXCLUDE in current section
                elseif("${TRIMMED_LINE}" MATCHES "^[ \t]*ADDON_SOURCES_EXCLUDE[ \t]*=[ \t]*(.+)$")
                    if("${current_section}" STREQUAL "common" OR "${current_section}" STREQUAL "${platform_section}")
                        set(exclude_pattern "${CMAKE_MATCH_1}")
                        string(STRIP "${exclude_pattern}" exclude_pattern)
                        list(APPEND exclude_patterns "${exclude_pattern}")
                        message(STATUS "          📋 Found exclusion (${current_section}): ${exclude_pattern}")
                    endif()
                elseif("${TRIMMED_LINE}" MATCHES "^[ \t]*ADDON_INCLUDES_EXCLUDE[ \t]*=[ \t]*(.+)$")
                    if("${current_section}" STREQUAL "common" OR "${current_section}" STREQUAL "${platform_section}")
                        set(exclude_pattern "${CMAKE_MATCH_1}")
                        string(STRIP "${exclude_pattern}" exclude_pattern)
                        list(APPEND exclude_patterns "${exclude_pattern}")
                        message(STATUS "          📋 Found include exclusion (${current_section}): ${exclude_pattern}")
                    endif()
                endif()
            endforeach()
            
            # Apply exclusions - remove files/paths that match exclude patterns
            if(exclude_patterns)
                foreach(exclude_pattern ${exclude_patterns})
                    # Convert addon-relative path to absolute path for comparison
                    set(full_exclude_pattern "${addon_path}/${exclude_pattern}")
                    
                    # Remove matching source files
                    if(ADDON_LIB_CPP_SOURCES)
                        list(LENGTH ADDON_LIB_CPP_SOURCES orig_count)
                        list(FILTER ADDON_LIB_CPP_SOURCES EXCLUDE REGEX ".*${exclude_pattern}.*")
                        list(LENGTH ADDON_LIB_CPP_SOURCES new_count)
                        math(EXPR excluded_count "${orig_count} - ${new_count}")
                        if(excluded_count GREATER 0)
                            message(STATUS "          🚫 Excluded ${excluded_count} C++ files matching: ${exclude_pattern}")
                        endif()
                    endif()
                    
                    if(ADDON_LIB_C_SOURCES)
                        list(LENGTH ADDON_LIB_C_SOURCES orig_count)
                        list(FILTER ADDON_LIB_C_SOURCES EXCLUDE REGEX ".*${exclude_pattern}.*")
                        list(LENGTH ADDON_LIB_C_SOURCES new_count)
                        math(EXPR excluded_count "${orig_count} - ${new_count}")
                        if(excluded_count GREATER 0)
                            message(STATUS "          🚫 Excluded ${excluded_count} C files matching: ${exclude_pattern}")
                        endif()
                    endif()
                endforeach()
                
                # Update combined sources list
                set(ADDON_LIB_SOURCES ${ADDON_LIB_CPP_SOURCES} ${ADDON_LIB_C_SOURCES})
                
                # Re-add sources with updated filtered lists
                if(ADDON_LIB_CPP_SOURCES)
                    target_sources(${target_name} PRIVATE ${ADDON_LIB_CPP_SOURCES})
                endif()
                
                if(ADDON_LIB_C_SOURCES)
                    target_sources(${target_name} PRIVATE ${ADDON_LIB_C_SOURCES})
                    set_source_files_properties(${ADDON_LIB_C_SOURCES} PROPERTIES
                        LANGUAGE C
                        COMPILE_FLAGS "-std=c99"
                    )
                endif()
            endif()
        endif()
        
        # Handle platform-specific header conflicts (e.g., Windows unistd.h on macOS/Linux)
        if(NOT WIN32 AND "${addon_name}" STREQUAL "ofxKinect")
            set(windows_platform_dir "${addon_path}/libs/libfreenect/platform/windows")
            if(EXISTS "${windows_platform_dir}")
                set(backup_dir "${windows_platform_dir}_backup_${CMAKE_BUILD_TYPE}")
                if(NOT EXISTS "${backup_dir}")
                    message(STATUS "          🔧 Temporarily moving Windows platform headers to avoid conflicts")
                    file(RENAME "${windows_platform_dir}" "${backup_dir}")
                    
                    # Restore original directory on build completion
                    add_custom_command(TARGET ${target_name} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E rename "${backup_dir}" "${windows_platform_dir}"
                        COMMENT "   Restoring Windows platform headers"
                    )
                endif()
            endif()
        endif()
        
        message(STATUS "       Successfully added addon: ${addon_name}")
    else()
        message(WARNING "⚠️  Addon not found: ${addon_name} (${addon_path})")
    endif()
endfunction()

# Setup build output (copy to bin folder and clean build)
function(of_setup_build_output target_name)
    # Create bin directory
    add_custom_command(TARGET ${target_name} PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_SOURCE_DIR}/bin"
        COMMENT "   Creating bin directory"
    )
    
    # Copy executable to bin folder and remove from build folder
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
        "$<TARGET_FILE:${target_name}>"
        "${CMAKE_CURRENT_SOURCE_DIR}/bin/$<TARGET_FILE_NAME:${target_name}>"
        COMMENT "   Copying executable to bin folder"
    )
    
    # Remove executable from build folder (keep build clean)
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E remove "$<TARGET_FILE:${target_name}>"
        COMMENT "   Cleaning build folder (removing executable)"
    )
    
    # Platform-specific post-build setup - copy dynamic libraries
    if(APPLE)
        # Copy FMOD library for macOS
        set(FMOD_DYLIB "${OF_ROOT}/libs/fmod/lib/osx/libfmod.dylib")
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${FMOD_DYLIB}"
            "${CMAKE_CURRENT_SOURCE_DIR}/bin/libfmod.dylib"
            COMMENT "   📦 Copying libfmod.dylib to bin"
        )
        
        # Fix the executable's library search paths using install_name_tool
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND install_name_tool -change "@executable_path/../Frameworks/libfmod.dylib" "@executable_path/libfmod.dylib" "${CMAKE_CURRENT_SOURCE_DIR}/bin/${target_name}" 2>/dev/null || true
            COMMENT "   🔧 Fixing library paths in executable"
            VERBATIM
        )
    endif()
    
    # Print completion message with run instructions
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Build completed"
        COMMENT "Build completion"
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

# ===================================
# Convenience Functions for External Libraries
# ===================================

# Easy way to add external libraries
function(of_add_library target_name library_name)
    if(${library_name} STREQUAL "OpenCV")
        find_package(OpenCV REQUIRED)
        target_link_libraries(${target_name} PRIVATE ${OpenCV_LIBS})
        target_include_directories(${target_name} PRIVATE ${OpenCV_INCLUDE_DIRS})
        message(STATUS "     Added OpenCV library")
        
    elseif(${library_name} STREQUAL "Boost")
        find_package(Boost REQUIRED COMPONENTS ${ARGN})
        target_link_libraries(${target_name} PRIVATE ${Boost_LIBRARIES})
        target_include_directories(${target_name} PRIVATE ${Boost_INCLUDE_DIRS})
        message(STATUS "     Added Boost library")
        
    elseif(${library_name} STREQUAL "SQLite")
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(SQLITE REQUIRED sqlite3)
        target_link_libraries(${target_name} PRIVATE ${SQLITE_LIBRARIES})
        target_include_directories(${target_name} PRIVATE ${SQLITE_INCLUDE_DIRS})
        message(STATUS "     Added SQLite library")
        
    else()
        # Try pkg-config as fallback
        find_package(PkgConfig QUIET)
        if(PkgConfig_FOUND)
            string(TOLOWER ${library_name} lib_name_lower)
            pkg_check_modules(${library_name} QUIET ${lib_name_lower})
            if(${library_name}_FOUND)
                target_link_libraries(${target_name} PRIVATE ${${library_name}_LIBRARIES})
                target_include_directories(${target_name} PRIVATE ${${library_name}_INCLUDE_DIRS})
                message(STATUS "     Added ${library_name} library (via pkg-config)")
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
        message(STATUS "     Added custom library: ${lib_name}")
    else()
        message(WARNING "⚠️  Custom library not found: ${lib_path}")
    endif()
endfunction()

message(STATUS "   openFrameworks CMake Module loaded successfully!")
