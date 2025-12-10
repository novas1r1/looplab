cmake_minimum_required(VERSION 3.22.1)

project(rubberband_flutter LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Fetch Rubber Band library from GitHub
include(FetchContent)

FetchContent_Declare(
    rubberband
    GIT_REPOSITORY https://github.com/breakfastquay/rubberband.git
    GIT_TAG v4.0.0
)

# Configure Rubber Band build options
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(RUBBERBAND_BUILD_SHARED OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(rubberband)

# Create main JNI library
add_library(rubberband_flutter SHARED
    rubberband_jni.cpp
    audio_file_handler.cpp
)

target_include_directories(rubberband_flutter PRIVATE
    ${rubberband_SOURCE_DIR}
)

target_link_libraries(rubberband_flutter
    rubberband
    log
)

# Enable position independent code
set_target_properties(rubberband_flutter PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

