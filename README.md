# ofxCmakeBuilder - Cross-Platform CMake Build System for openFrameworks

**ofxCmakeBuilder** provides a cross-platform CMake build system for openFrameworks projects. It includes improved support for addons, automatic dependency detection, and comprehensive build automation script for built-in examples.

## Features

- **Cross-platform**: Works on macOS(not tested), Linux(tested). Windows support coming soon
- **Addon support**: Automatically detects and configures addons with their dependencies, by parsing the conventional addons.make
- **Platform-specific exclusions**: Properly handles platform-specific source/include exclusions from `addon_config.mk`
- **Dynamic dependency detection**: Automatically finds and links system libraries and frameworks
- **Automated testing**: Build and test all examples
- **Reuse of Precompiled Core Library**: Precompiled library reuse eliminates redundant compilation
- **Respect Original Project Structure**: Executables automatically moved to bin/ folder

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
- **`generateCMake.sh`**: Cross-platform CMakeLists.txt generator
- **`buildAll.sh`**: Build all examples
- **`buildAndTestAll.sh`**: Build and run all examples

## Usage

### Generate CMakeLists.txt for a Project

For a single project:

```bash
cd /path/to/openframeworks
scripts/linux/generateCMake.sh examples/3d/3DPrimitivesExample
scripts/osx/generateCMake.sh examples/3d/3DPrimitivesExample
```
### Build a Project

```bash
cd examples/3d/3DPrimitivesExample
mkdir build && cd build
cmake .. && make -j4
make run
```

For all examples:

```bash
scripts/linux/generateCMake.sh all
scripts/osx/generateCMake.sh all
```

### Build All Examples

```bash
scripts/linux/buildAll.sh
scripts/osx/buildAll.sh
```

### Build and Test All Examples

Automatically build all examples and run each one by running for 4 seconds:

```bash
scripts/macos/buildAndTestAll.sh
```

## Supported Addons

The system has been tested and works with most of the built-in addons(OF v.0.12.1) - breaks with ofxKinect


## Technical Details

### Addon Configuration

The system automatically parses `addon_config.mk` files and handles:

- Platform-specific source exclusions (`common:`, `osx:`, `linux:`, `vs:` sections)
- Include directory exclusions
- Library dependencies and linking
- Framework linking (macOS)
- PKG-config integration

### Build Optimizations

- Intelligent dependency caching
- Minimal rebuild on source changes
- Proper header dependency tracking

## Troubleshooting

### Common Issues

1. **Missing libraries**: The system automatically detects most dependencies, but some may need manual installation
2. **Platform-specific compilation errors**: Check that platform exclusions in `addon_config.mk` are properly configured
3. **Framework linking issues (macOS)**: Ensure Xcode command line tools are installed

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
## License

MIT License
