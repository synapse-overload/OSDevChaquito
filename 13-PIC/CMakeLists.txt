cmake_minimum_required(VERSION 3.10)

# new project with used langs C and ASM
project(ChaquitoOS C ASM_NASM)

# Set additional compiler flags. The base freestanding flags are in the toolchain file.
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} \
    -falign-jumps \
    -falign-functions \
    -falign-labels \
    -fomit-frame-pointer \
    -Wno-pointer-to-int-cast \
    -finline-functions \
    -Wno-unused-function \
    -fno-builtin \
    -Werror \
    -Wno-unused-label \
    -Wno-cpp \
    -Wno-unused-parameter \
    -nostdlib \
    -nostartfiles \
    -nodefaultlibs \
    -std=gnu99 \
    -mpreferred-stack-boundary=2 \
    ")

set(CMAKE_C_FLAGS_DEBUG          "-O0 -g"  CACHE INTERNAL "")
set(CMAKE_C_FLAGS_RELEASE        "-O2"     CACHE INTERNAL "")
set(CMAKE_ASM_NASM_FLAGS_DEBUG   "-g -F dwarf" CACHE INTERNAL "")
set(CMAKE_ASM_NASM_FLAGS_RELEASE ""        CACHE INTERNAL "")

add_subdirectory(src)

# Create the final OS image
add_custom_command(
    OUTPUT os.bin
    COMMAND dd if=/dev/zero of=os.bin bs=512 count=101
    COMMAND dd if=src/boot/boot.bin of=os.bin conv=notrunc
    COMMAND dd if=src/kernel.bin of=os.bin seek=1 conv=notrunc
    DEPENDS kernel_bin boot_bin
    COMMENT "Creating os.bin"
)

add_custom_target(os ALL DEPENDS os.bin)
