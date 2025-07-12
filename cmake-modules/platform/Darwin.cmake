# ================================================================================
# macOS Platform Configuration for openFrameworks
# ================================================================================

message(STATUS "   Configuring for macOS platform...")

function(of_configure_platform target_name)
    # Compiler options for macOS
    target_compile_options(${target_name} PRIVATE 
        -std=c++17 
        -stdlib=libc++
        -Wall
    )
    
    # Find required macOS frameworks
    find_library(OPENGL_FRAMEWORK OpenGL)
    find_library(COCOA_FRAMEWORK Cocoa)
    find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
    find_library(IOKIT_FRAMEWORK IOKit)
    find_library(COREAUDIO_FRAMEWORK CoreAudio)
    find_library(AUDIOTOOLBOX_FRAMEWORK AudioToolbox)
    find_library(AUDIOUNIT_FRAMEWORK AudioUnit)
    
    # Link macOS frameworks
    target_link_libraries(${target_name} PRIVATE
        ${OPENGL_FRAMEWORK}
        ${COCOA_FRAMEWORK}
        ${COREFOUNDATION_FRAMEWORK}
        ${IOKIT_FRAMEWORK}
        ${COREAUDIO_FRAMEWORK}
        ${AUDIOTOOLBOX_FRAMEWORK}
        ${AUDIOUNIT_FRAMEWORK}
        
        # openFrameworks bundled libraries for macOS
        "${OF_ROOT}/libs/kiss/lib/${OF_PLATFORM}/libkiss.a"
        "${OF_ROOT}/libs/tess2/lib/${OF_PLATFORM}/libtess2.a"
        "${OF_ROOT}/libs/fmod/lib/${OF_PLATFORM}/libfmod.dylib"
    )
    
    message(STATUS "   macOS platform configuration complete")
endfunction()
