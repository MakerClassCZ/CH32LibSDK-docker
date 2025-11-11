# Toolchain file for Clang19/LLVM with RISC-V support, Xwchc, and compiler-rt
# Using xPack RISC-V GCC for sysroot (newlib + libm)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)

# Compiler paths
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_ASM_COMPILER clang)

# Binutils (use LLVM tools)
set(CMAKE_AR llvm-ar)
set(CMAKE_RANLIB llvm-ranlib)
set(CMAKE_OBJCOPY llvm-objcopy)
set(CMAKE_OBJDUMP llvm-objdump)
set(CMAKE_SIZE llvm-size)

# Linker
set(CMAKE_LINKER ld.lld)

# Don't search for programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Architecture flags for CH32V003 with Xwchc extension
# IMPORTANT: LLVM 19+ includes Xwchc support as experimental extension
set(TARGET_FLAGS "--target=riscv32-unknown-elf")
set(ARCH_FLAGS "-march=rv32ec_xwchc -mabi=ilp32e")
set(EXPERIMENTAL_FLAGS "-menable-experimental-extensions")

# Use compiler-rt instead of libgcc
set(RTLIB_FLAGS "--rtlib=compiler-rt")

# Sysroot - use xPack RISC-V GCC for newlib/libm
# xPack provides rv32ec/ilp32e multilib (compatible with rv32ec_xwchc)
# Pure xPack build - no WCH fallback
if(NOT EXISTS "/opt/xpack-riscv-none-elf-gcc")
    message(FATAL_ERROR "xPack RISC-V GCC not found at /opt/xpack-riscv-none-elf-gcc! This build requires xPack sysroot.")
endif()

set(SYSROOT_PATH "/opt/xpack-riscv-none-elf-gcc/riscv-none-elf")
message(STATUS "Using xPack sysroot: ${SYSROOT_PATH}")
set(SYSROOT_FLAGS "--sysroot=${SYSROOT_PATH}")

# Common C flags
set(CMAKE_C_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${RTLIB_FLAGS} ${SYSROOT_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_CXX_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${RTLIB_FLAGS} ${SYSROOT_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_ASM_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS}")

# Optimization flags
set(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE "-Oz" CACHE STRING "")
set(CMAKE_C_FLAGS_MINSIZEREL "-Oz" CACHE STRING "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g" CACHE STRING "")

# Library search paths for multilib
# xPack: rv32ec/ilp32e multilib (need BOTH newlib and GCC runtime paths)
# Pure xPack build - no WCH fallback

# xPack requires TWO library search paths:
# 1. Newlib path (libc.a, libm.a)
# 2. GCC runtime path (crtbegin.o, crtend.o, etc.)
set(MULTILIB_FLAGS "-L/opt/xpack-riscv-none-elf-gcc/riscv-none-elf/lib/rv32ec/ilp32e -L/opt/xpack-riscv-none-elf-gcc/lib/gcc/riscv-none-elf/14.2.0/rv32ec/ilp32e")

# Linker flags (use LLD for fast linking)
# Note: LTO is NOT compatible with compiler-rt (library is ELF, not bitcode)
# Use COMPILER_RT_BUILTINS variable in target_link_libraries() to link at end
set(CMAKE_EXE_LINKER_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${RTLIB_FLAGS} ${SYSROOT_FLAGS} ${MULTILIB_FLAGS} -fuse-ld=lld")

# Path to compiler-rt builtins library (will be linked at end via target_link_libraries)
set(COMPILER_RT_BUILTINS "/usr/lib/llvm-19/lib/clang/19/lib/baremetal/libclang_rt.builtins-riscv32.a" CACHE FILEPATH "Path to compiler-rt builtins library")

# Skip compiler test (requires full toolchain setup)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# Use LLVM compiler-rt for runtime support
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)
