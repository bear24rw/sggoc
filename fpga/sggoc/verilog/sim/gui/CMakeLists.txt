cmake_minimum_required(VERSION 3.21)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_BUILD_TYPE RelWithDebInfo)

project(sggoc)

find_package(verilator)

add_compile_options(
    -march=native
    -ffast-math
    -Wall
    -Wextra
    -O3
)

add_executable(sggoc
    gui.cpp
    imgui/imgui.cpp
    imgui/imgui_widgets.cpp
    imgui/imgui_draw.cpp
    imgui/imgui_demo.cpp
    imgui/imgui_tables.cpp
    imgui/backends/imgui_impl_opengl3.cpp
    imgui/backends/imgui_impl_glfw.cpp
)

target_compile_features(sggoc PUBLIC
    cxx_std_20
)

target_compile_definitions(sggoc PUBLIC
    -DGL_SILENCE_DEPRECATION
)

target_include_directories(sggoc PUBLIC
    imgui
    imgui/backends
)

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
add_subdirectory(glfw)

target_link_libraries(sggoc PUBLIC
    glfw
    "-framework OpenGL"
    "-framework Cocoa"
    "-framework IOKit"
    "-framework CoreVideo"
)

verilate(sggoc
    SOURCES
        ../../rtl/sggoc.v
        verilator.vlt
    INCLUDE_DIRS
        ../../rtl
        ../../rtl/tv80/rtl/core
    TOP_MODULE
        sggoc
    PREFIX
        v_sggoc
    THREADS
        1
    VERILATOR_ARGS
        -O3
        --x-assign fast
        --x-initial fast
        --noassert
        -Wall
        -Wno-pinconnectempty
        -Wno-unused
        -Wno-width
)
