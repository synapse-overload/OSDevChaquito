# CMAKE toolchain file for i686-elf
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR i686)

# https://cmake.org/cmake/help/latest/manual/cmake-toolchains.7.html
# the above url contains some very good recommendations for writing a toolchain
# file, but the main point is to set the compilers and flags for a freestanding
# environment. We also skip some of CMake's usual checks since we know our 
# toolchain is correct and we're not using C++ exceptions or RTTI.


# Skip compiler ABI checks for freestanding environment (no crt0.o, no libc)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(TOOLCHAIN_PREFIX i686-elf-)
set(TOOLCHAIN_BIN_DIR $ENV{HOME}/opt/cross/bin)

set(CMAKE_C_COMPILER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}g++)
set(CMAKE_ASM_NASM_COMPILER /usr/bin/nasm)
set(CMAKE_LINKER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}ld)

set(CMAKE_OBJCOPY ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_PREFIX}objcopy)

# Add flags for a freestanding environment
set(CMAKE_C_FLAGS "-ffreestanding -O2 -g -Wall -Wextra" CACHE INTERNAL "")

# not really going to use C++ right now but it's nice to have it there
set(CMAKE_CXX_FLAGS "-ffreestanding -O2 -g -Wall -Wextra -fno-exceptions -fno-rtti" CACHE INTERNAL "")

# Tell CMake to not use the standard system libraries
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
