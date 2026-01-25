# ================================================================================
# Windows Platform Configuration for openFrameworks  
# ================================================================================

message(STATUS "   Configuring for Windows platform...")

function(of_configure_platform target_name)
    # Compiler options for Windows
    target_compile_options(${target_name} PRIVATE 
        /std:c++17 
        /bigobj
        /W3
    )
    
    # Windows system libraries
    target_link_libraries(${target_name} PRIVATE
        # Graphics and system
        opengl32 glu32 gdi32 ole32 oleaut32 uuid setupapi 
        wsock32 ws2_32 winmm advapi32 version user32 shell32 psapi
        
        # openFrameworks bundled libraries for Windows
        "${OF_ROOT}/cmake-modules/libs/kiss/lib/${OF_PLATFORM}/kiss.lib"
        "${OF_ROOT}/cmake-modules/libs/tess2/lib/${OF_PLATFORM}/tess2.lib"
        "${OF_ROOT}/cmake-modules/libs/fmod/lib/${OF_PLATFORM}/fmod_vc.lib"
    )
    
    message(STATUS "   Windows platform configuration complete")
endfunction()
