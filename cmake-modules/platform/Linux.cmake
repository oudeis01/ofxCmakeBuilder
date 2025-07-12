# ================================================================================
# Linux Platform Configuration for openFrameworks
# ================================================================================

message(STATUS "   Configuring for Linux platform...")

# ================================================================================
# Platform-specific function
# ================================================================================

function(of_configure_platform target_name)
    # Compiler options
    target_compile_options(${target_name} PRIVATE 
        -fexceptions 
        -std=c++17 
        -Wall 
        -pthread
    )
    
    # Linker options
    target_link_options(${target_name} PRIVATE 
        -pthread
        -Wl,--as-needed
        -Wl,--gc-sections
        -fuse-ld=gold
        -Wl,-rpath=./libs:./bin/libs:./
    )
    
    # Find required system packages
    find_package(PkgConfig REQUIRED)
    
    # GStreamer (multimedia framework)
    pkg_check_modules(GSTREAMER REQUIRED 
        gstreamer-1.0 
        gstreamer-base-1.0 
        gstreamer-video-1.0 
        gstreamer-app-1.0
    )
    
    # GTK (GUI toolkit)
    pkg_check_modules(GTK REQUIRED gtk+-3.0)
    
    # Additional system packages (optional but commonly used)
    pkg_check_modules(ASSIMP QUIET assimp)
    pkg_check_modules(OPENCV QUIET opencv4)
    
    # Include directories for system libraries
    target_include_directories(${target_name} PRIVATE 
        ${GSTREAMER_INCLUDE_DIRS}
        ${GTK_INCLUDE_DIRS}
    )
    
    if(ASSIMP_FOUND)
        target_include_directories(${target_name} PRIVATE ${ASSIMP_INCLUDE_DIRS})
    endif()
    
    if(OPENCV_FOUND)
        target_include_directories(${target_name} PRIVATE ${OPENCV_INCLUDE_DIRS})
    endif()
    
    # Third-party static libraries (bundled with openFrameworks)
    target_link_libraries(${target_name} PRIVATE
        # openFrameworks bundled libraries
        "${OF_ROOT}/libs/kiss/lib/${OF_PLATFORM}/libkiss.a"
        "${OF_ROOT}/libs/tess2/lib/${OF_PLATFORM}/libtess2.a"
        
        # System libraries from pkg-config
        ${GSTREAMER_LIBRARIES}
        ${GTK_LIBRARIES}
    )
    
    # Optional system libraries
    if(ASSIMP_FOUND)
        target_link_libraries(${target_name} PRIVATE ${ASSIMP_LIBRARIES})
    endif()
    
    if(OPENCV_FOUND)
        target_link_libraries(${target_name} PRIVATE ${OPENCV_LIBRARIES})
    endif()
    
    # Core system libraries (always required)
    target_link_libraries(${target_name} PRIVATE
        # Graphics libraries
        GL GLU GLEW glfw
        
        # X11 libraries  
        X11 Xxf86vm Xrandr Xi Xcursor Xinerama
        
        # Audio libraries
        sndfile openal pulse-simple pulse asound jack mpg123
        
        # System utilities
        rt udev fontconfig curl freeimage freetype
        pugixml uriparser z png crypto ssl glut dl pthread
    )
    
    # FMOD (audio library) - dynamic linking
    set(FMOD_LIB "${OF_ROOT}/libs/fmod/lib/${OF_PLATFORM}/libfmod.so")
    if(EXISTS ${FMOD_LIB})
        target_link_libraries(${target_name} PRIVATE ${FMOD_LIB})
        message(STATUS "     FMOD audio library found and linked")
    else()
        message(STATUS "  ⚠️  FMOD library not found (commercial license required)")
    endif()
    
    message(STATUS "   Linux platform configuration complete")
endfunction()
