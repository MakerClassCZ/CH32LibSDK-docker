# Toolchain file for Clang19/LLVM with RISC-V support and Xwchc
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

# Sysroot (use xPack GCC RISC-V toolchain for libc/libm)
set(SYSROOT_PATH "/opt/wch-toolchain/riscv-wch-elf")
set(SYSROOT_FLAGS "--sysroot=${SYSROOT_PATH}")

# Common C flags
set(CMAKE_C_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${SYSROOT_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_CXX_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${SYSROOT_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_ASM_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS}")

# Optimization flags
set(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE "-Oz" CACHE STRING "")
set(CMAKE_C_FLAGS_MINSIZEREL "-Oz" CACHE STRING "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g" CACHE STRING "")

# Linker flags (use LLD for fast linking)
# Note: We use -lc -lm -lgcc to link with standard libraries from sysroot
set(CMAKE_EXE_LINKER_FLAGS_INIT "${TARGET_FLAGS} ${ARCH_FLAGS} ${EXPERIMENTAL_FLAGS} ${SYSROOT_FLAGS} -fuse-ld=lld")

# Skip compiler test (requires full toolchain setup)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# Optional: Use compiler-rt instead of libgcc (if available)
# set(CMAKE_EXE_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT} --rtlib=compiler-rt")
