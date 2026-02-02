# ofxCmakeBuilder

**ofxCmakeBuilder** provides a cross-platform CMake build system for openFrameworks projects. It includes improved support for addons, automatic dependency detection, and comprehensive build automation script for built-in examples.

## Features

- **Cross-platform**: Works on `linux64` and `macOS` (macOS not tested, Windows support is currently WIP)
- **Addon support**: Automatically detects and configures addons with their dependencies, by parsing the conventional addons.make
- **Platform-specific exclusions**: Properly handles platform-specific source/include exclusions from `addon_config.mk`
- **Dynamic dependency detection**: Automatically finds and links system libraries and frameworks
- **Automated testing**: Build and test all examples
- **Reuse of Precompiled Core Library**: Precompiled library reuse eliminates redundant compilation
- **Respect Original Project Structure**: Executables automatically moved to bin/ folder
- **Smart Core Build**: Automatically builds the core library if missing, or links to the existing one

## Example CMakeLists.txt (8 lines)
```cmake
cmake_minimum_required(VERSION 3.10)
project(myProject)

include("../../../libs/openFrameworks/cmake/openFrameworks.cmake")
of_setup_project()

file(GLOB_RECURSE SOURCES "src/*.cpp" "src/*.h")
add_executable(${PROJECT_NAME} ${SOURCES})
```

## Installation

1. **Download this package** to any location
2. **Run the installer** with your openFrameworks root path:

```bash
./install-cmake-system.sh /path/to/your/openframeworks
```

Example:

```bash
# If openFrameworks is in your home directory
./install-cmake-system.sh ~/of_v20250319_linux64_gcc6_release

# Absolute path
./install-cmake-system.sh /home/youruser/of_v20250319_linux64_gcc6_release
```

## Installed Components

### Core CMake Modules
- **`openFrameworks.cmake`**: Main CMake module with cross-platform(WIP) support and addon handling
- **`platform/Darwin.cmake`**: macOS-specific configuration (frameworks, libraries)(WIP)
- **`platform/Linux.cmake`**: Linux-specific configuration
- **`platform/Windows.cmake`**: Windows-specific configuration(WIP)

### Utility Scripts
- **`generateCMake.sh`**: CMakeLists.txt generator for OF projects
- **`buildAll.sh`**: Build all examples
- **`buildAndTestAll.sh`**: Build and run all examples

### File Structure
```
# the files will be copied in the following structure, when running the installation script.

OF_ROOT/
└── scripts
    └── cmake-scripts/
        ├── generateCMake.sh
        ├── buildAll.sh
        └── buildAndTestAll.sh
└── libs
    └── openFrameworks
        └── cmake
            ├── platform
            │   ├── Darwin.cmake
            │   ├── Linux.cmake
            │   └── Windows.cmake
            └── openFrameworks.cmake
```

## Usage

### Generate CMakeLists.txt for a Project

For a single project:

```bash
cd /path/to/openframeworks
scripts/cmake-scripts/generateCMake.sh examples/3d/3DPrimitivesExample
```
### Build a Project

```bash
cd examples/3d/3DPrimitivesExample
cmake -B build
cmake --build build --parallel
# or if you want to limit the resource
cmake --build build -j8
```

For all examples:

```bash
scripts/cmake-scripts/generateCMake.sh all
```

### Build All Examples

```bash
scripts/cmake-scripts/buildAll.sh
```

### Build All Examples

```bash
scripts/cmake-scripts/buildAll.sh
```

### Build and Test All Examples

Automatically build all examples and run each one by running for 4 seconds:

```bash
scripts/cmake-scripts/buildAndTestAll.sh
```

## Supported Addons

The system has been tested and works with most of the built-in addons(OF v.0.12.1) - but currently breaks with ofxKinect


## Technical Details

### Addon Configuration

The system automatically parses `addon_config.mk` files and handles:

- Platform-specific source exclusions (`common:`, `osx:`, `linux:`, `vs:` sections)
- Include directory exclusions
- Library dependencies and linking
- Framework linking (macOS)
- PKG-config integration

The addon_config.mk parsing was tested only with the officially bundled addons.
For future implementation, a CMakeLists.txt template for addons can be discussed.

### Build Optimizations

- Dependency caching for faster rebuilds
- Minimal rebuild on source changes
- Header dependency tracking

## Advanced Usage

### Build Core from Source

By default, the system automatically checks for the pre-compiled core library in `libs/openFrameworksCompiled/lib/`.
- If found: It links against it (Fast build).
- If missing: It automatically builds the core from source and installs it to the global location (First run optimization).

You can control this behavior with the following options:

#### 1. Force Rebuild Core
To force a rebuild of the global core library (e.g. after updating OF source):

```bash
# locate your project's root, then
cmake -B build -DOF_FORCE_BUILD_CORE=ON
```

#### 2. Project-Specific Core (Local Scope)
To build the core only for *this* project without affecting the global shared library (useful for testing core modifications):

```bash
cmake -DOF_CORE_SCOPE=LOCAL ..
```

This will produce and link the openFrameworks.a inside the project's build directory.

### Debug Output

For verbose CMake output with debugging information:

```bash
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON
```

### Build System Updates

If you update the ofxCmakeBuilder source, reinstall with:

```bash
./install-cmake-system.sh /path/to/openframeworks
```

## Troubleshooting

### Common Issues

1. **Missing libraries**: The system automatically detects most dependencies, but some may need manual installation
2. **Platform-specific compilation errors**: Check that platform exclusions in `addon_config.mk` are properly configured
3. **Framework linking issues (macOS)**: Ensure Xcode command line tools are installed

## License

MIT License

