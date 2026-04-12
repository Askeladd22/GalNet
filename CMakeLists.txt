cmake_minimum_required(VERSION 3.20)

project(x4native_gnn_core LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(x4native_gnn_core SHARED
    native/x4native_gnn_core.cpp
)

set(_x4nativesdk_dir "${CMAKE_CURRENT_SOURCE_DIR}/../x4native-sdk")

target_include_directories(x4native_gnn_core PRIVATE
    "${_x4nativesdk_dir}"
)

set_target_properties(x4native_gnn_core PROPERTIES
    PREFIX ""
    OUTPUT_NAME "x4native_gnn_core"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/native"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/native"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib"
)

foreach(_cfg Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER "${_cfg}" _cfg_upper)
    set_target_properties(x4native_gnn_core PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY_${_cfg_upper} "${CMAKE_CURRENT_SOURCE_DIR}/native"
        LIBRARY_OUTPUT_DIRECTORY_${_cfg_upper} "${CMAKE_CURRENT_SOURCE_DIR}/native"
        ARCHIVE_OUTPUT_DIRECTORY_${_cfg_upper} "${CMAKE_CURRENT_BINARY_DIR}/lib/${_cfg}"
    )
endforeach()
