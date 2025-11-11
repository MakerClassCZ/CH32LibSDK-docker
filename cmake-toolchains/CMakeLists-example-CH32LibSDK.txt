# ============================================================================
# Example CMakeLists.txt for CH32LibSDK Projects
# ============================================================================
#
# This is a universal template for building CH32 projects with CH32LibSDK.
# Copy this file to your project directory and rename it to CMakeLists.txt
#
# Features:
#   - Universal toolchain support (GCC, CLANG_LIBGCC, CLANG_COMPILER_RT)
#   - Environment-based toolchain selection (Docker) or explicit user choice
#   - Automatic MCU parameter detection from SDK
#   - SDK and custom device support
#   - Toolchain-specific compilation and linking
#
# Usage:
#   1. Copy to your project: cp CMakeLists-example-CH32LibSDK.txt myproject/CMakeLists.txt
#   2. Edit PROJECT_NAME_BASE, TARGET_NAME, DEVICE_CLASS, MCU, and PROJECT_SOURCES
#   3. Build:
#      cmake -B build -DUSE_TOOLCHAIN=GCC        # or CLANG_LIBGCC, CLANG_COMPILER_RT
#      cmake --build build
#
# ============================================================================

cmake_minimum_required(VERSION 3.20)

# ============================================================================
# Project Configuration - EDIT THIS SECTION FOR YOUR PROJECT
# ============================================================================

# Project identification
set(PROJECT_NAME_BASE "MyProject")      # Base name for project
set(TARGET_NAME "main")                 # Output binary name (without .elf)

# Device and MCU selection
set(DEVICE_CLASS "tinyboy" CACHE STRING "Device class: tinyboy, babyboy, babypad, etc.")
set(MCU "CH32V003x4" CACHE STRING "Target MCU: CH32V003x4, CH32V003x6, CH32V203x6, etc.")

# Project source files - ADD YOUR SOURCE FILES HERE
set(PROJECT_SOURCES
    src/main.c
    # Add more source files as needed
)

# ============================================================================
# Toolchain Selection - ENV-based (Docker) or explicit user choice
# ============================================================================

# Available toolchains:
#   GCC               - Official WCH GCC toolchain (maximum compatibility)
#   CLANG_LIBGCC      - Clang 19 + LLVM LLD + GCC libgcc (best performance)
#   CLANG_COMPILER_RT - Clang 19 + LLVM compiler-rt + xPack (pure LLVM, no WCH dependency)

# Toolchain selection priority:
#   1. User explicit choice: -DUSE_TOOLCHAIN=...
#   2. Environment variable: $CH32_TOOLCHAIN (set by Docker image)
#   3. Error: No default, must be specified

# Check if user provided explicit toolchain choice
if(NOT DEFINED USE_TOOLCHAIN OR USE_TOOLCHAIN STREQUAL "")
    # No user choice, check environment variable (from Docker)
    if(DEFINED ENV{CH32_TOOLCHAIN} AND NOT "$ENV{CH32_TOOLCHAIN}" STREQUAL "")
        set(USE_TOOLCHAIN $ENV{CH32_TOOLCHAIN})
        message(STATUS "Toolchain from Docker environment: ${USE_TOOLCHAIN}")
    else()
        # No ENV and no user choice - error
        message(FATAL_ERROR
            "Toolchain not specified!\n"
            "  Please specify with: -DUSE_TOOLCHAIN=<GCC|CLANG_LIBGCC|CLANG_COMPILER_RT>\n"
            "  Or build in a Docker container with CH32_TOOLCHAIN environment variable."
        )
    endif()
else()
    message(STATUS "Toolchain from user: ${USE_TOOLCHAIN}")
endif()

# Validate toolchain selection
if(NOT USE_TOOLCHAIN MATCHES "^(GCC|CLANG_LIBGCC|CLANG_COMPILER_RT)$")
    message(FATAL_ERROR "Invalid toolchain: ${USE_TOOLCHAIN}. Must be GCC, CLANG_LIBGCC, or CLANG_COMPILER_RT")
endif()

# Configure toolchain-specific settings
if(USE_TOOLCHAIN STREQUAL "GCC")
    set(CMAKE_TOOLCHAIN_FILE "/opt/cmake-toolchains/toolchain-gcc-wch.cmake")
    set(PROJECT_NAME "${PROJECT_NAME_BASE}_GCC")
    set(USE_CLANG FALSE)
    set(USE_COMPILER_RT FALSE)
    message(STATUS "Using GCC WCH toolchain (maximum compatibility)")

elseif(USE_TOOLCHAIN STREQUAL "CLANG_LIBGCC")
    set(CMAKE_TOOLCHAIN_FILE "/opt/cmake-toolchains/toolchain-clang19-libgcc.cmake")
    set(PROJECT_NAME "${PROJECT_NAME_BASE}_Clang_libgcc")
    set(USE_CLANG TRUE)
    set(USE_COMPILER_RT FALSE)
    message(STATUS "Using Clang 19 + libgcc toolchain (best performance)")

elseif(USE_TOOLCHAIN STREQUAL "CLANG_COMPILER_RT")
    set(CMAKE_TOOLCHAIN_FILE "/opt/cmake-toolchains/toolchain-clang19-compiler-rt.cmake")
    set(PROJECT_NAME "${PROJECT_NAME_BASE}_Clang_CompilerRT")
    set(USE_CLANG TRUE)
    set(USE_COMPILER_RT TRUE)
    message(STATUS "Using Clang 19 + compiler-rt + xPack (pure LLVM, no WCH dependency)")
endif()

project(${PROJECT_NAME} C ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# ============================================================================
# SDK Configuration
# ============================================================================

set(SDK_ROOT "/opt/CH32LibSDK")

# ============================================================================
# MCU Parameter Detection
# ============================================================================

function(parse_mcu_from_sdk SDK_ROOT MCU_NAME)
    set(MAKEFILE1 "${SDK_ROOT}/Makefile1.inc")

    if(NOT EXISTS "${MAKEFILE1}")
        message(FATAL_ERROR "SDK Makefile1.inc not found at: ${MAKEFILE1}")
    endif()

    # Read entire Makefile1.inc
    file(READ "${MAKEFILE1}" MAKEFILE_CONTENT)

    # Find the MCU section - looks for "ifeq ($(MCU),CH32V003x4)"
    string(REPLACE "\n" ";" MAKEFILE_LINES "${MAKEFILE_CONTENT}")

    set(IN_MCU_BLOCK FALSE)
    set(MCU_BLOCK "")

    foreach(line ${MAKEFILE_LINES})
        # Check if we're starting the MCU block
        if(line MATCHES "ifeq.*MCU.*${MCU_NAME}")
            set(IN_MCU_BLOCK TRUE)
        endif()

        # Collect lines in the block
        if(IN_MCU_BLOCK)
            set(MCU_BLOCK "${MCU_BLOCK}${line}\n")
        endif()

        # Check if we're ending the MCU block
        if(IN_MCU_BLOCK AND line MATCHES "^endif")
            break()
        endif()
    endforeach()

    if(NOT MCU_BLOCK)
        message(FATAL_ERROR "MCU ${MCU_NAME} not found in ${MAKEFILE1}")
    endif()

    # Extract MCUSERIE (e.g., CH32V003)
    string(REGEX MATCH "MCUSERIE[ \t]*=[ \t]*([A-Z0-9]+)" _ "${MCU_BLOCK}")
    set(MCU_SERIE "${CMAKE_MATCH_1}")

    # Extract MCUCLASS (e.g., CH32V0)
    string(REGEX MATCH "MCUCLASS[ \t]*=[ \t]*([A-Z0-9]+)" _ "${MCU_BLOCK}")
    set(MCU_CLASS "${CMAKE_MATCH_1}")

    # Extract SDK_SUBDIR (e.g., ch32v003)
    string(REGEX MATCH "SDK_SUBDIR[ \t]*=[ \t]*([a-z0-9]+)" _ "${MCU_BLOCK}")
    set(SDK_SUBDIR_VALUE "${CMAKE_MATCH_1}")

    # Extract FLASHSIZE (e.g., 0x4000)
    string(REGEX MATCH "FLASHSIZE[ \t]*=[ \t]*(0x[0-9a-fA-F]+)" _ "${MCU_BLOCK}")
    set(FLASH_SIZE "${CMAKE_MATCH_1}")

    # Extract RAMSIZE (e.g., 0x800)
    string(REGEX MATCH "RAMSIZE[ \t]*=[ \t]*(0x[0-9a-fA-F]+)" _ "${MCU_BLOCK}")
    set(RAM_SIZE "${CMAKE_MATCH_1}")

    # Extract STACKSIZE (e.g., 256)
    string(REGEX MATCH "STACKSIZE[ \t]*=[ \t]*([0-9]+)" _ "${MCU_BLOCK}")
    set(STACK_SIZE "${CMAKE_MATCH_1}")

    # Export to parent scope
    set(MCU_SERIE "${MCU_SERIE}" PARENT_SCOPE)
    set(MCU_CLASS "${MCU_CLASS}" PARENT_SCOPE)
    set(SDK_SUBDIR "${SDK_SUBDIR_VALUE}" PARENT_SCOPE)
    set(FLASH_SIZE "${FLASH_SIZE}" PARENT_SCOPE)
    set(RAM_SIZE "${RAM_SIZE}" PARENT_SCOPE)
    set(STACK_SIZE "${STACK_SIZE}" PARENT_SCOPE)

    message(STATUS "MCU ${MCU_NAME}: Flash=${FLASH_SIZE}, RAM=${RAM_SIZE}, Stack=${STACK_SIZE}, SDK=${SDK_SUBDIR_VALUE}")
endfunction()

# Parse MCU parameters from SDK
parse_mcu_from_sdk("${SDK_ROOT}" "${MCU}")

# SDK paths
set(SDK_PATH "${SDK_ROOT}/_sdk/${SDK_SUBDIR}")
set(LIB_PATH "${SDK_ROOT}/_lib")
set(FONT_PATH "${SDK_ROOT}/_font")

# ============================================================================
# Device Configuration
# ============================================================================

# Detect device location (SDK or custom)
foreach(search_path IN ITEMS
    "${SDK_ROOT}/_devices/${DEVICE_CLASS}"
    "${CMAKE_CURRENT_SOURCE_DIR}/device/${DEVICE_CLASS}")

    if(EXISTS "${search_path}/_config.h")
        set(DEVICE_PATH "${search_path}")
        break()
    endif()
endforeach()

if(NOT DEVICE_PATH)
    message(FATAL_ERROR "Device '${DEVICE_CLASS}' not found in SDK or custom devices!")
endif()

# Auto-detect device type from path
if(DEVICE_PATH MATCHES "^${SDK_ROOT}")
    set(DEVICE_TYPE "SDK")
    set(USE_SDK_DEVICE ON)
    set(USE_CUSTOM_DEVICE OFF)
    set(DEVICE_CONFIG_INCLUDE "// SDK device config handled by global.h")
    set(DEVICE_INCLUDE_HEADER "// SDK device headers handled by global.h")
else()
    set(DEVICE_TYPE "Custom")
    set(USE_SDK_DEVICE OFF)
    set(USE_CUSTOM_DEVICE ON)
    # Emulate SDK's global.h device config include pattern
    set(DEVICE_CONFIG_INCLUDE "#include \"device/${DEVICE_CLASS}/_config.h\"")
    set(DEVICE_INCLUDE_HEADER "#include \"device/${DEVICE_CLASS}/_include.h\"")
endif()

message(STATUS "Using ${DEVICE_TYPE} device: ${DEVICE_CLASS}")

# Generate unified config.h wrapper with device-specific includes
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/config.h"
"// ****************************************************************************
//
//                 Project Configuration Wrapper (Auto-generated)
//
// ****************************************************************************
// This file is automatically generated by CMake during configuration
// DO NOT EDIT MANUALLY - changes will be overwritten
//
// Purpose: Inject custom device configuration before loading main config.h
// This emulates SDK's global.h pattern where device _config.h is included
// based on USE_* macros. For custom devices, we inject the include here.
//
// Device class: ${DEVICE_CLASS}
// Device type: ${DEVICE_TYPE}
// ****************************************************************************

#ifndef _CONFIG_WRAPPER_H
#define _CONFIG_WRAPPER_H

// ----------------------------------------------------------------------------
//                    Custom Device Configuration (CMake)
// ----------------------------------------------------------------------------
// Emulate SDK's global.h device config include pattern
// SDK's global.h conditionally includes device/_config.h for SDK devices
// For custom devices, we inject the include here via CMake configuration

${DEVICE_CONFIG_INCLUDE}

// ----------------------------------------------------------------------------
//                    Include Original Project Configuration
// ----------------------------------------------------------------------------
// Now include the original config.h with project-specific settings
// Device clock defines from _config.h above will be seen by SDK headers
// Using absolute path to avoid recursion (generated config.h in build/ vs source config.h)

#include \"${CMAKE_CURRENT_SOURCE_DIR}/config.h\"

// ----------------------------------------------------------------------------
//                    Custom Device Function Declarations
// ----------------------------------------------------------------------------
// Include device function headers AFTER SDK (which is included by config.h)

${DEVICE_INCLUDE_HEADER}

#endif // _CONFIG_WRAPPER_H
")

# ============================================================================
# Source Files Collection
# ============================================================================

# Device drivers
if(EXISTS "${DEVICE_PATH}/${DEVICE_CLASS}.c")
    set(DEVICE_SOURCES "${DEVICE_PATH}/${DEVICE_CLASS}.c")
    message(STATUS "Using unity build: ${DEVICE_CLASS}.c")
else()
    # Fallback: collect all .c files from device directory
    file(GLOB DEVICE_SOURCES "${DEVICE_PATH}/*.c")
    message(STATUS "Using multiple device sources: ${DEVICE_SOURCES}")
endif()

# SDK sources - include all, linker will remove unused with --gc-sections
file(GLOB SDK_SOURCES "${SDK_PATH}/sdk_*.c")

# Library sources - include all, linker will remove unused with --gc-sections
file(GLOB LIB_SOURCES "${LIB_PATH}/src/lib_*.c")

# Font sources
set(FONT_SOURCES "${FONT_PATH}/font.c")

# Startup code - use SDK version for both compilers
set(STARTUP_ASM "${SDK_PATH}/crt0.S")
message(STATUS "Using SDK crt0.S")

# ============================================================================
# Executable Definition
# ============================================================================

add_executable(${TARGET_NAME}.elf
    ${STARTUP_ASM}
    ${PROJECT_SOURCES}
    ${DEVICE_SOURCES}
    ${SDK_SOURCES}
    ${LIB_SOURCES}
    ${FONT_SOURCES}
)

# ============================================================================
# Include Directories
# ============================================================================

target_include_directories(${TARGET_NAME}.elf PRIVATE
    ${CMAKE_CURRENT_BINARY_DIR}  # For generated headers (config.h) - FIRST!
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${DEVICE_PATH}
    ${SDK_PATH}
    ${LIB_PATH}/inc
    ${FONT_PATH}
)

# ============================================================================
# Compiler Definitions
# ============================================================================

# Convert device class to uppercase for USE_* macro
string(TOUPPER ${DEVICE_CLASS} DEVICE_CLASS_UPPER)

target_compile_definitions(${TARGET_NAME}.elf PRIVATE
    MCU_${MCU}
    FLASHSIZE=${FLASH_SIZE}
    RAMSIZE=${RAM_SIZE}
    STACKSIZE=${STACK_SIZE}
    DEVCLASS_${DEVICE_CLASS}
    USE_${DEVICE_CLASS_UPPER}=1
    SDK_SUBDIR=${SDK_SUBDIR}
)

# Set INCLUDES_H - use SDK includes.h for both compilers
target_compile_definitions(${TARGET_NAME}.elf PRIVATE
    INCLUDES_H="/opt/CH32LibSDK/includes.h"
)

# For Clang: generate HANDLER fix file
if(USE_CLANG)
    set(CLANG_FIX_FILE "${CMAKE_CURRENT_BINARY_DIR}/clang_handler_fix.h")
    file(WRITE "${CLANG_FIX_FILE}"
"// Auto-generated Clang compatibility fix for HANDLER attribute
// GCC uses __attribute__((interrupt(\"WCH-Interrupt-fast\"))) which Clang doesn't support
#ifdef HANDLER
#undef HANDLER
#endif
#define HANDLER __attribute__((interrupt))
")
endif()

# ============================================================================
# Compiler Options
# ============================================================================

target_compile_options(${TARGET_NAME}.elf PRIVATE
    -Oz -flto  # Aggressive size optimization + Link Time Optimization
    -Wall
    -Wextra
    # Suppress SDK warnings (third-party code issues)
    -Wno-misleading-indentation
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-implicit-fallthrough
    -Wno-pointer-sign
    -ffunction-sections
    -fdata-sections
    -fno-pic  # Disable position-independent code
    -fno-plt  # Disable procedure linkage table
    # Force include to ensure all SDK files get device config via INCLUDES_H
    $<$<COMPILE_LANGUAGE:C>:-include ${CMAKE_CURRENT_SOURCE_DIR}/include.h>
    $<$<COMPILE_LANGUAGE:C>:-std=gnu11>
)

# For Clang: force-include HANDLER fix after include.h
if(USE_CLANG)
    target_compile_options(${TARGET_NAME}.elf PRIVATE
        $<$<COMPILE_LANGUAGE:C>:SHELL:-include ${CLANG_FIX_FILE}>
    )
endif()

# ============================================================================
# Linker Options (Toolchain-Specific)
# ============================================================================

if(USE_CLANG)
    # Clang + LLD linker (both libgcc and compiler-rt variants)
    target_link_options(${TARGET_NAME}.elf PRIVATE
        -flto
        -T${SDK_ROOT}/memmap-lld.ld
        -Wl,--gc-sections
        -Wl,--print-memory-usage
        -Wl,-Map=${TARGET_NAME}.map
        -Wl,--defsym=__FLASH_SIZE__=${FLASH_SIZE}
        -Wl,--defsym=__RAM_SIZE__=${RAM_SIZE}
        -Wl,--defsym=__STACK_SIZE__=${STACK_SIZE}
        -static
        -nostartfiles
    )

    # Add libgcc paths only for CLANG_LIBGCC (not for CLANG_COMPILER_RT)
    if(NOT USE_COMPILER_RT)
        target_link_options(${TARGET_NAME}.elf PRIVATE
            # WCH libgcc paths for Clang+libgcc variant
            -L/opt/wch-toolchain/riscv-wch-elf/lib/rv32ec/ilp32e
            -L/opt/wch-toolchain/lib/gcc/riscv-wch-elf/12.2.0/rv32ec/ilp32e
        )
    endif()

    # Link with standard libraries
    if(USE_COMPILER_RT)
        # Clang+compiler-rt: link with c m (compiler-rt + xPack newlib)
        # Note: xPack libraries are compiled for rv32ec/ilp32e (without xwchc),
        # but are binary compatible with rv32ec_xwchc code (xwchc is superset)
        target_link_libraries(${TARGET_NAME}.elf PRIVATE c m)
    else()
        # Clang+libgcc: link with c m gcc (WCH libgcc)
        target_link_libraries(${TARGET_NAME}.elf PRIVATE c m gcc)
    endif()

else()
    # GCC + ld linker
    target_link_options(${TARGET_NAME}.elf PRIVATE
        -T${SDK_ROOT}/memmap.ld
        -Wl,--gc-sections
        -Wl,--print-memory-usage
        -Wl,-Map=${TARGET_NAME}.map
        -Wl,--defsym=__FLASH_SIZE__=${FLASH_SIZE}
        -Wl,--defsym=__RAM_SIZE__=${RAM_SIZE}
        -Wl,--defsym=__STACK_SIZE__=${STACK_SIZE}
        -nostartfiles
    )

    # Link with standard libraries
    target_link_libraries(${TARGET_NAME}.elf PRIVATE c m gcc)
endif()

# ============================================================================
# Post-build: Generate .bin, .hex, .lst and show size
# ============================================================================

if(USE_CLANG)
    # Use LLVM tools for Clang builds
    set(OBJCOPY_CMD "llvm-objcopy")
    set(OBJDUMP_CMD "llvm-objdump")
    set(SIZE_CMD "llvm-size")
    set(TOOLSET_NAME "LLVM")
else()
    # Use GNU tools for GCC builds
    set(OBJCOPY_CMD "${CMAKE_OBJCOPY}")
    set(OBJDUMP_CMD "${CMAKE_OBJDUMP}")
    set(SIZE_CMD "${CMAKE_SIZE}")
    set(TOOLSET_NAME "GNU")
endif()

add_custom_command(TARGET ${TARGET_NAME}.elf POST_BUILD
    COMMAND ${OBJCOPY_CMD} -O binary -j .init -j .text -j .fini -j .data
            ${TARGET_NAME}.elf ${TARGET_NAME}.bin
    COMMAND ${OBJCOPY_CMD} -O ihex ${TARGET_NAME}.elf ${TARGET_NAME}.hex
    COMMAND ${OBJDUMP_CMD} -D -S ${TARGET_NAME}.elf > ${TARGET_NAME}.lst
    COMMAND ${SIZE_CMD} ${TARGET_NAME}.elf
    COMMENT "Generating output files: .bin, .hex, .lst (using ${TOOLSET_NAME} tools, toolchain: ${USE_TOOLCHAIN})"
    VERBATIM
)

# ============================================================================
# Flash target (using minichlink)
# ============================================================================

add_custom_target(flash
    COMMAND minichlink -w ${TARGET_NAME}.bin flash -b
    DEPENDS ${TARGET_NAME}.elf
    COMMENT "Flashing ${TARGET_NAME}.bin to MCU using minichlink..."
)
