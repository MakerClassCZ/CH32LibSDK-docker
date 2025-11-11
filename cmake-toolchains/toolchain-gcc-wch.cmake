# Toolchain file for WCH RISC-V GCC compiler
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR riscv32)

# Compiler paths
set(CMAKE_C_COMPILER riscv-wch-elf-gcc)
set(CMAKE_CXX_COMPILER riscv-wch-elf-g++)
set(CMAKE_ASM_COMPILER riscv-wch-elf-gcc)

# Binutils
set(CMAKE_AR riscv-wch-elf-ar)
set(CMAKE_RANLIB riscv-wch-elf-ranlib)
set(CMAKE_OBJCOPY riscv-wch-elf-objcopy)
set(CMAKE_OBJDUMP riscv-wch-elf-objdump)
set(CMAKE_SIZE riscv-wch-elf-size)

# Don't search for programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Architecture flags for CH32V003 (RV32EC with XW extensions)
set(ARCH_FLAGS "-march=rv32ecxw -mabi=ilp32e")

# Common C flags
set(CMAKE_C_FLAGS_INIT "${ARCH_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_CXX_FLAGS_INIT "${ARCH_FLAGS} -ffreestanding -fno-builtin")
set(CMAKE_ASM_FLAGS_INIT "${ARCH_FLAGS}")

# Optimization flags
set(CMAKE_C_FLAGS_DEBUG "-Og -g" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE "-Os" CACHE STRING "")
set(CMAKE_C_FLAGS_MINSIZEREL "-Os" CACHE STRING "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "-O2 -g" CACHE STRING "")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS_INIT "${ARCH_FLAGS} -nostdlib")

# Skip compiler test (requires full toolchain setup)
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)
