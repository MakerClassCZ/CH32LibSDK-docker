# ============================================================================
# CH32 CMake Toolchain - ch32v003fun SDK
# ============================================================================
#
# This toolchain file configures CMake for building CH32 projects using
# the ch32v003fun SDK with GCC WCH toolchain.
#
# ch32v003fun: Minimalist SDK with direct hardware access
# Repository: https://github.com/cnlohr/ch32v003fun
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=/opt/cmake-toolchains/toolchain-ch32fun.cmake ..
#
# Environment variables required:
#   CH32V003FUN_PATH - Path to ch32v003fun repository (set by Docker)
#

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv)

# Toolchain programs
set(CMAKE_C_COMPILER riscv-wch-elf-gcc)
set(CMAKE_CXX_COMPILER riscv-wch-elf-g++)
set(CMAKE_ASM_COMPILER riscv-wch-elf-gcc)
set(CMAKE_OBJCOPY riscv-wch-elf-objcopy)
set(CMAKE_OBJDUMP riscv-wch-elf-objdump)
set(CMAKE_SIZE riscv-wch-elf-size)

# Prevent CMake from testing the compiler
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# Target configuration for CH32V003 (rv32ec/ilp32e)
set(CMAKE_C_FLAGS "-march=rv32ec -mabi=ilp32e -g -Os -flto -ffunction-sections -fdata-sections -Wall" CACHE STRING "C flags")
set(CMAKE_CXX_FLAGS "-march=rv32ec -mabi=ilp32e -g -Os -flto -ffunction-sections -fdata-sections -Wall" CACHE STRING "C++ flags")
set(CMAKE_ASM_FLAGS "-march=rv32ec -mabi=ilp32e -g" CACHE STRING "ASM flags")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS "-Wl,--gc-sections -flto -nostdlib -static" CACHE STRING "Linker flags")

# ch32v003fun SDK paths
set(CH32FUN_PATH $ENV{CH32V003FUN_PATH})

if(NOT EXISTS "${CH32FUN_PATH}")
    message(FATAL_ERROR "ch32v003fun not found at ${CH32FUN_PATH}. Please set CH32V003FUN_PATH environment variable.")
endif()

# Include directories for ch32v003fun
include_directories(
    ${CH32FUN_PATH}/ch32v003fun
    ${CH32FUN_PATH}/ch32v003fun/extralibs
)

# Print configuration info
message(STATUS "Using ch32v003fun SDK")
message(STATUS "  ch32v003fun path: ${CH32FUN_PATH}")
message(STATUS "  Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  Target: RISC-V rv32ec (ilp32e ABI)")
message(STATUS "  Build type: ${CMAKE_BUILD_TYPE}")
