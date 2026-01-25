# ================================================================================
# macOS Platform Configuration for openFrameworks
# ================================================================================

message(STATUS "   Configuring for macOS platform...")

# Helper function to safely link libraries (only if they exist)
function(of_link_library_if_exists target_name lib_path)
    if(EXISTS ${lib_path})
        target_link_libraries(${target_name} PRIVATE ${lib_path})
        get_filename_component(lib_name ${lib_path} NAME)
        message(STATUS "     [Linked] ${lib_name}")
    else()
        get_filename_component(lib_name ${lib_path} NAME)
        message(STATUS "     [Skipped] missing: ${lib_name}")
    endif()
endfunction()

function(of_configure_platform target_name)
    # Compiler options for macOS
    target_compile_options(${target_name} PRIVATE 
        -std=c++17 
        -stdlib=libc++
        -Wall
        -D__MACOSX_CORE__
    )
    
    # Find required macOS frameworks
    find_library(OPENGL_FRAMEWORK OpenGL)
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
    find_library(IOKIT_FRAMEWORK IOKit)
    find_library(COREAUDIO_FRAMEWORK CoreAudio)
    find_library(AUDIOTOOLBOX_FRAMEWORK AudioToolbox)
    find_library(AUDIOUNIT_FRAMEWORK AudioUnit)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(COREVIDEO_FRAMEWORK CoreVideo)
    find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
    find_library(COREMEDIA_FRAMEWORK CoreMedia)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore)
    find_library(SECURITY_FRAMEWORK Security)
    find_library(CORESERVICES_FRAMEWORK CoreServices)
    find_library(APPLICATIONSERVICES_FRAMEWORK ApplicationServices)
    
    # Link macOS frameworks
    target_link_libraries(${target_name} PRIVATE
        ${OPENGL_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${COREFOUNDATION_FRAMEWORK}
        ${IOKIT_FRAMEWORK}
        ${COREAUDIO_FRAMEWORK}
        ${AUDIOTOOLBOX_FRAMEWORK}
        ${AUDIOUNIT_FRAMEWORK}
        ${ACCELERATE_FRAMEWORK}
        ${COREVIDEO_FRAMEWORK}
        ${AVFOUNDATION_FRAMEWORK}
        ${COREMEDIA_FRAMEWORK}
        ${QUARTZCORE_FRAMEWORK}
        ${SECURITY_FRAMEWORK}
        ${CORESERVICES_FRAMEWORK}
        ${APPLICATIONSERVICES_FRAMEWORK}
    )
    
    # openFrameworks bundled libraries for macOS (dynamically detected)
    message(STATUS "     Linking openFrameworks libraries:")
    
    # Core libraries (most likely to exist)
    of_link_library_if_exists(${target_name} "${OF_ROOT}/cmake-modules/libs/tess2/lib/${OF_PLATFORM}/tess2.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/cmake-modules/libs/glew/lib/${OF_PLATFORM}/glew.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/glfw/lib/${OF_PLATFORM}/glfw3.a")
    
    # Image processing libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/FreeImage/lib/${OF_PLATFORM}/freeimage.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/freetype/lib/${OF_PLATFORM}/freetype.a")
    
    # Data processing libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/pugixml/lib/${OF_PLATFORM}/pugixml.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/json/lib/${OF_PLATFORM}/json.a")
    
    # Audio libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/rtAudio/lib/${OF_PLATFORM}/rtaudio.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/fmod/lib/${OF_PLATFORM}/libfmod.dylib")
    
    # Network libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/curl/lib/${OF_PLATFORM}/curl.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/uriparser/lib/${OF_PLATFORM}/uriparser.a")
    
    # Graphics libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/cairo/lib/${OF_PLATFORM}/cairo.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/cairo/lib/${OF_PLATFORM}/cairo-script-interpreter.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/cairo/lib/${OF_PLATFORM}/png.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/cairo/lib/${OF_PLATFORM}/pixman-1.a")
    
    # Utility libraries
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/boost/lib/${OF_PLATFORM}/boost_system.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/boost/lib/${OF_PLATFORM}/boost_filesystem.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/utf8/lib/${OF_PLATFORM}/utf8.a")
    
    # Additional libraries that might exist in some versions
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/kiss/lib/${OF_PLATFORM}/libkiss.a")
    of_link_library_if_exists(${target_name} "${OF_ROOT}/libs/poco/lib/${OF_PLATFORM}/poco.a")
    
    message(STATUS "   macOS platform configuration complete")
endfunction()

# macOS-specific post-build setup
function(of_macos_post_build target_name)
    # Copy dynamic libraries to bin folder after build
    message(STATUS "     Setting up dynamic library copying...")
    
    # Copy FMOD library (for audio)
    set(FMOD_DYLIB "${OF_ROOT}/libs/fmod/lib/osx/libfmod.dylib")
    if(EXISTS ${FMOD_DYLIB})
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${FMOD_DYLIB}"
            "${CMAKE_CURRENT_SOURCE_DIR}/bin/libfmod.dylib"
            COMMENT "   [Setup] Copying libfmod.dylib to bin"
        )
        
        message(STATUS "       [Setup] Will copy: libfmod.dylib")
    else()
        message(STATUS "       [Warning] FMOD library not found at: ${FMOD_DYLIB}")
    endif()
    
    # Fix the executable's library search paths using install_name_tool
    add_custom_command(TARGET ${target_name} POST_BUILD
        COMMAND install_name_tool -change "@executable_path/../Frameworks/libfmod.dylib" "@executable_path/libfmod.dylib" "${CMAKE_CURRENT_SOURCE_DIR}/bin/${target_name}" 2>/dev/null || true
        COMMENT "   [Setup] Fixing library paths in executable"
        VERBATIM
    )
endfunction()
